# BharathCoudOps Developer Portal

Backstage developer portal for the BharathCoudOps platform catalog, software templates, GitHub Actions visibility, Cloudflare Access protection, guest identity, and OCI-hosted production operations.

## Supported Versions

| Component              | Version                                    |
| ---------------------- | ------------------------------------------ |
| Backstage release      | `1.54.6`                                   |
| Node.js                | `22` or `24`; Node 24 in CI and containers |
| Yarn                   | `4.13.0`                                   |
| React                  | `18.3.1`                                   |
| PostgreSQL             | `17.11-bookworm`                           |
| PostgreSQL exporter    | `0.20.1`                                   |
| Node exporter          | `1.12.1`                                   |

Backstage package versions are managed as a release set. Use `yarn backstage-cli versions:bump --release <version>` for future Backstage upgrades; do not upgrade React, React Router, TypeScript, or native database packages independently of Backstage compatibility.

## Local Development

Install Node 24 and provide a GitHub token used by the configured integration:

```bash
export GITHUB_TOKEN='<token>'
node .yarn/releases/yarn-4.13.0.cjs install --immutable
node .yarn/releases/yarn-4.13.0.cjs start
```

The frontend is available at `http://localhost:3000` and the backend at `http://localhost:7007`. Local development uses guest authentication and an in-memory SQLite database.

## Production Configuration

The production container loads [app-config.yaml](app-config.yaml) followed by [app-config.production.yaml](app-config.production.yaml). The production file overrides public URLs, PostgreSQL, and Cloudflare-protected guest authentication. Cloudflare Access must authenticate every request before it reaches Backstage because the production guest provider does not perform identity verification itself.

| Variable                 | Default                           | Description                                               |
| ------------------------ | --------------------------------- | --------------------------------------------------------- |
| `BACKSTAGE_BASE_URL`     | Required                          | Public HTTPS URL used by the frontend, backend, and CORS  |
| `BACKSTAGE_BIND_ADDRESS` | Required                          | Private host address used for published Compose ports     |
| `BACKSTAGE_VERSION`      | Required                          | Immutable application image tag, normally the release tag |
| `POSTGRES_HOST`          | `postgres`                        | Compose PostgreSQL service name                           |
| `POSTGRES_PORT`          | `5432`                            | PostgreSQL service port                                   |
| `POSTGRES_USER`          | `backstage`                       | PostgreSQL role                                           |
| `BACKSTAGE_INSTALL_ROOT` | `/opt/backstage-platform`         | Versioned release installation root                       |
| `BACKSTAGE_BACKUP_ROOT`  | `/var/backups/backstage-platform` | Database backup and metrics root                          |

## Secret Bundle

Deployment reads one JSON object from OCI Vault and writes each value to a root-owned release secret file. Values must be non-empty single-line strings. No secret files are committed.

| JSON key            | Container variable         | Purpose                                                                        |
| ------------------- | -------------------------- | ------------------------------------------------------------------------------ |
| `backend_secret`    | `BACKSTAGE_BACKEND_SECRET` | Backstage service-to-service signing secret; use at least 32 random characters |
| `github_token`      | `GITHUB_TOKEN`             | GitHub catalog and scaffolder integration token                                |
| `postgres_password` | `POSTGRES_PASSWORD`        | PostgreSQL password; use at least 16 random characters                         |

## ✅ Validation

Run the same checks used by GitHub Actions from the repository root:

```bash
bash scripts/validate.sh
node .yarn/releases/yarn-4.13.0.cjs install --immutable
node .yarn/releases/yarn-4.13.0.cjs prettier:check
node .yarn/releases/yarn-4.13.0.cjs tsc
node .yarn/releases/yarn-4.13.0.cjs workspace app test --watch=false
node .yarn/releases/yarn-4.13.0.cjs build:backend
```

GitHub Actions runs [scripts/validate-ci.sh](scripts/validate-ci.sh) in the pinned
Node 24 image. Public pull requests remain on the free GitHub-hosted runner and
cannot access the private OCI host.

## Production Stack

[compose.yaml](compose.yaml) defines four services with pinned images and resource limits.

| Service                 | Published port | Persistent data                    |
| ----------------------- | -------------- | ---------------------------------- |
| Backstage               | `7007`         | PostgreSQL                         |
| PostgreSQL              | Internal only  | `postgres-data` volume             |
| PostgreSQL exporter     | `9187`         | None                               |
| Backup metrics exporter | `9101`         | Read-only backup metrics directory |

All published ports bind to `BACKSTAGE_BIND_ADDRESS`. Public access must pass through the managed Cloudflare route; the containers do not publish directly on every host interface.

## Lifecycle Actions

[scripts/bootstrap.sh](scripts/bootstrap.sh) downloads an immutable semantic release tag and dispatches to [scripts/manage.sh](scripts/manage.sh).

| Action     | Behaviour                                                                                                                |
| ---------- | ------------------------------------------------------------------------------------------------------------------------ |
| `validate` | Validates repository files, image pins, secret schema, OCI payload size, and Compose when Docker is available            |
| `dry-run`  | Runs validation without changing the host                                                                                |
| `deploy`   | Installs pinned Docker packages, creates a versioned release, builds the image, starts the stack, and verifies readiness |
| `verify`   | Checks container state and Backstage readiness                                                                           |
| `status`   | Prints Compose status and verifies readiness                                                                             |
| `backup`   | Creates a compressed PostgreSQL dump and updates Prometheus textfile metrics                                             |
| `restore`  | Restores a managed backup path and verifies readiness                                                                    |
| `rollback` | Swaps the current and previous release links and verifies readiness                                                      |

Backups are retained for seven days and match `/var/backups/backstage-platform/backstage-YYYYMMDDTHHMMSSZ.sql.gz`.

## 🚀 Production Deployment

Production deployment targets the existing `k3s` host to avoid additional OCI compute and block-storage costs. Backstage runs as a resource-limited Compose stack on that host, and the Cloudflare connector remains on `web-01`.

After the Vault data and a published release tag are ready, use this order:

1. Require `01 - Validate Backstage Platform` to pass.
2. Update `bharath-oci-host-config/environments/prd/backstage.json` to the published `automation_ref` through repository review.
3. Require `01 - Validate OCI Host Configuration` to pass.
4. Run `08 - Configure Production Backstage` with `action=deploy`.

The deployment pipeline performs remote `validate` and `dry-run` stages before `deploy`, then verifies the protected public route.

## Repository Layout

| Path               | Responsibility                                                                     |
| ------------------ | ---------------------------------------------------------------------------------- |
| `packages/app`     | New frontend system, navigation, authentication, and platform pages                |
| `packages/backend` | Backstage backend plugins and production image                                     |
| `catalog`          | BharathCoudOps domains, systems, components, groups, and resources                 |
| `templates`        | Repository-reviewed sandbox request workflows                                      |
| `scripts`          | Validation, Docker installation, release deployment, backup, restore, and rollback |
