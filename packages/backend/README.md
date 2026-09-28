# BharathCoudOps Backstage Backend

Production Backstage backend for the BharathCoudOps developer portal. Plugin registration is centralised in `src/index.ts`; runtime settings come from the root `app-config.yaml` and `app-config.production.yaml` files.

## Development

From the repository root:

```bash
yarn install --immutable
yarn workspace backend start
```

The backend listens on `http://localhost:7007`, uses guest authentication, and stores local development data in an in-memory SQLite database. Put uncommitted overrides in `app-config.local.yaml`.

## Registered Plugins

| Category    | Plugins                                                                         |
| ----------- | ------------------------------------------------------------------------------- |
| Application | App backend and proxy                                                           |
| Identity    | Auth backend and guest provider                                                   |
| Catalog     | Core catalog, GitHub, scaffolder entity model, processing logs                    |
| Delivery    | Scaffolder, GitHub publish actions, notifications                               |
| Content     | TechDocs                                                                        |
| Discovery   | PostgreSQL search engine, catalog and TechDocs collators                        |
| Operations  | Kubernetes                                                                      |
| Platform    | Permissions, user settings, notifications, signals, MCP Actions                 |

## Production Image

Build from the repository root so all workspace packages, configurations, catalog entities, and templates are available:

```bash
yarn workspace backend build
yarn workspace backend build-image
```

The image runs as the unprivileged `node` user, loads secrets from Docker secret files through `scripts/entrypoint.sh`, uses a read-only root filesystem, and exposes readiness at `/.backstage/health/v1/readiness`.

## Validation

```bash
yarn tsc
yarn workspace backend lint
yarn workspace backend test --watch=false
yarn workspace backend build
```

## Documentation

- [Backstage Documentation](https://backstage.io/docs)
- [Backend System](https://backstage.io/docs/backend-system/)
- [Configuration](https://backstage.io/docs/conf/)
