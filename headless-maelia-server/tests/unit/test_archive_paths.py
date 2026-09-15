"""Le chemin dans l'archive porte du sens, et il ne faut pas le perdre.

Un territoire MAELIA contient `meteo/observee/2019.csv` ET
`meteo/simulee/rcp8.5/2019.csv` : même nom, fichiers différents. Apparier sur le
seul nom de fichier les faisait atterrir au même endroit — et le run réclamait
ensuite une météo introuvable.
"""

from app.contexts.catalog.domain.models import DataSpec, FileKind
from app.contexts.catalog.domain.services import resolve_spec
from app.contexts.dataset.domain.services import instance_key_for, normalise_upload_name

ANNEE = r"\d{4}\.csv"

OBSERVEE = DataSpec(
    id="commun.meteo.observee", label="observée", module="modeleCommun",
    kind=FileKind.CSV, relative_dir="modeleCommun/meteo/observee", file_name_pattern=ANNEE,
)
SIMULEE = DataSpec(
    id="commun.meteo.simulee", label="simulée", module="modeleCommun",
    kind=FileKind.CSV, relative_dir="modeleCommun/meteo/simulee", file_name_pattern=ANNEE,
)
ESPECES = DataSpec(
    id="agri.culture.especesCultivees", label="especesCultivees.csv", module="modeleAgricole",
    kind=FileKind.CSV, relative_dir="modeleAgricole/culture", file_name="especesCultivees.csv",
)

TOUTES = [OBSERVEE, SIMULEE, ESPECES]


class TestQuelleSpecPourCeFichier:
    def test_le_chemin_departage_deux_familles_de_meme_motif(self):
        assert resolve_spec(TOUTES, "2019.csv", "modeleCommun/meteo/observee/2019.csv") is OBSERVEE
        assert (
            resolve_spec(TOUTES, "2019.csv", "modeleCommun/meteo/simulee/rcp8.5/2019.csv")
            is SIMULEE
        )

    def test_sans_chemin_utilisable_on_garde_le_premier(self):
        """Une archive plate reste importable : mieux vaut un choix qu'un refus."""
        assert resolve_spec(TOUTES, "2019.csv", "2019.csv") is OBSERVEE

    def test_un_nom_exact_l_emporte_toujours_sur_un_motif(self):
        trouve = resolve_spec(TOUTES, "especesCultivees.csv", "ailleurs/especesCultivees.csv")
        assert trouve is ESPECES

    def test_un_nom_inconnu_ne_correspond_a_rien(self):
        assert resolve_spec(TOUTES, "inconnu.csv", "modeleCommun/inconnu.csv") is None


class TestCleDInstance:
    def test_elle_porte_le_sous_dossier_quand_l_archive_en_a_un(self):
        """Le modèle lit `simulee/<scénario>/<année>.csv` : le scénario ne se
        devine pas depuis le nom du fichier."""
        cle = instance_key_for(SIMULEE, "2019.csv", "modeleCommun/meteo/simulee/rcp8.5/2019.csv")
        assert cle == "rcp8.5/2019.csv"

    def test_pas_de_sous_dossier_pas_de_prefixe(self):
        cle = instance_key_for(OBSERVEE, "2019.csv", "modeleCommun/meteo/observee/2019.csv")
        assert cle == "2019.csv"

    def test_un_fichier_unique_n_a_pas_d_instance(self):
        assert instance_key_for(ESPECES, "especesCultivees.csv", "x/especesCultivees.csv") is None

    def test_le_nom_stocke_ne_contient_pas_le_sous_dossier(self):
        """Le sous-dossier dit où écrire, pas comment le fichier s'appelle."""
        assert normalise_upload_name(SIMULEE, "2019.csv", "rcp8.5/2019.csv") == "2019.csv"
