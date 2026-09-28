//==============================================================================
// HOME PAGE MODULE
//==============================================================================

import { createFrontendModule } from '@backstage/frontend-plugin-api';
import { HomePageWidgetBlueprint } from '@backstage/plugin-home-react/alpha';
import { MarkdownContent } from '@backstage/core-components';

//==============================================================================
// PLATFORM OVERVIEW CONTENT
//==============================================================================

const content = `
## Platform status

- [Cloud estate](/cloud)
- [Environment inventory](/environments)
- [Expiring sandboxes](/sandboxes)
- [Pending approvals](/approvals)
- [GitHub Actions](https://github.com/orgs/bharathcloudops/actions)
- [Software catalog](/catalog)
- [Create](/create)
`;

//==============================================================================
// PLATFORM OVERVIEW WIDGET
//==============================================================================

const platformOverviewWidget = HomePageWidgetBlueprint.make({
  name: 'platform-overview',
  params: {
    name: 'PlatformOverview',
    title: 'Platform Overview',
    description: 'Cloud and delivery operations',
    components: async () => ({
      Content: () => <MarkdownContent content={content} />,
    }),
  },
});

//==============================================================================
// HOME FEATURE REGISTRATION
//==============================================================================

export const homeModule = createFrontendModule({
  pluginId: 'home',
  extensions: [platformOverviewWidget],
});
