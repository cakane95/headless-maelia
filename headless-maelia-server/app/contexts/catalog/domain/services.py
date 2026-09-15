"""Catalog business rules — pure functions, testable without infrastructure."""

import re
from collections.abc import Iterable, Sequence
from dataclasses import dataclass
from typing import Any

from app.contexts.catalog.domain.models import DataSpec, ParameterSpec

# `required_if` is a deliberately minimal expression: `<param> <op> <literal>`.
# Arbitrary code is never evaluated — the catalog is data, not script.
_COMPARISON = re.compile(
    r"^\s*(?P<param>[A-Za-z_][\w]*)\s*(?P<op>==|!=)\s*(?P<value>'[^']*'|\"[^\"]*\"|[\w.\-]+)\s*$"
)


class InvalidExpression(ValueError):
    """`required_if` does not follow the expected form."""


def _literal(raw: str) -> Any:
    raw = raw.strip()
    if raw[:1] in {"'", '"'}:
        return raw[1:-1]
    if raw == "true":
        return True
    if raw == "false":
        return False
    try:
        return int(raw)
    except ValueError:
        pass
    try:
        return float(raw)
    except ValueError:
        return raw


def _operandes(expression: str) -> list[str]:
    """Comparisons of an expression, whatever the operators joining them."""
    return [
        part
        for alternative in expression.split("||")
        for part in alternative.split("&&")
        if part.strip()
    ]


def compared_parameter(term: str) -> str | None:
    """The parameter a single comparison reads, or None if it is not one."""
    match = _COMPARISON.match(term)
    return match["param"] if match else None


def referenced_parameters(expression: str) -> list[str]:
    """Parameters a condition reads, in order of appearance, without repeats.

    Feeds the screens: an output that is not produced must be able to say which
    switch turns it on, and a parameter that is greyed out which one frees it.
    """
    names: list[str] = []
    for part in _operandes(expression):
        name = compared_parameter(part)
        if name and name not in names:
            names.append(name)
    return names


def evaluate_condition(expression: str, config: dict[str, Any]) -> bool:
    """Evaluate an applicability condition against the project configuration.

    Accepted form: `param == value` / `param != value` comparisons joined by
    `&&` and `||`, with `&&` binding tighter — the shape of a disjunctive normal
    form, so parentheses are never needed. A hydrographic file in SWAT mode reads
    `executerModeleHydrographique == true && nomChoixModeleHydrographique == 'SWAT'`;
    an output guarded by two growth models reads
    `sorties_eau == true && plante == 'AqYield' || sorties_eau == true && plante == 'AqYieldNC'`.

    Parentheses stay out on purpose: the condition is read by an administrator in
    a table cell, and the model's own guards all flatten to this form.

    A parameter missing from the configuration counts as unset: an equality is
    then false, an inequality true.
    """
    if "||" in expression:
        return any(evaluate_condition(part, config) for part in expression.split("||"))
    if "&&" in expression:
        return all(evaluate_condition(part, config) for part in expression.split("&&"))

    match = _COMPARISON.match(expression)
    if match is None:
        raise InvalidExpression(f"unrecognised condition: {expression!r}")

    expected = _literal(match["value"])
    current = config.get(match["param"])

    # The front end may send booleans as text: align before comparing.
    if isinstance(expected, bool) and isinstance(current, str):
        current = current.lower() == "true"

    return current == expected if match["op"] == "==" else current != expected


def is_applicable(spec: DataSpec, config: dict[str, Any]) -> bool:
    """Is this file expected, given the project configuration?

    With no condition a file always applies. An unreadable condition must not
    hide a file: it is treated as applicable so the problem stays visible.
    """
    if not spec.required_if:
        return True
    try:
        return evaluate_condition(spec.required_if, config)
    except InvalidExpression:
        return True


def applicable_specs(specs: Iterable[DataSpec], config: dict[str, Any]) -> list[DataSpec]:
    return [s for s in specs if is_applicable(s, config)]


def matches_instance(spec: DataSpec, file_name: str) -> bool:
    """Does this file name belong to that multi-instance family?

    Used by bulk import: a ZIP of files is filed into the right datasets without
    asking the user to name them.
    """
    if spec.file_name is not None:
        return file_name == spec.file_name
    if not spec.file_name_pattern:
        return False
    return re.fullmatch(spec.file_name_pattern, file_name) is not None


def _situee_dans(spec: DataSpec, chemin: str) -> int:
    """Longueur du dossier de la spec retrouve dans le chemin de l'archive.

    Zero si le chemin ne passe pas par la. Sert a departager, donc la spec la
    plus precise (le dossier le plus long) gagne.
    """
    dossier = chemin.replace("\\", "/").rsplit("/", 1)[0] if "/" in chemin else ""
    attendu = (spec.relative_dir or "").strip("/")
    if not attendu or not dossier:
        return 0
    return len(attendu) if attendu in dossier else 0


