const { withNx } = require('@nx/webpack');
const path = require('path');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const withTM = require('next-transpile-modules')(['sequelize-typescript']);

module.exports = withTM(withNx({
  reactStrictMode: true,
  webpack: (config, { isServer }) => {
    // Configure output
    config.output = {
      ...config.output,
      path: path.resolve(__dirname, '../../dist/apps/web'),
      filename: 'bundle.js',
    };

    // Ensure module rules exist before pushing
    if (!config.module) config.module = {};
    if (!config.module.rules) config.module.rules = [];

    // Add support for HBS templates
    config.module.rules.push({
      test: /\.hbs$/,
      use: 'handlebars-loader',
    });

    // Add support for TS files
    config.module.rules.push({
      test: /\.ts$/,
      use: [
        {
          loader: 'ts-loader',
          options: { transpileOnly: true },
        },
      ],
      exclude: /node_modules/,
    });

    // Ensure plugins array exists
    if (!config.plugins) config.plugins = [];

    // Copy static assets
    config.plugins.push(new CopyWebpackPlugin({
      patterns: [
        {
          from: path.resolve(__dirname, 'src/public'),
          to: 'public',
          noErrorOnMissing: true,
        },
        {
          from: path.resolve(__dirname, 'src/views'),
          to: 'views',
          noErrorOnMissing: true,
        },
      ],
    }));

    // Add resolve extensions
    config.resolve = {
      ...config.resolve,
      extensions: ['.ts', '.js'],
    };

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
}));
