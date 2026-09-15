<div class="maelia-hero" markdown>

# Plateforme headless-MAELIA

Simulation multi-agents **eau / agriculture / normes** sur moteur GAMA headless.
Décrire un modèle, l'alimenter en données, composer des scénarios, exécuter et
lire les résultats — sans jamais installer GAMA.

</div>

## Je veux…

| Je veux… | Section |
|---|---|
| **comprendre** ce que fait la plateforme et pourquoi elle existe | Comprendre |
| **l'installer** et lancer une première simulation | Démarrer |
| **m'en servir** pour une tâche précise | Guides |
| **savoir comment c'est fait** avant d'y toucher | Architecture |
| **chercher** un fichier, un paramètre, une route d'API | Référence |
| **y contribuer** | Contribuer |

Les sections apparaissent dans le menu du haut au fur et à mesure qu'elles sont
écrites.

!!! abstract "En une phrase"
    MAELIA est un modèle de simulation de socio-agrosystèmes écrit en GAML et
    exécuté par GAMA. Cette plateforme met une interface web devant lui : elle
    décrit ce que le modèle attend, versionne les données d'un territoire,
    compose des scénarios, pilote les exécutions et rend les sorties lisibles.

## Démarrage en trois commandes

Prérequis : Docker et Docker Compose v2. **Rien d'autre** — ni Java, ni GAMA,
ni Python.

```bash
git clone <dépôt> && cd headless-maelia
docker compose up -d
curl http://localhost:8000/api/v1/health/dependencies   # doit répondre "status": "ok"
```

--8<-- "_partials/services.md:urls"

## Le modèle, en chiffres

--8<-- "_partials/chiffres-modele.md:tout"

Aucun de ces noms n'est écrit dans le code de la plateforme : les trois
catalogues sont **engendrés depuis le GAML du modèle**, et se régénèrent à
chaque montée de version.

## Les deux domaines

--8<-- "_partials/deux-domaines.md:tableau"

--8<-- "_partials/deux-domaines.md:regle"

C'est ce qui permettra d'accueillir un second modèle que MAELIA sans réécrire
la plateforme.

## État de cette documentation

Cette documentation est en cours de refonte. Les sections listées ci-dessus
apparaissent dans le menu **au fur et à mesure qu'elles sont écrites** ; ce qui
n'y figure pas encore se trouve dans la
[documentation antérieure](archive/index.md), conservée mais **non fiable** —
elle contient des chiffres périmés, des chemins disparus et une page décrivant
du code qui n'a jamais existé. Le détail de ce qui a motivé la refonte y est
expliqué.
