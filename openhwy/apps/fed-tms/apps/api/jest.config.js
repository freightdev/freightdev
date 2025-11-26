module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>'],
  testMatch: ['**/__tests__/**/*.ts?(x)', '**/?(*.)+(spec|test).ts?(x)'],
  moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx', 'json'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/lib/$1',
    '^@repo/(.*)$': '<rootDir>/../../packages/$1',
  },
  collectCoverageFrom: [
    'app/**/*.ts',
    'lib/**/*.ts',
    '!**/*.d.ts',
    '!**/node_modules/**',
    '!**/__tests__/**',
  ],
  coveragePathIgnorePatterns: ['/node_modules/', '/__tests__/'],
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  testPathIgnorePatterns: ['/node_modules/', '/.next/'],
  transformIgnorePatterns: ['/node_modules/'],
  globals: {
    'ts-jest': {
      tsconfig: {
        jsx: 'react',
        esModuleInterop: true,
        allowSyntheticDefaultImports: true,
      },
    },
  },
  verbose: true,
}
