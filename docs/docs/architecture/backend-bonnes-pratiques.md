# Backend — bonnes pratiques d'implémentation

!!! abstract "Objet de ce document"
    Le **comment**. [Architecture backend](backend.md) explique *pourquoi* le
    backend est découpé ainsi ; ce document dit *comment écrire le code* qui s'y
    conforme : où placer un fichier, comment nommer, quoi mettre dans chaque
    couche, avec du code réel.

    À ouvrir avant de créer un fichier. À citer en revue.

---

## 1. Les deux domaines

| | **Administration** | **Simulation** |
|---|---|---|
| Objet | *décrire* un modèle | *exploiter* un modèle |
| Produit | des **schémas** | des **données** et des **résultats** |
| Contextes | `catalog`, `model` | `project`, `dataset`, `scenario`, `run`, `result` |
| Espace front | `/admin` | `/simulation` |

**La règle d'or : Administration produit ce que Simulation consomme.**
Un dataset n'est valide que contre un `DataSpec`, un scénario que contre un
`ParameterSpec`. La flèche ne s'inverse jamais — `catalog` ignore l'existence de
`project`.

!!! note "Domaine `Simulation`, contexte `run`"
    Le domaine s'appelle **Simulation**. Le contexte qui porte le cycle de vie
    d'une exécution s'appelle **`run`**. Ne les confondez pas dans les
    conversations ni dans les noms de modules.

---

## 2. Arborescence

```
headless-maelia-server/
├── app/
│   ├── main.py                  # assemblage FastAPI : monte les routeurs
│   ├── shared/                  # socle technique — AUCUN métier
│   │   ├── config.py            # Settings unique
│   │   ├── database.py          # session SQLAlchemy
│   │   ├── errors.py            # exceptions de base + handler RFC 7807
│   │   ├── logging.py           # journalisation contextualisée
│   │   └── health.py            # sondes de disponibilité
│   ├── contexts/
│   │   ├── catalog/             # ─ Administration
│   │   ├── model/               # ─ Administration
│   │   ├── project/             # ─ Simulation
│   │   ├── dataset/             # ─ Simulation
│   │   ├── scenario/            # ─ Simulation
│   │   ├── run/                 # ─ Simulation
│   │   └── result/              # ─ Simulation
│   └── worker/
│       ├── settings.py          # WorkerSettings ARQ
│       └── tasks.py             # tâches → délèguent aux cas d'usage
└── tests/
    ├── unit/                    # domaine pur, sans Docker
    ├── integration/             # adaptateurs, Testcontainers
    └── e2e/                     # chaîne complète
```

Chaque contexte a la **même** structure interne :

```
contexts/<contexte>/
├── domain/
│   ├── models.py        # dataclasses pures
│   ├── services.py      # règles métier pures
│   ├── ports.py         # Protocol
│   └── errors.py        # exceptions métier
├── application/
│   └── use_cases.py     # orchestration
├── infrastructure/
│   ├── persistence.py   # SQLAlchemy + adaptateur
│   └── ...              # autres adaptateurs
└── api/
    ├── routes.py        # APIRouter
    └── schemas.py       # Pydantic
```

**Ne créez que les fichiers nécessaires.** Un contexte sans règle métier n'a pas
besoin de `services.py`. Un fichier vide ajouté « pour la symétrie » est du bruit.

---

## 3. La règle de dépendance

```
api ─┐
     ├──▶ application ──▶ domain ◀── infrastructure
worker ┘
```

C'est **la** règle. Tout le reste en découle.

| Couche | A le droit d'importer | N'importe **jamais** |
|---|---|---|
| `domain` | stdlib, autres modules du même `domain` | FastAPI, SQLAlchemy, Redis, websockets, `httpx`, un autre contexte |
| `application` | son `domain`, `shared`, cas d'usage d'un autre contexte | FastAPI, SQLAlchemy |
| `infrastructure` | son `domain`, `shared`, les bibliothèques externes | `api` |
| `api` | son `application`, ses `schemas`, `shared` | `infrastructure` d'un autre contexte |

