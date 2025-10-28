module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  parserOptions: {
    project: ['tsconfig.json'],
  },
  plugins: ['@typescript-eslint'],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
  ],
  rules: {
    'require-jsdoc': 'off',
    'max-len': ['warn', { code: 120 }],
  },
  ignorePatterns: ['lib/', 'dist/', 'index.js'],
};
