const withTM = require('next-transpile-modules')(['sequelize-typescript']);
const CopyWebpackPlugin = require('copy-webpack-plugin');
const path = require('path');

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  webpack: (config, { isServer }) => {
    // Add support for HBS templates
    config.module.rules.push({
      test: /\.hbs$/,
      use: 'handlebars-loader',
    });

    // Ensure plugins array exists
    if (!config.plugins) config.plugins = [];

    // Copy static assets
    config.plugins.push(
      new CopyWebpackPlugin({
        patterns: [
          {
            from: path.resolve(__dirname, 'public'),
            to: 'public',
            noErrorOnMissing: true,
          },
          {
            from: path.resolve(__dirname, 'views'),
            to: 'views',
            noErrorOnMissing: true,
          },
        ],
      }),
    );

    // Add alias for src directory
    if (!config.resolve) config.resolve = {};
    if (!config.resolve.alias) config.resolve.alias = {};
    config.resolve.alias['@'] = path.resolve(__dirname, 'src');

    // Ensure React is properly resolved
    config.resolve.alias['react'] = path.resolve(
      __dirname,
      '../../node_modules/react',
    );
    config.resolve.alias['react-dom'] = path.resolve(
      __dirname,
      '../../node_modules/react-dom',
    );

    return config;
  },
  async rewrites() {
    const rewrites = [];

    if (process.env.NEXT_PUBLIC_API_URL) {
      rewrites.push({
        source: '/api/:path*',
        destination: `${process.env.NEXT_PUBLIC_API_URL}/:path*`,
      });
    }

    return rewrites;
  },
};

module.exports = withTM(nextConfig);