### Où placer ce code ? Quatre questions

| Question | Couche |
|---|---|
| Est-ce vrai indépendamment de FastAPI, Postgres et GAMA ? | `domain` |
| Est-ce un enchaînement d'étapes coordonnant plusieurs objets ? | `application` |
| Est-ce que ça parle à un système extérieur ? | `infrastructure` |
| Est-ce lié à HTTP (statuts, multipart, pagination) ? | `api` |

**Exemple.** « Un CSV transposé se lit en inversant lignes et colonnes » → `domain`.
« Le fichier arrive en `multipart/form-data` » → `api`. « Il est stocké dans
MinIO » → `infrastructure`. « Importer un CSV = décoder, valider, enregistrer,
journaliser » → `application`.

---

## 4. Une tranche verticale complète

Exemple réel : *valider un jeu de données contre son schéma*. Les quatre couches,
dans l'ordre où on les écrit.

### 4.1 `domain/models.py` — dataclasses pures

```python
from dataclasses import dataclass, field
from datetime import datetime
from enum import StrEnum
from uuid import UUID


class DatasetStatus(StrEnum):
    DRAFT = "DRAFT"
    VALID = "VALID"
    INVALID = "INVALID"


@dataclass(frozen=True, slots=True)
class ValidationIssue:
    row: int | None
    field_name: str | None
    message: str


@dataclass(frozen=True, slots=True)
class Dataset:
    id: UUID
    project_id: UUID
    data_spec_id: UUID
    version: int
    status: DatasetStatus
    records: list[dict[str, str]] = field(default_factory=list)
    created_at: datetime | None = None

    def __post_init__(self) -> None:
        # Invariant: a version starts at 1. An invalid object must not exist.
        if self.version < 1:
            raise ValueError("a dataset version starts at 1")

    def with_status(self, status: DatasetStatus) -> "Dataset":
        """Immutable: produce a new object rather than mutate."""
        return replace(self, status=status)
```

**Règles.** `frozen=True` (un objet muté est un objet dont on ne sait plus d'où il
vient) · `slots=True` (mémoire, et interdit les attributs surprises) · invariants
dans `__post_init__` · **aucun import de framework** · aucune méthode qui fasse
une E/S.

### 4.2 `domain/services.py` — la règle métier, pure

```python
def validate(dataset: Dataset, spec: DataSpec) -> list[ValidationIssue]:
    """Check records against the schema. Pure function: same inputs, same
    outputs, no side effect — hence testable with nothing."""
    issues: list[ValidationIssue] = []

    for index, record in enumerate(dataset.records, start=1):
        for field_spec in spec.fields:
            raw = record.get(field_spec.name)

            if field_spec.required and not raw:
                issues.append(ValidationIssue(index, field_spec.name, "valeur obligatoire absente"))
                continue
            if raw and not field_spec.accepts(raw):
                issues.append(
                    ValidationIssue(index, field_spec.name, f"« {raw} » n'est pas un {field_spec.type}")
                )

    return issues
```

Notez que la validation **ne connaît aucun fichier MAELIA**. Elle lit un
`DataSpec` — c'est le principe « les schémas sont des données » (P5).

### 4.3 `domain/ports.py` — les frontières

```python
from typing import Protocol
from uuid import UUID


class DatasetRepository(Protocol):
    async def get(self, dataset_id: UUID) -> Dataset | None: ...
    async def save(self, dataset: Dataset) -> None: ...
    async def list_for_project(self, project_id: UUID) -> list[Dataset]: ...
```

**Quand créer un port ?** Quand il isole une dépendance *externe* (base, stockage,
moteur), ou quand il permet une *substitution réelle* (test sans infrastructure).
**Jamais par symétrie.**

**Comment le dimensionner ?** Le port exprime un besoin du domaine, pas les
capacités de la technologie. `SimulationEnginePort.run()` expose *une exécution
complète*, pas `load()`/`play()`/`stop()` — sinon le protocole GAMA fuit dans le
domaine et le port devient inimplémentable pour un autre moteur.

