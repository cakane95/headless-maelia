"""Quels paramètres sont actifs, compte tenu des écarts saisis.

Un paramètre peut n'avoir de sens que si un autre est activé :
`idExploitationAexecuter` ne veut rien dire tant que
`executerUnSeulAgriculteur` est faux — la simulation porte alors sur toutes les
exploitations et l'identifiant est ignoré.

La règle vit ici, et nulle part ailleurs. Le front interroge, il n'évalue pas :
deux évaluateurs, c'est deux comportements le jour où l'un des deux change.
"""

from collections.abc import Iterable, Mapping
from dataclasses import dataclass
from typing import Any

from app.contexts.catalog.domain.models import ParameterSpec
from app.contexts.catalog.domain.services import InvalidExpression, evaluate_condition


@dataclass(frozen=True, slots=True)
class Activation:
    """État d'un paramètre : modifiable ou non, et pourquoi."""

    name: str
    enabled: bool
    condition: str | None = None
    because: str | None = None


def effective_values(
    values: Mapping[str, Any], specs: Iterable[ParameterSpec]
) -> dict[str, Any]:
    """Les valeurs vues par le modèle : les écarts posés sur les défauts.

    Une condition se lit sur l'état complet, pas sur les seuls écarts — un
    paramètre commandé par un booléen vrai *par défaut* est actif sans que
    personne n'ait rien saisi.
    """
    complet = {spec.name: spec.default for spec in specs}
    complet.update(values)
    return complet


def activation(
    values: Mapping[str, Any], specs: Iterable[ParameterSpec]
) -> dict[str, Activation]:
    """État d'activité de chaque paramètre pour ces écarts."""
    specs = list(specs)
    etat = effective_values(values, specs)
    par_nom = {spec.name: spec for spec in specs}

    resultat: dict[str, Activation] = {}
    for spec in specs:
        if not spec.enabled_if:
            resultat[spec.name] = Activation(spec.name, enabled=True)
            continue

        try:
            actif = evaluate_condition(spec.enabled_if, etat)
        except InvalidExpression:
            # Une condition illisible n'éteint pas le paramètre : mieux vaut un
            # champ modifiable à tort qu'un champ verrouillé sans explication.
            resultat[spec.name] = Activation(
                spec.name, enabled=True, condition=spec.enabled_if,
                because="condition illisible : le paramètre reste modifiable",
            )
            continue

        resultat[spec.name] = Activation(
            spec.name,
            enabled=actif,
            condition=spec.enabled_if,
            because=None if actif else _explication(spec.enabled_if, par_nom),
        )
    return resultat


def _explication(condition: str, par_nom: Mapping[str, ParameterSpec]) -> str:
    """Phrase lisible : « demande que X soit activé »."""
    morceaux = []
    for partie in condition.split("&&"):
        nom = partie.strip().split("==")[0].split("!=")[0].strip()
        spec = par_nom.get(nom)
        morceaux.append(spec.label if spec and spec.label != nom else nom)
    return "demande que " + ", ".join(morceaux) + " soit activé"


def inactive_values(
    values: Mapping[str, Any], specs: Iterable[ParameterSpec]
) -> list[str]:
    """Écarts posés sur des paramètres que leur condition éteint.

    Ils ne sont pas refusés — on peut préparer une valeur avant d'activer le
    levier qui la commande — mais ils restent sans effet, et le dire évite de
    chercher pourquoi la simulation ne change pas.
    """
    etats = activation(values, specs)
    return sorted(nom for nom in values if nom in etats and not etats[nom].enabled)
