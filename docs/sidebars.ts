import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

/**
 * Creating a sidebar enables you to:
 - create an ordered group of docs
 - render a sidebar for each doc of that group
 - provide next/previous navigation

 The sidebars can be generated from the filesystem, or explicitly defined here.

 Create as many sidebars as you want.
 */
const sidebars: SidebarsConfig = {
  // Getting Started Sidebar
  gettingStartedSidebar: [
    {
      type: 'category',
      label: 'Getting Started',
      items: [
        'getting-started/overview',
        'getting-started/account-setup',
        'getting-started/navigation',
        'getting-started/glossary',
        'getting-started/system-requirements',
      ],
    },
  ],

  // Students Sidebar
  studentsSidebar: [
    {
      type: 'category',
      label: 'For Students',
      items: [
        'students/quick-start',
        'students/joining-course',
        'students/team-collaboration',
        'students/case-overview',
        'students/evidence-vault',
        'students/negotiation-process',
        'students/client-consultation',
        'students/scoring-system',
        'students/troubleshooting',
      ],
    },
  ],

  // Instructors Sidebar
  instructorsSidebar: [
    {
      type: 'category',
      label: 'For Instructors',
      items: [
        'instructors/course-creation',
        'instructors/student-management',
        'instructors/case-configuration',
        'instructors/simulation-monitoring',
        'instructors/grading-tools',
        'instructors/report-generation',
        'instructors/ai-configuration',
        'instructors/best-practices',
      ],
    },
  ],

  // Administrators Sidebar
  adminsSidebar: [
    {
      type: 'category',
      label: 'For Administrators',
      items: [
        'admins/organization-setup',
        'admins/user-management',
        'admins/license-management',
        'admins/system-monitoring',
        'admins/security-settings',
        'admins/backup-recovery',
      ],
    },
  ],

  // API Sidebar
  apiSidebar: [
    {
      type: 'category',
      label: 'API Documentation',
      items: [
        'api/authentication',
        'api/rest-endpoints',
        'api/rate-limiting',
        'api/integration-examples',
        'api/webhooks',
      ],
    },
  ],
};

export default sidebars;
