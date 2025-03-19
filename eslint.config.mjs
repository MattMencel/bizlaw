import js from '@eslint/js';
import { FlatCompat } from '@eslint/eslintrc';
import path from 'path';
import { fileURLToPath } from 'url';
import stylisticPlugin from '@stylistic/eslint-plugin';

// Set up __dirname equivalent for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Initialize the compatibility layer
const compat = new FlatCompat({
  baseDirectory: __dirname,
  recommendedConfig: js.configs.recommended,
});

// Extract the stylistic preset rules - this avoids circular references
const stylisticPresetRules = {
  // Use the recommended preset
  ...stylisticPlugin.configs.recommended.rules,

  // Also include the type-checked preset rules
  ...stylisticPlugin.configs['disable-legacy'].rules,

  // Just a few overrides for our preferences
  '@stylistic/quotes': ['warn', 'single', { avoidEscape: true }],
  '@stylistic/indent': ['warn', 2, { SwitchCase: 1 }],
  '@stylistic/object-curly-spacing': ['warn', 'always'],
  '@stylistic/semi': ['warn', 'always'],
};

const config = [
  // Base configurations
  js.configs.recommended,

  // TypeScript configurations
  ...compat.extends('plugin:@typescript-eslint/recommended'),

  // React configurations
  ...compat.extends('plugin:react/recommended'),
  ...compat.extends('plugin:react-hooks/recommended'),

  // Next.js configurations
  ...compat.extends('plugin:@next/next/recommended'),

  // Import plugin configurations
  ...compat.extends('plugin:import/recommended'),
  ...compat.extends('plugin:import/typescript'),

  // Accessibility configurations
  ...compat.extends('plugin:jsx-a11y/recommended'),

  // Add Stylistic plugin with presets
  {
    plugins: {
      '@stylistic': stylisticPlugin,
    },
    rules: stylisticPresetRules,
  },

  // Global configuration and rules
  {
    ignores: ['**/node_modules/**', '**/dist/**', '**/coverage/**'],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'module',
      parserOptions: {
        ecmaFeatures: {
          jsx: true,
        },
      },
    },
    settings: {
      react: {
        version: 'detect',
      },
      'import/resolver': {
        typescript: {
          alwaysTryTypes: true,
          project: './tsconfig.base.json',
        },
        node: {
          extensions: ['.js', '.jsx', '.ts', '.tsx'],
        },
      },
    },
    rules: {
      // JavaScript best practices
      'prefer-const': 'warn',
      'no-var': 'warn',
      eqeqeq: ['warn', 'smart'],
      'no-console': ['warn', { allow: ['warn', 'error', 'info'] }],
      'no-unused-vars': 'off',
      'arrow-body-style': ['warn', 'as-needed'],
      'object-shorthand': ['warn', 'always'],
      'prefer-template': 'warn',

      // TypeScript rules
      '@typescript-eslint/no-unused-vars': [
        'warn',
        {
          argsIgnorePattern: '^_',
          varsIgnorePattern: '^_',
          caughtErrorsIgnorePattern: '^_',
        },
      ],
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/explicit-function-return-type': 'off',
      '@typescript-eslint/explicit-module-boundary-types': 'off',
      '@typescript-eslint/consistent-type-imports': [
        'warn',
        {
          prefer: 'type-imports',
          disallowTypeAnnotations: false,
        },
      ],

      // React rules
      'react/react-in-jsx-scope': 'off',
      'react/prop-types': 'off',
      'react/jsx-boolean-value': ['warn', 'never'],
      'react/jsx-curly-brace-presence': [
        'warn',
        {
          props: 'never',
          children: 'never',
        },
      ],
      'react/jsx-no-useless-fragment': 'warn',

      // Import rules
      'import/order': [
        'warn',
        {
          groups: ['builtin', 'external', 'internal', ['parent', 'sibling', 'index']],
          'newlines-between': 'always',
          alphabetize: {
            order: 'asc',
            caseInsensitive: true,
          },
        },
      ],
      'import/no-unresolved': 'off',
      'import/first': 'warn',

      // Turn off standard rules that Stylistic handles
      indent: 'off',
      quotes: 'off',
      semi: 'off',
      'comma-dangle': 'off',
      'object-curly-spacing': 'off',
    },
  },

  // TypeScript-specific files
  {
    files: ['**/*.ts', '**/*.tsx'],
    rules: {
      '@typescript-eslint/no-non-null-assertion': 'warn',
    },
  },

  // Test files
  {
    files: ['**/*.{test,spec}.{ts,tsx,js,jsx}'],
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',
      'no-console': 'off',
    },
  },

  // Model files
  {
    files: ['**/models/**/*.ts'],
    rules: {
      '@typescript-eslint/no-unused-vars': 'off',
      'max-classes-per-file': 'off',
    },
  },

  // Next.js app-specific files
  {
    files: ['**/apps/bizlaw/**/*.{ts,tsx,js,jsx}'],
    rules: {
      '@next/next/no-html-link-for-pages': ['error', 'apps/bizlaw/src/app'],
    },
    settings: {
      next: {
        rootDir: 'apps/bizlaw',
      },
    },
  },

  // Configuration for CommonJS files (like config files)
  {
    files: [
      '**/tailwind.config.js',
      '**/postcss.config.js',
      '**/next.config.js',
      '**/jest.config.js',
      '**/*.config.js',
      '**/webpack.config.js',
      '**/.eslintrc.js',
      '**/babel.config.js',
      '**/commitlint.config.js',
      '**/nx.config.js'
    ],
    languageOptions: {
      sourceType: 'commonjs',
      globals: {
        // Add CommonJS globals
        require: 'readonly',
        module: 'writable',
        __dirname: 'readonly',
        __filename: 'readonly',
        process: 'readonly',
      },
    },
    rules: {
      // Disable ESM-specific rules for CommonJS files
      '@typescript-eslint/no-require-imports': 'off',
      '@typescript-eslint/no-var-requires': 'off',
    },
  },

  // Declaration files (.d.ts)
  {
    files: ['**/*.d.ts'],
    rules: {
      '@typescript-eslint/no-unused-vars': 'off',
      '@typescript-eslint/no-explicit-any': 'off',
      'import/no-duplicates': 'off',
    },
  },
];

export default config;
