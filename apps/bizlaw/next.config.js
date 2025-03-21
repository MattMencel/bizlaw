const path = require('path');

const { composePlugins, withNx } = require('@nx/next');
const CircularDependencyPlugin = require('circular-dependency-plugin');

/**
 * @type {import('@nx/next/plugins/with-nx').WithNxOptions}
 **/
const nextConfig = {
  nx: {
    svgr: false,
  },

  webpack: (config, { isServer }) => {
    // Disable strictExportPresence to prevent 'Cannot access r before initialization'
    config.module.parser = {
      ...config.module.parser,
      javascript: {
        ...config.module.parser?.javascript,
        strictExportPresence: false,
      },
    };

    // Add resolve.alias configuration for '@/'
    config.resolve.alias = {
      ...config.resolve.alias,
      '@': path.join(__dirname, 'src'),
    };

    // Add a circular dependency plugin to warn about circular dependencies
    config.plugins.push(
      new CircularDependencyPlugin({
        exclude: /node_modules/,
        failOnError: false,
        allowAsyncCycles: false,
        cwd: process.cwd(),
      }),
    );

    return config;
  },

  outputFileTracingRoot: path.join(__dirname, '../../'),
  outputFileTracingIncludes: {
    '**': ['drizzle/**/*']
  },


  serverComponentsExternalPackages: ['postgres', 'zod', 'drizzle-orm'],
  serverRuntimeConfig: {
    dbHost: process.env.DB_HOST,
    dbPort: process.env.DB_PORT,
    dbUser: process.env.DB_USER,
    dbPassword: process.env.DB_PASSWORD,
    dbName: process.env.DB_NAME,
  },
};

const plugins = [
  withNx,
];

module.exports = composePlugins(...plugins)(nextConfig);
