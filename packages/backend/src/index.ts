//==============================================================================
// BACKSTAGE BACKEND INITIALIZATION
//==============================================================================

import { createBackend } from '@backstage/backend-defaults';

//==============================================================================
// BACKEND APPLICATION
//==============================================================================

const backend = createBackend();

//==============================================================================
// APPLICATION AND PROXY PLUGINS
//==============================================================================

backend.add(import('@backstage/plugin-app-backend'));
backend.add(import('@backstage/plugin-proxy-backend'));

//==============================================================================
// SOFTWARE SCAFFOLDER PLUGINS
//==============================================================================

backend.add(import('@backstage/plugin-scaffolder-backend'));
backend.add(import('@backstage/plugin-scaffolder-backend-module-github'));
backend.add(
  import('@backstage/plugin-scaffolder-backend-module-notifications'),
);

//==============================================================================
// TECHDOCS PLUGIN
//==============================================================================

backend.add(import('@backstage/plugin-techdocs-backend'));

//==============================================================================
// AUTHENTICATION PLUGINS
//==============================================================================

backend.add(import('@backstage/plugin-auth-backend'));
backend.add(import('@backstage/plugin-auth-backend-module-guest-provider'));

//==============================================================================
// SOFTWARE CATALOG PLUGINS
//==============================================================================

backend.add(import('@backstage/plugin-catalog-backend'));
backend.add(
  import('@backstage/plugin-catalog-backend-module-scaffolder-entity-model'),
);
backend.add(import('@backstage/plugin-catalog-backend-module-github'));

backend.add(import('@backstage/plugin-catalog-backend-module-logs'));

//==============================================================================
// PERMISSION PLUGINS
//==============================================================================

backend.add(import('@backstage/plugin-permission-backend'));
backend.add(
  import('@backstage/plugin-permission-backend-module-allow-all-policy'),
);

//==============================================================================
// SEARCH PLUGINS
//==============================================================================

backend.add(import('@backstage/plugin-search-backend'));
backend.add(import('@backstage/plugin-search-backend-module-pg'));
backend.add(import('@backstage/plugin-search-backend-module-catalog'));
backend.add(import('@backstage/plugin-search-backend-module-techdocs'));

//==============================================================================
// USER SETTINGS PLUGIN
//==============================================================================

backend.add(import('@backstage/plugin-user-settings-backend'));

//==============================================================================
// NOTIFICATION AND SIGNAL PLUGINS
//==============================================================================

backend.add(import('@backstage/plugin-notifications-backend'));
backend.add(import('@backstage/plugin-signals-backend'));

//==============================================================================
// MCP ACTIONS PLUGIN
//==============================================================================

backend.add(import('@backstage/plugin-mcp-actions-backend'));

//==============================================================================
// BACKEND STARTUP
//==============================================================================

backend.start();
