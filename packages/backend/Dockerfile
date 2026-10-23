#==============================================================================
# BACKSTAGE MULTI-STAGE PRODUCTION IMAGE
#==============================================================================

#==============================================================================
# PACKAGE MANIFEST STAGE
#==============================================================================

FROM node:25-trixie-slim AS packages

USER node
WORKDIR /app

COPY --chown=node:node backstage.json package.json yarn.lock ./
COPY --chown=node:node .yarn ./.yarn
COPY --chown=node:node .yarnrc.yml ./
COPY --chown=node:node packages ./packages

RUN find packages \! -name package.json -mindepth 2 -maxdepth 2 -exec rm -rf {} \+

#==============================================================================
# APPLICATION BUILD STAGE
#==============================================================================

FROM node:25-trixie-slim AS build

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends build-essential libsqlite3-dev python3 && \
    rm -rf /var/lib/apt/lists/*

USER node
WORKDIR /app

COPY --from=packages --chown=node:node /app ./
RUN --mount=type=cache,target=/home/node/.cache/yarn,sharing=locked,uid=1000,gid=1000 \
    node .yarn/releases/yarn-4.13.0.cjs install --immutable

COPY --chown=node:node . .
RUN node .yarn/releases/yarn-4.13.0.cjs tsc
RUN node .yarn/releases/yarn-4.13.0.cjs build:backend
RUN mkdir packages/backend/dist/skeleton packages/backend/dist/bundle && \
    tar xzf packages/backend/dist/skeleton.tar.gz -C packages/backend/dist/skeleton && \
    tar xzf packages/backend/dist/bundle.tar.gz -C packages/backend/dist/bundle

#==============================================================================
# PRODUCTION RUNTIME STAGE
#==============================================================================

FROM node:25-trixie-slim

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends libsqlite3-dev && \
    rm -rf /var/lib/apt/lists/*

USER node
WORKDIR /app

ENV NODE_ENV=production

COPY --from=build --chown=node:node /app/.yarn ./.yarn
COPY --from=build --chown=node:node /app/.yarnrc.yml ./
COPY --from=build --chown=node:node /app/backstage.json ./
COPY --from=build --chown=node:node /app/yarn.lock /app/package.json ./
COPY --from=build --chown=node:node /app/packages/backend/dist/skeleton/ ./

RUN --mount=type=cache,target=/home/node/.cache/yarn,sharing=locked,uid=1000,gid=1000 \
    node .yarn/releases/yarn-4.13.0.cjs workspaces focus --all --production && \
    node .yarn/releases/yarn-4.13.0.cjs cache clean

COPY --from=build --chown=node:node /app/packages/backend/dist/bundle/ ./
COPY --chown=node:node app-config*.yaml ./
COPY --chown=node:node catalog ./catalog
COPY --chown=node:node templates ./templates
COPY --chown=node:node --chmod=0555 scripts/entrypoint.sh ./scripts/entrypoint.sh

ENTRYPOINT ["./scripts/entrypoint.sh"]
CMD ["node", "packages/backend", "--config", "app-config.yaml", "--config", "app-config.production.yaml"]