### 4.4 `application/use_cases.py` — l'orchestration

```python
async def validate_dataset(
    dataset_id: UUID,
    datasets: DatasetRepository,
    catalog: CatalogPort,
) -> ValidationReport:
    """Un cas d'usage = une transaction, une intention métier, un nom de verbe."""
    dataset = await datasets.get(dataset_id)
    if dataset is None:
        raise DatasetNotFound(dataset_id)

    spec = await catalog.get_data_spec(dataset.data_spec_id)

    issues = validate(dataset, spec)                     # ← la règle pure
    status = DatasetStatus.VALIDE if not issues else DatasetStatus.INVALIDE

    await datasets.save(dataset.with_status(status))
    log.info("dataset validé", extra={"dataset_id": str(dataset_id), "issues": len(issues)})

    return ValidationReport(dataset_id=dataset_id, status=status, issues=issues)
```

**Règles.** Les dépendances sont des **paramètres**, jamais des imports concrets ·
une transaction par cas d'usage, ouverte ici et nulle part ailleurs · aucun objet
HTTP en entrée ni en sortie · un nom de verbe à l'infinitif.

### 4.5 `infrastructure/persistence.py` — l'adaptateur

```python
class DatasetSqlRepository:
    """Satisfait DatasetRepository sans en hériter : Protocol = typage structurel."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get(self, dataset_id: UUID) -> Dataset | None:
        row = await self._session.get(DatasetRow, dataset_id)
        return _to_domain(row) if row else None

    async def save(self, dataset: Dataset) -> None:
        await self._session.merge(_to_row(dataset))


def _to_domain(row: DatasetRow) -> Dataset: ...
def _from_domain(dataset: Dataset) -> DatasetRow: ...
```

**Le mapping vit ici**, en deux fonctions privées explicites. Pas de couche de
mappers générés : deux fonctions se lisent et se déboguent.

L'entité SQLAlchemy (`DatasetRow`) **n'est pas** le modèle de domaine. Les
confondre, c'est laisser le schéma de base dicter le métier.

### 4.6 `api/routes.py` + `schemas.py` — le bord HTTP

```python
# schemas.py — contrat HTTP, distinct du domaine
class ValidationIssueOut(BaseModel):
    row: int | None
    field_name: str | None
    message: str

class ValidationReportOut(BaseModel):
    dataset_id: UUID
    status: DatasetStatus
    issues: list[ValidationIssueOut]


# routes.py
router = APIRouter(prefix="/api/v1", tags=["datasets"])

@router.post("/datasets/{dataset_id}/validate", response_model=ValidationReportOut)
async def validate_endpoint(
    dataset_id: UUID,
    datasets: DatasetRepository = Depends(get_dataset_repository),
    catalog: CatalogPort = Depends(get_catalog),
) -> ValidationReport:
    return await validate_dataset(dataset_id, datasets, catalog)
```

La route **ne contient aucune règle** : elle traduit HTTP → cas d'usage → HTTP.
Si vous y voyez un `if` métier, il est au mauvais endroit.

---

## 5. Conventions

### Nommage

| Élément | Convention | Exemple |
|---|---|---|
| Module | `snake_case`, singulier | `dataset/domain/models.py` |
| Modèle de domaine | `PascalCase`, nom métier | `Dataset`, `ValidationIssue` |
| Entité SQLAlchemy | suffixe `Row` | `DatasetRow` |
| Schéma Pydantic | suffixe `In` / `Out` | `DatasetCreateIn`, `DatasetOut` |
| Port | nom du rôle, sans `I` ni `Abstract` | `DatasetRepository` |
| Adaptateur | technologie + rôle | `DatasetSqlRepository`, `MinioFileStorage` |
| Cas d'usage | verbe à l'infinitif | `validate_dataset`, `launch_run` |
| Erreur métier | suffixe `Error` ou nom parlant | `DatasetNotFound` |
| Fonction privée | préfixe `_` | `_to_domain` |

