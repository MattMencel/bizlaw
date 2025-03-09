const { composePlugins, withNx } = require('@nx/webpack');
const path = require('path');

// Nx plugins for webpack.
module.exports = composePlugins(withNx(), (config) => {
  // Add Node.js specific configurations
  config.target = 'node';
  
  // Externalize node_modules - using a safer approach
  config.externalsPresets = { node: true };
  
  // Configure output
  config.output = {
    ...config.output,
    path: path.resolve(__dirname, '../../dist/apps/api'),
    filename: 'main.js',
    libraryTarget: 'commonjs',
  };
  
  // Ensure module rules exists before pushing
  if (!config.module) config.module = {};
  if (!config.module.rules) config.module.rules = [];
  
  // Handle assets
  config.module.rules.push({
    test: /\.(txt|sql|html|hbs)$/,
    type: 'asset/source',  // Modern approach instead of raw-loader
  });
  
  // Optimize for Node.js
  config.optimization = {
    ...config.optimization,
    minimize: false,
  };

  // Add resolve extensions
  config.resolve = {
    ...config.resolve,
    extensions: ['.ts', '.js'],
  };

  return config;
});