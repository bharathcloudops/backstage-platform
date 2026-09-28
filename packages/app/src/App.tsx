//==============================================================================
// BACKSTAGE APPLICATION MODULE
//==============================================================================

import { createApp } from '@backstage/frontend-defaults';
import catalogPlugin from '@backstage/plugin-catalog/alpha';
import { authModule } from './modules/auth';
import { navModule } from './modules/nav';
import { homeModule } from './modules/home';
import { platformPlugin } from './modules/platform';

//==============================================================================
// APPLICATION FEATURE REGISTRATION
//==============================================================================

export default createApp({
  features: [
    catalogPlugin,
    authModule,
    navModule,
    homeModule,
    platformPlugin,
  ],
});