**Tout le code est en anglais** : identifiants, commentaires et docstrings.
Deux exceptions, et seulement deux :

- les **messages destinés à l'utilisateur** (`detail` d'une erreur, libellés
  d'API) restent en français, puisque l'interface l'est ;
- les **identifiants GAML** gardent leur orthographe exacte —
  `nbAnneesSimulation`, jamais `nb_annees_simulation` : ce sont des clés du
  protocole, pas des noms que nous choisissons.

Les chemins d'API sont en anglais (`/dataspecs/applicable`) ; les routes du front
restent en français (`/admin/banc-essai`) car elles sont visibles par
l'utilisateur.

### Typage

Annotation obligatoire sur toute fonction publique. Syntaxe moderne :
`str | None`, `list[str]`, `dict[str, Any]`. `Any` doit se justifier — à la
frontière d'un protocole externe, c'est légitime ; ailleurs, c'est un aveu.

### Commentaires

Le code dit *ce qu'il fait* ; le commentaire dit *pourquoi*. Commentez ce qui
surprendrait un lecteur compétent : une contrainte externe, un contournement,
un ordre d'opérations non évident.

```python
# ✗ Inutile
# incrémente la version
version += 1

# ✓ Utile
# MAELIA réécrit ses includes pendant le run : sans copie par exécution, deux runs
# concurrents se corrompent silencieusement.
includes_path = materialize(run_id, territory)
```

### Async

- **Async** : tout ce qui touche au réseau, à la base, au broker.
- **Sync** : le domaine entier. Une règle métier n'a aucune raison d'être `async`.
- **E/S bloquante** (fichiers, `shutil`, client MinIO) : `await asyncio.to_thread(...)`.
  Copier 21 Mo d'includes dans la boucle d'événements fige tout le worker.
- **Jamais de boucle non bornée** dans un chemin de requête. Toute attente est
  bornée et annulable — un `listen()` bloquant a déjà empêché l'arrêt de l'API.

---

## 6. Erreurs

Trois familles, trois traitements.

```python
# shared/errors.py
class DomainError(Exception):
    """Règle métier violée → 4xx."""

class NotFoundError(DomainError):
    """Ressource absente → 404."""

class ConflictError(DomainError):
    """État incompatible → 409."""
```

| Famille | Origine | Traitement |
|---|---|---|
| **Métier** | `DomainError` levée par le domaine | handler global → RFC 7807 avec le bon statut |
| **Infrastructure** | moteur injoignable, timeout | remontée telle quelle ; le run passe en `ECHEC` avec le motif |
| **Programmation** | `KeyError`, `AttributeError` | jamais rattrapée localement → 500 + trace |

Réponses en `application/problem+json` (RFC 7807) via un gestionnaire unique dans
`shared/errors.py`.

!!! danger "`except Exception` nu"
    Interdit, **sauf** sur un traitement explicitement best-effort — nettoyage,
    sonde de santé, ingestion optionnelle. Dans ce cas : commentaire justifiant, et
    journalisation systématique.

    ```python
    try:
        await session.stop(exp_id)
    except Exception as exc:  # arrêt best-effort : ne doit jamais masquer l'erreur d'origine
        log.warning("stop(%s) a échoué : %s", exp_id, exc)
    ```

---

## 7. Journalisation

Toute ligne relative à une exécution porte son identité métier. Sans cela, les
journaux de trois runs concurrents sont illisibles.

```python
log.info("run démarré", extra={"run_id": run_id, "project_id": project_id})
```

Message en minuscules, sans point final, factuel. Pas de donnée sensible, pas de
volume : une ligne par étape, pas une par enregistrement.

---

## 8. Règles spécifiques au moteur de simulation

Elles viennent de pannes réelles. Les enfreindre coûtera le temps qu'il a fallu
pour les découvrir.

