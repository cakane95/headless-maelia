"""Ce qui manque vraiment pour lancer une simulation.

Un projet tourne sur SES données : ce qui manque manquera pour de bon. La
distinction obligatoire / facultatif vient du modèle lui-même — il s'arrête sur
les uns, il continue sans les autres — et c'est elle qui décide si un lancement
part ou s'arrête ici, vingt minutes plus tôt.
"""

from app.contexts.catalog.domain.models import DataSpec, FileKind
from app.contexts.project.domain.models import FileStatus
from app.contexts.project.domain.services import compute_completion


def spec(spec_id: str, required: bool = True) -> DataSpec:
    return DataSpec(
        id=spec_id,
        label=f"{spec_id}.csv",
        module="modeleAgricole",
        kind=FileKind.CSV,
        relative_dir="modeleAgricole",
        file_name=f"{spec_id}.csv",
        required=required,
    )


def inventory(**statuses: FileStatus) -> dict[str, dict[str, FileStatus]]:
    return {name: {"": status} for name, status in statuses.items()}


def test_nothing_missing_when_every_required_file_is_valid():
    completion = compute_completion(
        [spec("a"), spec("b"), spec("c", required=False)],
        inventory(a=FileStatus.VALID, b=FileStatus.VALID),
    )
    assert completion.missing == ()


def test_an_optional_file_never_blocks():
    """Le modèle continue sans : le lui réclamer arrêterait un run qui marche."""
    completion = compute_completion(
        [spec("a"), spec("facultatif", required=False)],
        inventory(a=FileStatus.VALID),
    )
    assert completion.missing == ()


def test_a_missing_required_file_blocks_and_is_named():
    completion = compute_completion([spec("a"), spec("b")], inventory(a=FileStatus.VALID))
    assert [e.data_spec_id for e in completion.missing] == ["b"]


def test_a_draft_is_not_a_supplied_file():
    """Un brouillon n'est pas publié : le run ne le lirait pas."""
    completion = compute_completion([spec("a")], inventory(a=FileStatus.DRAFT))
    assert [e.data_spec_id for e in completion.missing] == ["a"]


def test_an_invalid_file_blocks_too():
    """Le charger produirait un résultat qu'on ne pourrait pas défendre."""
    completion = compute_completion([spec("a")], inventory(a=FileStatus.INVALID))
    assert [e.data_spec_id for e in completion.missing] == ["a"]


def test_only_applicable_specs_are_counted():
    """L'applicabilité est calculée avant : un module éteint n'apporte pas ses
    fichiers, donc ils ne manquent pas."""
    completion = compute_completion([spec("a")], inventory(a=FileStatus.VALID))
    assert completion.expected == 1 and completion.missing == ()
