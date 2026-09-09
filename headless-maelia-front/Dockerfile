# Pas de directive `# syntax=` volontairement : elle imposerait le téléchargement
# de docker/dockerfile:* depuis Docker Hub à chaque build (panne au 1er lancement
# si le registre est indisponible ou rate-limité). Le frontend intégré de
# Docker >= 23 supporte RUN --mount=type=cache et COPY --from=<image>.
#
# headless-maelia-front/Dockerfile — SPA React / Vite
#
# Cibles :
#   dev  (défaut) → serveur Vite avec HMR sur 5173, sources montées en volume
#   prod          → build statique servi par nginx (proxy /api et /ws vers l'api)
# Build prod :  docker build --target prod -t maelia/frontend:prod .

# ─────────────────────────────── base ────────────────────────────────
FROM node:22-alpine AS base

ENV CI=true \
    PNPM_HOME=/pnpm \
    PATH=/pnpm:$PATH

RUN npm install -g pnpm@12.3.4

WORKDIR /app

# ─────────────────────────── dépendances ─────────────────────────────
FROM base AS deps

COPY package.json pnpm-lock.yaml* ./

# Le lockfile n'existe pas encore dans le dépôt : on l'utilise s'il est là
# (build reproductible), sinon on résout. Une fois `pnpm install` lancé en local,
# committez pnpm-lock.yaml pour passer définitivement sur --frozen-lockfile.
RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    if [ -f pnpm-lock.yaml ]; then \
        pnpm install --frozen-lockfile --fetch-retries=5; \
    else \
        echo "!! pnpm-lock.yaml absent — résolution non figée" && pnpm install; \
    fi

# ──────────────────────────── dev (défaut) ───────────────────────────
FROM deps AS dev

COPY . .

EXPOSE 5173

# --host 0.0.0.0 : sans ça Vite n'écoute que sur localhost DANS le conteneur
# et le port publié par docker ne répond pas.
CMD ["pnpm", "run", "dev", "--host", "0.0.0.0", "--port", "5173"]

# ─────────────────────────────── build ───────────────────────────────
FROM deps AS build

COPY . .
RUN pnpm run build

# ─────────────────────────────── prod ────────────────────────────────
FROM nginx:1.31-alpine AS prod

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost/ >/dev/null || exit 1

CMD ["nginx", "-g", "daemon off;"]