| # | Règle |
|---|---|
| **M1** | Une session moteur appartient au **worker**, jamais à une requête HTTP. La requête valide, crée, met en file, répond. |
| **M2** | Tout run travaille sur une **copie** de ses entrées. Le socle reste en lecture seule. |
| **M3** | Les chemins de sortie sont **déterministes**, dérivés de l'identifiant du run. Le chemin annoncé par le moteur n'est qu'un repli. |
| **M4** | La concurrence est **bornée explicitement** (`WORKER_MAX_JOBS`), dimensionnée sur la mémoire du moteur, pas sur les cœurs. |
| **M5** | Les sondes vérifient des **invariants** (« le modèle est lisible et inscriptible au chemin partagé »), pas des présences. |

---

## 9. Tests

| Niveau | Cible | Infrastructure | Attente |
|---|---|---|---|
| Unitaire | `domain/` | aucune | rapide, majoritaire |
| Cas d'usage | `application/` | ports simulés | logique d'orchestration |
| Adaptateur | `infrastructure/` | Testcontainers | mapping et requêtes réelles |
| Bout en bout | chaîne complète | `docker compose` | un run MAELIA court |

Un port se simule sans bibliothèque de mocks :

```python
class InMemoryDatasetRepository:
    def __init__(self) -> None:
        self._items: dict[UUID, Dataset] = {}

    async def get(self, dataset_id): return self._items.get(dataset_id)
    async def save(self, dataset): self._items[dataset.id] = dataset
```

Deux exigences non négociables :

1. **Le domaine se teste sans Docker.** Si un test de règle métier réclame une
   base, la règle est au mauvais endroit.
2. **Un test de bout en bout exécute une vraie simulation.** C'est le seul qui
   prouve que la plateforme fonctionne.

---

## 10. Anti-patterns

!!! danger "À ne pas faire"
    - **Un port par entité.** Un port isole une dépendance externe ou permet une
      substitution réelle. Pas plus.
    - **Trois classes pour cinq champs.** Sans règle métier, un schéma Pydantic et
      un dépôt suffisent ; le domaine viendra avec la première règle.
    - **Une entité SQLAlchemy servant de modèle de domaine.** Le schéma de base
      finit par dicter le métier.
    - **Une règle métier dans une route.** Elle devient introuvable et intestable.
    - **Une valeur MAELIA codée en dur.** Nom de fichier, de paramètre, de
      colonne : tout vient du catalogue.
    - **Un `shared/` fourre-tout.** Socle technique uniquement, jamais de métier.
    - **Un import de `infrastructure` depuis `domain`.** L'inversion de la règle de
      dépendance annule tout le bénéfice du découpage.
    - **Une abstraction « au cas où ».** On n'abstrait pas un second moteur avant
      d'en avoir un second.

**Règle d'arbitrage : une abstraction doit rendre un service aujourd'hui.**
Isoler une dépendance instable, permettre un test sans infrastructure, empêcher un
cycle — ce sont des services. « C'est plus propre » n'en est pas un.

---

## 11. Definition of Done

- [ ] La modification tient dans **un seul contexte**.
- [ ] `domain/` n'importe **ni** FastAPI, **ni** SQLAlchemy, **ni** Redis, **ni** websockets.
- [ ] Aucune règle métier n'est dans `api/` ou `infrastructure/`.
- [ ] Aucune valeur MAELIA n'est codée en dur.
- [ ] Les dépendances des cas d'usage sont des **paramètres**, pas des imports concrets.
- [ ] Toute E/S bloquante passe par `asyncio.to_thread`.
- [ ] Toute boucle d'attente est **bornée et annulable**.
- [ ] Tout effet de bord externe est **isolé par exécution**.
- [ ] Les journaux portent `run_id` / `project_id` quand ils existent.
- [ ] Les fonctions publiques sont annotées.
- [ ] Les règles métier ajoutées sont **testées sans Docker**.
- [ ] Toute abstraction nouvelle rend un service **aujourd'hui**.
