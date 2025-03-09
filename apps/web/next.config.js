const withTM = require('next-transpile-modules')(['sequelize-typescript']);

module.exports = withTM({
  reactStrictMode: true,
  webpack: (config, { isServer }) => {
    config.module.rules.push({
      test: /\.ts$/,
      use: [
        {
          loader: 'ts-loader',
          options: {
            transpileOnly: true,
          },
        },
      ],
      exclude: /node_modules/,
    });

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
});