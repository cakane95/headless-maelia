"""Ce qu'un run écrira, et pourquoi le reste manquera.

MAELIA n'écrit rien par défaut : chaque sortie est derrière un interrupteur,
lui-même imbriqué dans les gardes des modules dont elle dépend. Ces règles
lisent ce que le modèle dit, pour qu'un fichier absent ait une explication.
"""

import json
import pathlib

import pytest

from app.contexts.catalog.application.outputs import (
    effective_values,
    unreachable_terms,
    validate_output,
)
from app.contexts.catalog.domain.models import (
    Granularity,
    OutputFileSpec,
    OutputSpec,
    ParameterSpec,
    ParameterType,
)
from app.contexts.catalog.domain.outputs import (
    Production,
    expectation,
    owner,
    review,
)
from app.contexts.catalog.domain.services import (
    InvalidExpression,
    evaluate_condition,
    referenced_parameters,
)
from app.contexts.catalog.infrastructure.seed import load_output_seed


def sortie(identifiant, *fichiers, produced_if=None, exact=True, theme="ESSAI"):
    return OutputSpec(
        id=identifiant,
        label=identifiant,
        theme=theme,
        files=tuple(OutputFileSpec(nom, Granularity.YEAR_END) for nom in fichiers),
        produced_if=produced_if,
        exact=exact,
    )


# ── Le langage de conditions ────────────────────────────────────────────────


def test_ou_entre_deux_alternatives():
    """`sorties_eau` dépend de deux modèles de croissance possibles."""
    condition = (
        "sorties_eau == true && plante == 'AqYield' "
        "|| sorties_eau == true && plante == 'AqYieldNC'"
    )
    assert evaluate_condition(condition, {"sorties_eau": True, "plante": "AqYieldNC"})
    assert evaluate_condition(condition, {"sorties_eau": True, "plante": "AqYield"})
    assert not evaluate_condition(condition, {"sorties_eau": True, "plante": "HerbSim"})
    assert not evaluate_condition(condition, {"sorties_eau": False, "plante": "AqYield"})


def test_et_lie_plus_fort_que_ou():
    """Sans parenthèses, la précédence doit rendre la forme normale disjonctive."""
    # (a && b) || c — et non a && (b || c)
    condition = "a == true && b == true || c == true"
    assert evaluate_condition(condition, {"c": True})
    assert not evaluate_condition(condition, {"a": True})
    assert evaluate_condition(condition, {"a": True, "b": True})


def test_condition_illisible_reste_refusee():
    with pytest.raises(InvalidExpression):
        evaluate_condition("length(listeCanaux) > 0", {})


def test_parametres_cites_dans_les_deux_operateurs():
    assert referenced_parameters("a == true && b != 'x' || c == 1") == ["a", "b", "c"]


# ── La prédiction ───────────────────────────────────────────────────────────


def test_sortie_inconditionnelle_toujours_produite():
    attente = expectation(sortie("params", "simulationParameters.txt"), {})
    assert attente.production is Production.PRODUCED


def test_sortie_eteinte_nomme_ce_qui_la_debloque():
    spec = sortie(
        "eco", "eco_itk.csv",
        produced_if="executerModeleAgricole == true && ECO_itk == true",
    )
    attente = expectation(spec, {"executerModeleAgricole": True, "ECO_itk": False})
    assert attente.production is Production.ABSENT
    assert attente.blocking == ("ECO_itk",)
    assert "ECO_itk" in attente.reason


def test_le_chemin_le_plus_court_est_propose():
    """Deux routes mènent au fichier ; conseiller la plus courte."""
    spec = sortie(
        "eau", "sorties_eau.csv",
        produced_if="a == true && b == true && c == true || d == true",
    )
    attente = expectation(spec, {})
    assert attente.blocking == ("d",)


def test_condition_approximative_reste_incertaine():
    """Un terme abandonné à la traduction interdit d'affirmer quoi que ce soit."""
    spec = sortie("canaux", "Canaux_Annuel.csv", produced_if="Canaux == true", exact=False)
    attente = expectation(spec, {"Canaux": True})
    assert attente.production is Production.UNCERTAIN


def test_ecriture_hors_aiguillage_sous_condition_interne():
    spec = sortie("debug", "debugParHRU.csv", produced_if=None, exact=False)
    assert expectation(spec, {}).production is Production.UNCERTAIN


# ── Le croisement avec un run ───────────────────────────────────────────────


def test_le_suffixe_de_simulation_ne_perd_pas_le_fichier():
    """`nomDeLaSimulation` s'insère avant l'extension quand un territoire le pose."""
    spec = sortie("eau", "sorties_eau.csv")
    assert spec.owns("sorties_eau.csv")
    assert spec.owns("sorties_eauEssai1.csv")
    assert not spec.owns("sorties_CN.csv")


