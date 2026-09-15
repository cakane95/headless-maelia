<!-- Fragment inclus par plusieurs pages. Ne pas le lire seul, ne pas l'ajouter au nav.
     Vérifié le 2026-09-15 contre docker-compose.yml -->

--8<-- [start:urls]
| Service | URL | Rôle |
|---|---|---|
| `frontend` | <http://localhost:5173> | L'interface — c'est par là qu'on entre |
| `api` | <http://localhost:8000> | REST et WebSocket temps réel |
| `api` (Swagger) | <http://localhost:8000/docs> | Référence d'API interactive |
| `docs` | <http://localhost:8082> | Cette documentation |
| `minio` | <http://localhost:9001> | Console de stockage objet (`maelia` / `maelia12345`) |
| `gama-headless` | `ws://localhost:6868` | Serveur GAMA, piloté en WebSocket |
| `db` | `localhost:5432` | PostgreSQL 16 + PostGIS |
| `redis` | `localhost:6379` | File de tâches ARQ et pub/sub |
--8<-- [end:urls]

--8<-- [start:sondes]
La sonde de dépendances doit répondre `"status": "ok"` avec cinq contrôles `up` :
`postgres` (migrations comprises), `redis`, `minio`, `gama-headless` et
`shared-volume`.

```bash
curl http://localhost:8000/api/v1/health/dependencies
```
--8<-- [end:sondes]