def resolve_spec(
    specs: Sequence[DataSpec], file_name: str, archive_path: str | None = None
) -> DataSpec | None:
    """Find the spec matching a file name.

    Exact matches win over patterns: `canaux.csv` must land on its own spec, not
    on the "one file per canal" family.

    Quand plusieurs specs acceptent le meme nom, le chemin dans l'archive
    tranche : `meteo/observee/2019.csv` et `meteo/simulee/rcp8.5/2019.csv`
    portent le meme nom et ne sont pas le meme fichier. Sans cet arbitrage, les
    quatre series climatiques d'un territoire finissent dans la meme, et le run
    reclame une meteo qu'il ne trouve pas.
    """
    for candidats in (
        [s for s in specs if s.file_name == file_name],
        [s for s in specs if matches_instance(s, file_name)],
    ):
        if not candidats:
            continue
        if len(candidats) > 1 and archive_path:
            situees = sorted(
                ((_situee_dans(s, archive_path), s) for s in candidats),
                key=lambda couple: couple[0],
                reverse=True,
            )
            if situees[0][0] > 0:
                return situees[0][1]
        return candidats[0]
    return None


def order_by_dependencies(specs: Sequence[DataSpec]) -> list[list[str]]:
    """Group specs in levels: a level depends only on the previous ones.

    Feeds the preprocessing module (which file to produce before which) and the
    graph view. Any cycle is returned as a last level rather than failing the call.
    """
    known = {s.id for s in specs}
    remaining = {s.id: {d for d in s.depends_on if d in known} for s in specs}
    levels: list[list[str]] = []

    while remaining:
        ready = sorted(spec_id for spec_id, deps in remaining.items() if not deps)
        if not ready:  # cycle: return the rest as is rather than looping forever
            levels.append(sorted(remaining))
            break
        levels.append(ready)
        for spec_id in ready:
            del remaining[spec_id]
        for deps in remaining.values():
            deps.difference_update(ready)

    return levels


@dataclass(frozen=True, slots=True)
class SpecIssue:
    """What is wrong with a spec, and where."""

    field: str
    message: str


def validate_spec(spec: DataSpec, known_ids: Iterable[str] = ()) -> list[SpecIssue]:
    """Check a spec written by hand, before it enters the catalog.

    Every refusal here describes a spec the platform could store but never use:
    a file it cannot name, a condition it cannot read, a dependency on something
    that does not exist. Letting them through means discovering the problem when
    a project asks for its files — screens later, and without the context.
    """
    issues: list[SpecIssue] = []

    if not spec.file_name and not spec.file_name_pattern:
        issues.append(SpecIssue(
            "file_name", "un nom de fichier ou un motif est nécessaire pour le reconnaître"
        ))
    if spec.file_name and spec.file_name_pattern:
        issues.append(SpecIssue(
            "file_name_pattern",
            "nom et motif sont exclusifs : un fichier unique ou une famille, pas les deux",
        ))
    if spec.file_name_pattern:
        try:
            re.compile(spec.file_name_pattern)
        except re.error as exc:
            issues.append(SpecIssue("file_name_pattern", f"motif illisible : {exc}"))

    if not spec.relative_dir.strip():
        issues.append(SpecIssue("relative_dir", "l'emplacement dans includes/ est nécessaire"))

    if spec.required_if:
        try:
            evaluate_condition(spec.required_if, {})
        except InvalidExpression:
            issues.append(SpecIssue(
                "required_if",
                "condition illisible : forme attendue « param == valeur », "
                "plusieurs conditions liées par && (et) ou || (ou)",
            ))

    known = set(known_ids)
    for reference in spec.depends_on:
        if known and reference not in known:
            issues.append(SpecIssue("depends_on", f"dépendance inconnue du catalogue : {reference}"))

    positions = [f.position for f in spec.fields]
    if len(positions) != len(set(positions)):
        issues.append(SpecIssue(
            "fields", "deux champs partagent la même position : c'est elle qui les identifie"
        ))

    return issues


def validate_parameter(
    spec: ParameterSpec, known_names: Iterable[str] = ()
) -> list[SpecIssue]:
    """Verifie un parametre ecrit a la main, avant qu'il n'entre au catalogue.

    Chaque refus decrit un parametre que la plateforme pourrait stocker mais
    jamais servir : une valeur par defaut que son propre type refuse, une
    condition qu'on ne peut pas evaluer, une dependance vers un parametre qui
    n'existe pas.
    """
    issues: list[SpecIssue] = []

    if not spec.label.strip():
        issues.append(SpecIssue("label", "un libelle est necessaire pour l'afficher"))
    if not spec.group.strip():
        issues.append(SpecIssue("group", "la section du launcher est necessaire"))

    if spec.default is not None and not spec.accepts(spec.default):
        issues.append(SpecIssue(
            "default",
            f"la valeur par defaut n'est pas un {spec.type.value.lower()} valide",
        ))

    if spec.options_from and "#" not in spec.options_from:
        issues.append(SpecIssue(
            "options_from", "forme attendue : <identifiant de fichier>#<champ>"
        ))

    if spec.enabled_if:
        try:
            evaluate_condition(spec.enabled_if, {})
        except InvalidExpression:
            issues.append(SpecIssue(
                "enabled_if",
                "condition illisible : forme attendue « autreParametre == true », "
                "plusieurs conditions liees par && (et) ou || (ou)",
            ))
        else:
            connus = set(known_names)
            for partie in _operandes(spec.enabled_if):
                commandant = partie.strip().split("==")[0].split("!=")[0].strip()
                if commandant == spec.name:
                    issues.append(SpecIssue(
                        "enabled_if", "un parametre ne peut pas dependre de lui-meme"
                    ))
                elif connus and commandant not in connus:
                    issues.append(SpecIssue(
                        "enabled_if", f"parametre inconnu du launcher : {commandant}"
                    ))

    return issues
