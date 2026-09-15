"""A saved reading must survive the trip through the database.

The query is stored as JSON: if the round trip loses a filter or an aggregate,
the reading redrawn next year is not the one that was saved — and nothing would
say so, the chart would simply be wrong.
"""

import uuid
from types import SimpleNamespace

from app.contexts.result.domain.models import Aggregate, SeriesQuery
from app.contexts.result.infrastructure.repository import _to_domain, _to_json

FULL = SeriesQuery(
    x="annee",
    measures=("RECOLTE_rendement[t/ha]", "BIOMASSE_export[t/ha]"),
    series_by="culture",
    aggregate=Aggregate.SUM,
    filters={"parcelle": ("1_001", "2_004")},
    limit=120,
)


def row(query: dict) -> SimpleNamespace:
    return SimpleNamespace(
        id=uuid.uuid4(),
        project_id=uuid.uuid4(),
        name="Fig. 5 — rendement par année",
        file_name="suiviOTParParcelle.csv",
        chart="LINE",
        query=query,
        created_at=None,
    )


def test_round_trip_keeps_every_part_of_the_query():
    assert _to_domain(row(_to_json(FULL))).query == FULL


def test_filters_come_back_as_tuples_not_lists():
    """The domain query is frozen: a list would make it unhashable and mutable."""
    rebuilt = _to_domain(row(_to_json(FULL))).query
    assert rebuilt.filters["parcelle"] == ("1_001", "2_004")


def test_a_query_stored_before_a_field_existed_still_loads():
    """An older row has no `filters` key: it must read as « no filter »."""
    rebuilt = _to_domain(row({"x": "annee", "measures": ["a"]})).query
    assert rebuilt.filters == {}
    assert rebuilt.aggregate is Aggregate.MEAN
    assert rebuilt.limit == 500


def test_an_empty_query_does_not_explode():
    rebuilt = _to_domain(row({})).query
    assert rebuilt.x == "" and rebuilt.measures == ()
