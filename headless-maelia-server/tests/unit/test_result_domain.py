"""Profiling and aggregating outputs — no database, no file system.

The fixture reproduces the shape MAELIA actually writes: `;` separated, units in
brackets, one row per plot and per period, empty cells where an operation does
not apply.
"""

import pytest

from app.contexts.result.domain import services, suggest
from app.contexts.result.domain.models import Aggregate, ChartType, ColumnRole, SeriesQuery

SORTIES_EAU = (
    b"annee;parcelle;couvert;pluie[mm];irrigation[mm];satisfactionHydrique[%]\n"
    b"2019;p1;bl\xc3\xa9;215.9;10.0;80\n"
    b"2019;p2;mais;215.9;30.0;60\n"
    b"2020;p1;bl\xc3\xa9;180.5;20.0;70\n"
    b"2020;p2;mais;180.5;40.0;50\n"
)


def table():
    return services.read_table(SORTIES_EAU)


class TestReading:
    def test_sniffs_the_delimiter_and_keeps_every_row(self):
        header, rows = table()
        assert header[0] == "annee"
        assert len(rows) == 4

    def test_falls_back_on_latin1_rather_than_failing(self):
        header, _ = services.read_table("annee;cultur\xe9".encode("latin-1"))
        assert header[1].endswith("\xe9")

    def test_pads_a_short_row_instead_of_dropping_it(self):
        _, rows = services.read_table(b"a;b;c\n1;2\n")
        assert rows == [("1", "2", "")]


class TestProfiling:
    def test_reads_the_unit_out_of_the_header(self):
        column = services.profile(*table()).column("pluie[mm]")
        assert (column.label, column.unit) == ("pluie", "mm")

    def test_a_year_is_an_axis_not_a_measure(self):
        assert services.profile(*table()).column("annee").role is ColumnRole.TEMPORAL

    def test_numbers_are_measures_and_words_are_dimensions(self):
        profiled = services.profile(*table())
        assert profiled.column("pluie[mm]").role is ColumnRole.MEASURE
        assert profiled.column("couvert").role is ColumnRole.DIMENSION

    def test_a_dimension_carries_its_values_so_a_filter_can_be_offered(self):
        assert services.profile(*table()).column("couvert").values == ("blé", "mais")

    def test_a_mostly_numeric_column_stays_a_measure(self):
        """MAELIA leaves cells empty; that must not turn a measure into a label."""
        header, rows = services.read_table(b"x;v\n1;2.0\n2;\n3;4.0\n4;5.0\n")
        assert services.profile(header, rows).column("v").role is ColumnRole.MEASURE


class TestSeries:
    def test_means_over_the_axis(self):
        header, rows = table()
        result = services.build_series(
            header, rows, SeriesQuery(x="annee", measures=("irrigation[mm]",))
        )
        assert result.as_rows() == [
            {"x": "2019", "irrigation[mm]": 20.0},
            {"x": "2020", "irrigation[mm]": 30.0},
        ]

    def test_sums_when_asked(self):
        header, rows = table()
        result = services.build_series(
            header, rows,
            SeriesQuery(x="annee", measures=("irrigation[mm]",), aggregate=Aggregate.SUM),
        )
        assert dict(result.series[0].points) == {"2019": 40.0, "2020": 60.0}

    def test_splits_into_one_series_per_category(self):
        header, rows = table()
        result = services.build_series(
            header, rows,
            SeriesQuery(x="annee", measures=("irrigation[mm]",), series_by="couvert"),
        )
        assert [s.key for s in result.series] == ["blé — irrigation[mm]", "mais — irrigation[mm]"]

    def test_a_filter_restricts_the_rows_read(self):
        header, rows = table()
        result = services.build_series(
            header, rows,
            SeriesQuery(
                x="annee", measures=("irrigation[mm]",), filters={"couvert": ("mais",)}
            ),
        )
        assert dict(result.series[0].points) == {"2019": 30.0, "2020": 40.0}

    def test_the_axis_is_ordered_numerically_not_alphabetically(self):
        header, rows = services.read_table(b"jour;v\n10;1\n9;1\n100;1\n")
        result = services.build_series(header, rows, SeriesQuery(x="jour", measures=("v",)))
        assert result.x_values == ("9", "10", "100")

    def test_reports_truncation_rather_than_silently_cutting(self):
        header, rows = table()
        result = services.build_series(
            header, rows, SeriesQuery(x="annee", measures=("pluie[mm]",), limit=1)
        )
        assert result.truncated and result.x_values == ("2019",)

    def test_an_unknown_column_is_named_in_the_error(self):
        header, rows = table()
        with pytest.raises(KeyError, match="rendement"):
            services.build_series(header, rows, SeriesQuery(x="annee", measures=("rendement",)))


class TestSuggestions:
    def test_a_temporal_axis_yields_a_line_chart(self):
        proposals = suggest.suggest(services.profile(*table()))
        assert proposals[0].chart is ChartType.LINE
        assert proposals[0].query.x == "annee"

    def test_a_small_dimension_becomes_a_breakdown(self):
        """Which dimension wins matters less than proposing one: `couvert` and
        `parcelle` both split into two readable groups here."""
        proposals = suggest.suggest(services.profile(*table()))
        split = [p for p in proposals if p.query.series_by]
        assert split and split[0].query.series_by in {"couvert", "parcelle"}
        assert split[0].chart is ChartType.STACKED_BAR

    def test_only_measures_sharing_a_unit_are_compared(self):
        """Mixing mm and % on one axis would make the smaller one unreadable."""
        grouped = [
            p for p in suggest.suggest(services.profile(*table())) if len(p.query.measures) > 1
        ]
        assert grouped and all(m.endswith("[mm]") for m in grouped[0].query.measures)

    def test_a_table_without_measures_suggests_nothing(self):
        header, rows = services.read_table(b"ilot;zone\na;13218\n")
        assert suggest.suggest(services.profile(header, rows)) == []
