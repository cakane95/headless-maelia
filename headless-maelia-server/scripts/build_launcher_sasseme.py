"""Construit `launcherSassemeTest` : structure de launcherTest, valeurs de launcherSasseme.

Trois launchers sont livres avec le modele, et aucun ne suffit seul pour executer
le territoire de Sasseme depuis la plateforme :

* `launcherBase` declare les 149 variables du catalogue, mais porte un bloc
  `output { display }` et pas de condition d'arret : GAMA headless le refuse.
* `launcherTest` en est la copie headless — meme liste, meme valeurs, sans
  affichage, avec `until: simulationTerminee`. C'est celui que la plateforme
  execute, et le seul dont on ait la preuve qu'il mene un run a terme.
* `launcherSasseme` porte les valeurs calees par les modelisateurs sur
  `includes_sasseme`, mais il n'en declare que 140 et garde son affichage.

Ce script prend la **structure** de `launcherTest` et les **valeurs** de
`launcherSasseme`. Le resultat declare donc les 149 variables — un scenario peut
surcharger n'importe laquelle — tout en lisant `includes_sasseme` par defaut.

Usage (depuis la racine du depot) :
    python headless-maelia-server/scripts/build_launcher_sasseme.py [--verifier]
"""

from __future__ import annotations

import argparse
import pathlib
import re
import sys

RACINE = pathlib.Path(__file__).resolve().parents[2]
MAIN = RACINE / "gama-models" / "MAELIA_1.4.29_GAMA_2025-06" / "models" / "main"
STRUCTURE = MAIN / "launcherTest.gaml"
VALEURS = MAIN / "launcherSasseme.gaml"
CIBLE = MAIN / "launcherSassemeTest.gaml"

MODELE = "launcherSassemeTest"
EXPERIENCE = "sasseme_maelia"

# `parameter 'Libelle' var: nom <- valeur;`
DECLARATION = re.compile(
    r"(?P<avant>^[^\S\n]*parameter\s+(?:'[^']*'|\"[^\"]*\")?\s*var:\s*"
    r"(?P<nom>\w+)\s*<-\s*)(?P<valeur>.+?)(?P<apres>;)",
    re.M,
)

GABARIT_ENTETE = """/***************************************************************************
 * MAELIA - http://maelia-platform.inra.fr/
 *    Copyright (C) 2014-2015
 *    INRA - UMR 1248 AGIR ;
 *    Universite Toulouse 1 Capitole - IRIT
 *    CNRS - UMR 5563 GET
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program (Maelia/Licence_gpl_v3.txt).  If not, see
 * <http://www.gnu.org/licenses/>.
***************************************************************************/
/**
 *  launcherSassemeTest
 *  Description: la STRUCTURE de launcherTest, les VALEURS de launcherSasseme.
 *
 *  Chacun des deux apporte la moitie de ce qu'il faut pour executer le
 *  territoire de Sasseme en headless :
 *
 *    - launcherTest est deja prouve headless (pas de bloc d'affichage,
 *      until: simulationTerminee) et declare les NB_STRUCTURE parametres que le
 *      catalogue de la plateforme connait, si bien qu'un scenario peut
 *      surcharger n'importe lequel d'entre eux ;
 *
 *    - launcherSasseme porte les valeurs que les modelisateurs ont calees sur
 *      le territoire includes_sasseme, mais il n'en declare que NB_VALEURS.
 *
 *  Resultat : NB_REPRISES valeurs par defaut reprises de Sasseme, NB_ABSENTS
 *  laissees a celles de launcherTest faute d'etre declarees par Sasseme.
 *  Le territoire lu par defaut est includes_sasseme.
 *
 *  Les parametres ne sont PAS figes ici : la plateforme les surcharge au load,
 *  et impose en plus idSimulationAPI=<runId>, ce qui fait ecrire les sorties
 *  dans models/main/log/<runId> (cf. action majChemins).
 *
 *  Engendre par scripts/build_launcher_sasseme.py — ne pas editer a la main :
 *  une montee de version du modele demande de le regenerer.
 */
"""


