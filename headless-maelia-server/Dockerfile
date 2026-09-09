# Pas de directive `# syntax=` volontairement : elle imposerait le téléchargement
# de docker/dockerfile:* depuis Docker Hub à chaque build (panne au 1er lancement
# si le registre est indisponible ou rate-limité). Le frontend intégré de
# Docker >= 23 supporte RUN --mount=type=cache et COPY --from=<image>.
#
# headless-maelia-server/Dockerfile — backend Python (FastAPI + ARQ)
#
# Une seule image pour les deux rôles du compose :
#   api    → uvicorn app.main:app        (REST + WebSocket temps réel)
#   worker → arq app.worker.settings...  (consomme la file, pilote GAMA)
# Le rôle est choisi par la `command:` du service, pas par l'image.
#
# Cibles :
#   dev  (défaut) → root, deps de dev, code monté en volume, --reload
#   prod          → utilisateur non-root, code copié, healthcheck
# Build prod :  docker build --target prod -t maelia/backend:prod .

# ─────────────────────────────── base ────────────────────────────────
FROM python:3.12-slim AS base

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1

# libpq5 : requis par psycopg (migrations Alembic). curl : healthcheck.
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        libpq5 \
    && rm -rf /var/lib/apt/lists/*

# uv : installateur/résolveur Python (remplace poetry du prototype, ~10x plus rapide)
COPY --from=ghcr.io/astral-sh/uv:0.12.10 /uv /usr/local/bin/uv

WORKDIR /app

# ─────────────────────────── dépendances ─────────────────────────────
FROM base AS deps

COPY pyproject.toml uv.lock* ./

# `--system` installe dans /usr/local/lib/python3.12/site-packages, PAS dans /app.
# C'est indispensable : le compose monte ./headless-maelia-server sur /app, ce qui
# masquerait un .venv qui s'y trouverait.
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system -r pyproject.toml

# ──────────────────────────── dev (défaut) ───────────────────────────
FROM deps AS dev

RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system -r pyproject.toml --extra dev

COPY . .

EXPOSE 8000

# `--ws wsproto` est OBLIGATOIRE : websockets 10.4 est présent dans l'image (tiré
# par gama-client), et l'auto-détection d'uvicorn le choisirait alors que uvicorn
# 0.52 attend l'API de websockets>=13. Voir le commentaire dans pyproject.toml.
CMD ["uvicorn", "app.main:app", \
     "--host", "0.0.0.0", "--port", "8000", \
     "--ws", "wsproto", "--reload"]

# ─────────────────────────────── prod ────────────────────────────────
FROM deps AS prod

# uid 1000 : correspond à l'utilisateur hôte usuel sous Linux, pour que le worker
# puisse écrire dans le bind-mount ./gama-models (matérialisation des includes).
RUN useradd --create-home --uid 1000 maelia

COPY --chown=maelia:maelia . .

USER maelia

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl -fsS http://localhost:8000/health || exit 1

CMD ["uvicorn", "app.main:app", \
     "--host", "0.0.0.0", "--port", "8000", \
     "--ws", "wsproto"]
