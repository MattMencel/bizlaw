const path = require('path');

const { composePlugins, withNx } = require('@nx/next');
const CircularDependencyPlugin = require('circular-dependency-plugin');

/**
 * @type {import('@nx/next/plugins/with-nx').WithNxOptions}
 **/
const nextConfig = {
  nx: {
    // Set this to true if you would like to use SVGR
    svgr: false,
  },

  webpack: (config, { _isServer }) => {
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
        // exclude detection of files based on a RegExp
        exclude: /node_modules/,
        // add errors to webpack instead of warnings
        failOnError: false,
        // allow import cycles that include an async import,
        // e.g. via import(/* webpackMode: "weak" */ './file.js')
        allowAsyncCycles: false,
        // set the current working directory for displaying module paths
        cwd: process.cwd(),
      }),
    );

    return config;
  },

  // Improve Docker behavior
  outputFileTracingRoot: path.join(__dirname, '../../'),

  serverRuntimeConfig: {
    dbHost: process.env.DB_HOST,
    dbPort: process.env.DB_PORT,
    dbUser: process.env.DB_USER,
    dbPassword: process.env.DB_PASSWORD,
    dbName: process.env.DB_NAME,
  },

  serverExternalPackages: ['postgres'],

};

const plugins = [
  // Add more Next.js plugins to this list if needed.
  withNx,
];

module.exports = composePlugins(...plugins)(nextConfig);
