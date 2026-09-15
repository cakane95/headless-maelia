"""Writing to the input catalog: what is refused, and why.

Each refusal describes a spec the platform could store but never use. Letting
one through means discovering the problem when a project asks for its files —
screens later, and without the context that would explain it.
"""

import pytest

from app.contexts.catalog.application.use_cases import restore_spec, save_spec
from app.contexts.catalog.domain.models import DataSpec, FieldSpec, FileKind
from app.contexts.catalog.domain.services import validate_spec
from app.shared.errors import NotFoundError, ValidationError


def spec(**overrides) -> DataSpec:
    base = dict(
        id="agri.culture.essai",
        label="essai.csv",
        module="modeleAgricole",
        kind=FileKind.CSV,
        relative_dir="modeleAgricole/culture",
        file_name="essai.csv",
    )
    return DataSpec(**{**base, **overrides})


class FakeCatalog:
    def __init__(self, *specs: DataSpec) -> None:
        self.specs = {s.id: s for s in specs}

    async def list_all(self) -> list[DataSpec]:
        return list(self.specs.values())

    async def get(self, spec_id: str) -> DataSpec | None:
        return self.specs.get(spec_id)

    async def upsert(self, value: DataSpec) -> DataSpec:
        self.specs[value.id] = value
        return value

    async def delete(self, spec_id: str) -> None:
        self.specs.pop(spec_id, None)


class TestWhatMakesASpecUsable:
    def test_a_file_the_platform_cannot_name(self):
        issues = validate_spec(spec(file_name=None, file_name_pattern=None))
        assert [i.field for i in issues] == ["file_name"]

    def test_a_name_and_a_pattern_are_exclusive(self):
        """One file, or a family — the two readings are not compatible."""
        issues = validate_spec(spec(file_name="essai.csv", file_name_pattern=r"essai.+\.csv"))
        assert any(i.field == "file_name_pattern" for i in issues)

    def test_an_unreadable_pattern(self):
        issues = validate_spec(spec(file_name=None, file_name_pattern="prix[("))
        assert any("motif illisible" in i.message for i in issues)

    def test_a_condition_nobody_can_evaluate(self):
        issues = validate_spec(spec(required_if="n importe quoi"))
        assert any(i.field == "required_if" for i in issues)

    def test_a_condition_the_platform_understands(self):
        assert validate_spec(
            spec(required_if="executerModeleHydrographique == true && nomChoix == 'SWAT'")
        ) == []

    def test_two_fields_at_the_same_position(self):
        """Position is a field's identity: a transposed file repeats labels."""
        issues = validate_spec(spec(fields=(
            FieldSpec(name="A", position=0), FieldSpec(name="B", position=0),
        )))
        assert any(i.field == "fields" for i in issues)

    def test_a_dependency_on_something_that_does_not_exist(self):
        issues = validate_spec(spec(depends_on=("agri.inexistant",)), known_ids=["agri.autre"])
        assert any(i.field == "depends_on" for i in issues)


class TestSaving:
    async def test_a_valid_spec_goes_in(self):
        catalog = FakeCatalog()
        assert (await save_spec(catalog, spec())).id == "agri.culture.essai"

    async def test_an_invalid_spec_is_refused_with_its_reasons(self):
        with pytest.raises(ValidationError) as failure:
            await save_spec(FakeCatalog(), spec(relative_dir="", required_if="???"))
        assert {i["field"] for i in failure.value.issues} == {"relative_dir", "required_if"}


class TestRestoring:
    async def test_puts_back_what_the_reference_says(self):
        """Editing flips a spec to USER, which freezes it on one model version."""
        edited = spec(label="renommé à la main", origin="USER")
        reference = spec(label="essai.csv", origin="SEED")

        restored = await restore_spec(FakeCatalog(edited), edited.id, [reference])
        assert restored.label == "essai.csv" and restored.origin == "SEED"

    async def test_a_hand_written_spec_has_nothing_to_restore(self):
        with pytest.raises(NotFoundError, match="catalogue de référence"):
            await restore_spec(FakeCatalog(spec()), "agri.culture.essai", [])
