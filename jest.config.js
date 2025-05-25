/** @type {import('ts-jest').JestConfigWithTsJest} */
const fs = require('fs');
const path = require('path');

// Automatically include any package level `__tests__` directories
const packagesDir = path.join(__dirname, 'packages');
const packageTestRoots = fs.existsSync(packagesDir)
  ? fs
      .readdirSync(packagesDir)
      .map((pkg) => path.join(packagesDir, pkg, '__tests__'))
      .filter((dir) => fs.existsSync(dir))
      .map((dir) => `<rootDir>/${path.relative(__dirname, dir)}`)
  : [];

module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  // Include project tests and any package `__tests__` directories
  roots: ['<rootDir>/tests', '<rootDir>/src', ...packageTestRoots],
  moduleFileExtensions: ['ts', 'js', 'json', 'node'],
  setupFilesAfterEnv: ['<rootDir>/tests/setup.ts'],
  globals: {
    'ts-jest': {
      tsconfig: 'tsconfig.json',
    },
  },
  globalSetup: '<rootDir>/tests/globalSetup.ts',
  globalTeardown: '<rootDir>/tests/globalTeardown.ts',
};
