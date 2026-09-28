# Backstage Packages

This directory contains the deployable BharathCoudOps frontend and backend workspaces.

## Application Package

`app` uses Backstage's new frontend system. It owns the guest sign-in page, sidebar, home widgets, catalog routes, and the Cloud Estate, Environments, Sandboxes, Approvals, and Operations views.

```bash
yarn workspace app start
yarn workspace app test --watch=false
yarn workspace app build
```

## Backend Package

`backend` registers the application, proxy, authentication, catalog, scaffolder, TechDocs, permissions, search, notifications, signals, user settings, Kubernetes, and MCP Actions plugins. Its Dockerfile builds the complete production image from the repository root.

```bash
yarn workspace backend start
yarn workspace backend build
yarn workspace backend build-image
```

## Validation

Run package checks through the repository-level commands so shared TypeScript, lint, and Backstage configuration are included:

```bash
yarn prettier:check
yarn tsc
yarn lint:all
yarn test
yarn build:backend
```