def valeurs_de(chemin: pathlib.Path) -> dict[str, str]:
    """Valeur par defaut de chaque parametre declare par ce launcher.

    La premiere declaration gagne, comme dans GAMA : les launchers gardent des
    variantes commentees plus bas dans le fichier.
    """
    texte = chemin.read_bytes().decode("utf-8", errors="replace")
    releves: dict[str, str] = {}
    for trouve in DECLARATION.finditer(texte):
        releves.setdefault(trouve.group("nom"), trouve.group("valeur"))
    return releves


def construire() -> tuple[str, dict[str, list[str]]]:
    """Le texte du launcher, et le compte rendu de ce qui a ete repris."""
    structure = STRUCTURE.read_bytes().decode("utf-8", errors="replace")
    structure = structure.replace("\r\n", "\n")
    retenues = valeurs_de(VALEURS)
    declarees = valeurs_de(STRUCTURE)

    reprises: list[str] = []
    inchanges: list[str] = []

    def remplacer(trouve: re.Match[str]) -> str:
        nom = trouve.group("nom")
        if nom not in retenues:
            inchanges.append(nom)
            return trouve.group(0)
        if retenues[nom] != trouve.group("valeur"):
            reprises.append(nom)
        return trouve.group("avant") + retenues[nom] + trouve.group("apres")

    lignes = DECLARATION.sub(remplacer, structure).split("\n")

    # Renommer la DECLARATION, jamais sa citation : l'entete de launcherTest
    # parle de `model launcherTest` dans sa prose, et la toucher ferait couper
    # le fichier au mauvais endroit.
    indice_model = None
    for i, ligne in enumerate(lignes):
        if ligne.startswith("model launcherTest"):
            lignes[i] = "model " + MODELE
            indice_model = i
        elif ligne.startswith("experiment test_maelia"):
            lignes[i] = ligne.replace("test_maelia", EXPERIENCE, 1)
    if indice_model is None:
        raise SystemExit("declaration `model launcherTest` introuvable")

    entete = GABARIT_ENTETE
    for jeton, valeur in (
        ("NB_STRUCTURE", len(declarees)),
        ("NB_VALEURS", len(retenues)),
        ("NB_REPRISES", len(reprises)),
        ("NB_ABSENTS", len(inchanges)),
    ):
        entete = entete.replace(jeton, str(valeur))

    texte = entete + "\n".join(lignes[indice_model:])
    compte = {
        "reprises": sorted(reprises),
        "inchanges": sorted(inchanges),
        "ignores": sorted(set(retenues) - set(declarees)),
        "declarees": sorted(declarees),
    }
    return texte, compte


def main() -> int:
    arguments = argparse.ArgumentParser(description=__doc__)
    arguments.add_argument(
        "--verifier", action="store_true", help="n'ecrit rien, affiche le compte rendu"
    )
    options = arguments.parse_args()

    for chemin in (STRUCTURE, VALEURS):
        if not chemin.is_file():
            print(f"launcher introuvable : {chemin}", file=sys.stderr)
            return 1

    texte, compte = construire()

    print(f"structure : {len(compte['declarees'])} parametres ({STRUCTURE.name})")
    print(f"reprises de {VALEURS.name} : {len(compte['reprises'])}")
    print(f"inchanges (absents de Sasseme) : {len(compte['inchanges'])}")
    print("  " + ", ".join(compte["inchanges"]))
    if compte["ignores"]:
        print(f"ignores (declares par Sasseme seul) : {', '.join(compte['ignores'])}")

    if options.verifier:
        return 0

    # Le modele est en CRLF : ecrire en LF ferait un fichier mixte.
    CIBLE.write_bytes(texte.replace("\n", "\r\n").encode("utf-8"))
    print(f"ecrit : {CIBLE.relative_to(RACINE)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
