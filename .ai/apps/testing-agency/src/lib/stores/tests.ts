// src/lib/stores/tests.js
import type { TestCase, TestResult, TestSuite } from '$lib/types';
import { derived, writable } from 'svelte/store';
import { v4 as uuidv4 } from 'uuid';

/** Writable stores */

export const testSuites = writable<TestSuite[]>([]);
export const testCases = writable<TestCase[]>([]);
export const testResults = writable<TestResult[]>([]);
export const selectedTestSuite = writable<TestSuite | null>(null);
export const isTestRunning = writable(false);
export const testHistory = writable<TestResult[]>([]);

/** Derived stores */

export const recentTestResults = derived(testResults, ($results) => $results.slice(-10).reverse());

export const testStats = derived(testResults, ($results) => {
	const total = $results.length;
	const passed = $results.filter((r) => r.status === 'passed').length;
	const failed = $results.filter((r) => r.status === 'failed').length;
	const successRate = total > 0 ? parseFloat(((passed / total) * 100).toFixed(1)) : 0;

	return { total, passed, failed, successRate };
});

/** Store actions */

export const testStore = {
	createSuite: (suiteData: Omit<TestSuite, 'id' | 'tests' | 'createdAt' | 'updatedAt'>) => {
		const newSuite: TestSuite = {
			id: uuidv4(),
			tests: [],
			createdAt: new Date().toISOString(),
			updatedAt: new Date().toISOString(),
			...suiteData
		};
		testSuites.update((suites) => [...suites, newSuite]);
		return newSuite;
	},

	createTest: (
		testData: Omit<
			TestCase,
			'id' | 'createdAt' | 'updatedAt' | 'assertions' | 'headers' | 'body' | 'method'
		>
	) => {
		const newTest: TestCase = {
			id: uuidv4(),
			method: 'GET',
			headers: {},
			body: null,
			assertions: [],
			createdAt: new Date().toISOString(),
			updatedAt: new Date().toISOString(),
			...testData
		};
		testCases.update((tests) => [...tests, newTest]);
		return newTest;
	},

	addResult: (result: Omit<TestResult, 'id' | 'timestamp'>) => {
		const testResult: TestResult = {
			id: uuidv4(),
			timestamp: new Date().toISOString(),
			...result
		};
		testResults.update((results) => [...results, testResult]);
		return testResult;
	}
};
