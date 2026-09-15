---
search:
  exclude: true
---

<div class="maelia-hero" markdown>

# Archive — Plateforme headless-MAELIA

Simulation multi-agents **eau / agriculture / normes** sur moteur GAMA headless.
Décrire un modèle, l'alimenter en données, composer des scénarios, exécuter — sans
jamais installer GAMA.

</div>

!!! danger "Page archivée — ne pas s'y fier"
    Rédigée avant la refonte de la documentation. Conservée pour mémoire :
    elle peut décrire des types, des chemins ou des chiffres qui n'existent
    plus. Remplacée par la nouvelle page d'accueil — voir [le sommaire](../index.md).

## Par où commencer

<div class="grid cards" markdown>

-   :material-cog-outline: **Architecture backend**

    ---

    Les six forces qui contraignent le backend, le découpage en contextes métier,
    et le chemin de migration.

    [:octicons-arrow-right-24: Architecture backend](backend.md)

-   :material-code-braces: **Backend — bonnes pratiques**

    ---

    Le *comment* : où placer un fichier, quoi mettre dans chaque couche, avec une
    tranche verticale complète en code.

    [:octicons-arrow-right-24: Bonnes pratiques](backend-bonnes-pratiques.md)

-   :material-monitor-dashboard: **Architecture frontend**

    ---

    Deux espaces, deux layouts. Structure du SPA React et règle d'isolation du
    réseau.

    [:octicons-arrow-right-24: Architecture frontend](frontend.md)

-   :material-palette-outline: **Frontend — bonnes pratiques**

    ---

    Découpage du code, design system MAELIA, responsive et accessibilité WCAG AA.

    [:octicons-arrow-right-24: Bonnes pratiques](frontend-bonnes-pratiques.md)

-   :material-database-outline: **Données, sorties et paramètres**

    ---

    Inventaire de référence du modèle : 82 fichiers d'entrée, 128 sorties,
    148 paramètres, et leurs relations.

    [:octicons-arrow-right-24: Inventaire MAELIA](donnees-et-parametres.md)

-   :material-file-tree-outline: **Modèle de domaine**

    ---

    Structure des données d'entrée attendues par le modèle.

    [:octicons-arrow-right-24: Données d'entrée](modele-domaine-donnees-entree.md)

</div>

## Les deux domaines

La plateforme couvre deux usages distincts, séparés jusque dans le front
(`/admin` et `/simulation`).

| | **Administration** | **Simulation** |
|---|---|---|
| Qui | administrateur de la plateforme | modélisateur, observateur |
| Quoi | *décrire* un modèle : entrées, paramètres, sorties | *exploiter* un modèle sur un territoire |
| Produit | des **schémas** | des **données** et des **résultats** |

**Administration produit les schémas que Simulation consomme.** La dépendance va
dans un seul sens — c'est ce qui permettra d'accueillir un second modèle que
MAELIA sans réécrire la plateforme.

## Démarrage rapide

```bash
docker compose up -d
curl http://localhost:8000/api/v1/health/dependencies   # doit répondre "status": "ok"
```

| Service | URL |
|---|---|
| Frontend | <http://localhost:5173> |
| API (Swagger) | <http://localhost:8000/docs> |
| Documentation | <http://localhost:8082> |
| Console MinIO | <http://localhost:9001> |

Le détail — dépannage, contraintes d'installation, état du projet — est dans le
`README.md` du dépôt.

!!! info "Sections en construction"
    Les guides d'installation et d'utilisation, la référence de l'API REST et la
    charte graphique n'ont pas encore de page dédiée : leur contenu vit
    aujourd'hui dans le `README.md` et dans les documents d'architecture
    ci-dessus.