def test_bilan_separe_manquant_et_hors_catalogue():
    specs = [
        sortie("eau", "sorties_eau.csv", produced_if="sorties_eau == true"),
        sortie("azote", "sorties_CN.csv", produced_if="sorties_azote == true"),
    ]
    bilan = review(
        specs,
        {"sorties_eau": True, "sorties_azote": True},
        ["sorties_eau.csv", "inconnu.csv"],
    )
    assert bilan.produced == ("sorties_eau.csv",)
    assert bilan.missing == ("sorties_CN.csv",)
    assert bilan.undeclared == ("inconnu.csv",)
    assert not bilan.complete


def test_une_sortie_non_demandee_ne_manque_pas():
    specs = [sortie("azote", "sorties_CN.csv", produced_if="sorties_azote == true")]
    bilan = review(specs, {"sorties_azote": False}, [])
    assert bilan.missing == ()
    assert bilan.complete


def test_proprietaire_d_un_fichier():
    specs = [sortie("eau", "sorties_eau.csv")]
    assert owner(specs, "sorties_eau.csv").id == "eau"
    assert owner(specs, "autre.csv") is None


# ── Le croisement avec le launcher ──────────────────────────────────────────


def test_valeurs_effectives_reposent_sur_les_defauts():
    specs = [
        ParameterSpec(name="a", label="a", group="g", type=ParameterType.BOOL, default=True),
        ParameterSpec(name="b", label="b", group="g", type=ParameterType.BOOL, default=False),
    ]
    assert effective_values({"b": True}, specs) == {"a": True, "b": True}


def test_sortie_hors_de_portee_quand_le_launcher_ignore_son_interrupteur():
    spec = sortie("x", "x.csv", produced_if="executerModeleAgricole == true && RDT_itk == true")
    assert unreachable_terms(spec, {"executerModeleAgricole"}) == ["RDT_itk"]
    assert unreachable_terms(spec, {"executerModeleAgricole", "RDT_itk"}) == []


# ── La validation d'une sortie écrite à la main ─────────────────────────────


def test_sortie_sans_fichier_refusee():
    champs = [champ for champ, _ in validate_output(sortie("x"))]
    assert "files" in champs


def test_nom_de_fichier_sans_extension_refuse():
    spec = sortie("x", "sansExtension")
    assert any(champ == "files" for champ, _ in validate_output(spec))


def test_condition_illisible_refusee():
    spec = sortie("x", "x.csv", produced_if="length(liste) > 0")
    assert any(champ == "produced_if" for champ, _ in validate_output(spec))


# ── Le catalogue réel ───────────────────────────────────────────────────────


def test_le_seed_se_charge():
    specs = load_output_seed()
    assert len(specs) > 100
    assert all(spec.files for spec in specs)
    assert all(spec.theme for spec in specs)


def test_toute_condition_du_seed_est_evaluable():
    """Une condition illisible en base rendrait la sortie imprévisible."""
    for spec in load_output_seed():
        if spec.produced_if:
            evaluate_condition(spec.produced_if, {})


def test_le_seed_reproduit_un_run_reel():
    """L'invariant : ce que le catalogue prédit est ce que GAMA a écrit.

    Les neuf fichiers sont ceux d'un run terrainTest mené à terme avec les
    réglages par défaut du launcher. Si l'extraction dérive, ce test tombe.
    """
    racine = pathlib.Path(__file__).resolve().parents[2]
    parametres = json.loads(
        (racine / "app/contexts/catalog/infrastructure/seed/parameters.json")
        .read_text(encoding="utf-8")
    )
    valeurs = {entree["name"]: entree.get("default") for entree in parametres}

    specs = load_output_seed()
    # Les interrupteurs que le launcher n'expose pas gardent le défaut du modèle.
    seed = json.loads(
        (racine / "app/contexts/catalog/infrastructure/seed/outputs.json")
        .read_text(encoding="utf-8")
    )
    for entree in seed:
        if entree["flag"] and entree["flag"] not in valeurs:
            valeurs[entree["flag"]] = entree["default"]

    produits = [
        "corresponsanceIlotZoneMeteo.csv", "simulationDuration.txt",
        "simulationParameters.txt", "sorties_CN.csv", "sorties_GES.csv",
        "sorties_eau.csv", "suiviOTParParcelle.csv",
        "suivi_ajout_pools_residus.csv", "surfaceParcelles.csv",
    ]
    bilan = review(specs, valeurs, produits)
    assert bilan.missing == ()
    assert bilan.undeclared == ()
    assert sorted(bilan.produced) == sorted(produits)
