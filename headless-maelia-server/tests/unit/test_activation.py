"""Quels paramètres sont actifs, et pourquoi les autres ne le sont pas.

`idExploitationAexecuter` ne veut rien dire tant que `executerUnSeulAgriculteur`
est faux : la simulation porte alors sur toutes les exploitations et
l'identifiant est ignoré. Le griser sans le dire laisserait chercher.
"""

from app.contexts.catalog.domain.models import ParameterSpec, ParameterType
from app.contexts.scenario.domain.activation import (
    activation,
    effective_values,
    inactive_values,
)


def spec(name, type_=ParameterType.STRING, default=None, enabled_if=None, label=None):
    return ParameterSpec(
        name=name, label=label or name, group="Général", type=type_,
        default=default, enabled_if=enabled_if,
    )


LEVIER = spec("executerUnSeulAgriculteur", ParameterType.BOOL, False, label="simulationSurExploitation")
COMMANDE = spec("idExploitationAexecuter", default="expl_1",
                enabled_if="executerUnSeulAgriculteur == true")
IRRIGATION = spec("isIrrigationSimulee", ParameterType.BOOL, True)
MODELE_IRR = spec("nomChoixModeleIrrigation", default="Simple",
                  enabled_if="isIrrigationSimulee == true")
LIBRE = spec("nbAnneesSimulation", ParameterType.INT, 3)

TOUS = [LEVIER, COMMANDE, IRRIGATION, MODELE_IRR, LIBRE]


class TestActivite:
    def test_un_parametre_sans_condition_est_toujours_actif(self):
        assert activation({}, TOUS)["nbAnneesSimulation"].enabled

    def test_un_parametre_commande_par_un_levier_eteint_est_grise(self):
        etat = activation({}, TOUS)["idExploitationAexecuter"]
        assert not etat.enabled
        assert etat.condition == "executerUnSeulAgriculteur == true"

    def test_activer_le_levier_le_rend_modifiable(self):
        etats = activation({"executerUnSeulAgriculteur": True}, TOUS)
        assert etats["idExploitationAexecuter"].enabled

    def test_la_condition_se_lit_sur_les_defauts_aussi(self):
        """`isIrrigationSimulee` vaut vrai par défaut : le modèle d'irrigation
        est actif sans que personne n'ait rien saisi."""
        assert activation({}, TOUS)["nomChoixModeleIrrigation"].enabled

    def test_eteindre_un_levier_vrai_par_defaut_grise_ce_qu_il_commande(self):
        etats = activation({"isIrrigationSimulee": False}, TOUS)
        assert not etats["nomChoixModeleIrrigation"].enabled

    def test_la_raison_nomme_le_levier_avec_son_libelle(self):
        etat = activation({}, TOUS)["idExploitationAexecuter"]
        assert "simulationSurExploitation" in etat.because

    def test_une_condition_illisible_laisse_le_champ_modifiable(self):
        """Mieux vaut un champ modifiable à tort qu'un champ verrouillé sans
        explication."""
        bancal = spec("x", enabled_if="n importe quoi")
        etat = activation({}, [bancal])["x"]
        assert etat.enabled and "illisible" in etat.because


class TestValeursEffectives:
    def test_les_ecarts_se_posent_sur_les_defauts(self):
        valeurs = effective_values({"nbAnneesSimulation": 1}, TOUS)
        assert valeurs["nbAnneesSimulation"] == 1
        assert valeurs["isIrrigationSimulee"] is True


class TestEcartsSansEffet:
    def test_un_ecart_sur_un_parametre_grise_est_signale(self):
        """Il n'est pas refusé — on peut préparer une valeur avant d'activer le
        levier — mais il ne change rien tant que le levier est éteint."""
        assert inactive_values({"idExploitationAexecuter": "expl_9"}, TOUS) == [
            "idExploitationAexecuter"
        ]

    def test_aucun_signalement_quand_le_levier_accompagne_la_valeur(self):
        ecarts = {"executerUnSeulAgriculteur": True, "idExploitationAexecuter": "expl_9"}
        assert inactive_values(ecarts, TOUS) == []
