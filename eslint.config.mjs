import js from '@eslint/js';
import { FlatCompat } from '@eslint/eslintrc';
import path from 'path';
import { fileURLToPath } from 'url';
import typescriptEslintPlugin from '@typescript-eslint/eslint-plugin';
import typescriptEslintParser from '@typescript-eslint/parser';
import reactPlugin from 'eslint-plugin-react';
import jsxA11yPlugin from 'eslint-plugin-jsx-a11y';
import prettierPlugin from 'eslint-plugin-prettier';
import nxPlugin from '@nx/eslint-plugin';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Import Prettier config from .prettierrc
const prettierConfigPath = path.join(__dirname, '.prettierrc');
const prettierConfig = JSON.parse(fs.readFileSync(prettierConfigPath, 'utf8'));

const compat = new FlatCompat({
  baseDirectory: __dirname,
  recommendedConfig: js.configs.recommended,
});

const config = [
  ...compat.extends('eslint:recommended'),
  ...compat.extends('plugin:@typescript-eslint/recommended'),
  ...compat.extends('plugin:react/recommended'),
  ...compat.extends('plugin:jsx-a11y/recommended'),
  // The order is important - prettier should be last
  ...compat.extends('plugin:prettier/recommended'),
  ...compat.extends('next'),
  ...compat.extends('next/core-web-vitals'),
  {
    plugins: {
      '@typescript-eslint': typescriptEslintPlugin,
      react: reactPlugin,
      'jsx-a11y': jsxA11yPlugin,
      prettier: prettierPlugin,
      '@nx': nxPlugin,
    },
    languageOptions: {
      parser: typescriptEslintParser,
      ecmaVersion: 2020,
      sourceType: 'module',
    },
    rules: {
      // Use the imported Prettier config with "warn" instead of "error"
      'prettier/prettier': ['warn', prettierConfig],
      // Disable rules that might conflict with Prettier
      'max-len': 'off',
      quotes: ['warn', 'single', { avoidEscape: true }],
      // Turn off formatting rules that Prettier handles
      indent: 'off',
      'no-mixed-spaces-and-tabs': 'off',
      'comma-dangle': 'off',
      'object-curly-spacing': 'off',
    },
    settings: {
      react: {
        version: 'detect',
      },
    },
  },
];

export default config;
