// src/lib/services/testRunner.js
import { get } from 'svelte/store';
import { isTestRunning, testCases, testStore } from '../stores/tests.js';
import { uiStore } from '../stores/ui.js';
import { httpClient } from './httpClient.js';
import { serviceManager } from './serviceManager.js';

class TestRunner {
    constructor() {
        this.runningTests = new Map();
        this.testQueue = [];
        this.maxConcurrentTests = 3;
    }

    // Run a single test case
    async runTest(testId, options = {}) {
        const test = this.getTest(testId);
        if (!test) {
            throw new Error('Test not found');
        }

        // Check if test is already running
        if (this.runningTests.has(testId)) {
            throw new Error('Test is already running');
        }

        this.runningTests.set(testId, { startTime: Date.now(), status: 'running' });

        try {
            const result = await this.executeTest(test, options);

            // Store result
            testStore.addResult(result);

            this.runningTests.delete(testId);
            return result;
        } catch (error) {
            const errorResult = {
                testId: test.id,
                suiteId: test.suiteId,
                status: 'failed',
                error: error.message,
                responseTime: 0,
                statusCode: 0,
                response: null,
            };

            testStore.addResult(errorResult);
            this.runningTests.delete(testId);

            throw error;
        }
    }

    // Execute individual test
    async executeTest(test, options = {}) {
        const startTime = performance.now();

        try {
            // Get service configuration
            const service = serviceManager.getService(test.serviceId);
            if (!service) {
                throw new Error('Service not found');
            }

            const serviceConfig = serviceManager.getServiceConfig(service);
            const endpoint = serviceManager.buildEndpointUrl(serviceConfig.baseUrl, test.endpoint);

            // Build request configuration
            const requestConfig = {
                method: test.method,
                url: endpoint,
                headers: { ...serviceConfig.headers, ...test.headers },
                auth: test.auth || serviceConfig.auth,
                body: test.body,
                params: test.params,
                timeout: options.timeout || serviceConfig.timeout,
            };

            // Execute request
            const response = await httpClient.request(requestConfig);
            const endTime = performance.now();
            const responseTime = Math.round(endTime - startTime);

            // Run assertions
            const assertionResults = await this.runAssertions(test.assertions, response);

            const result = {
                testId: test.id,
                suiteId: test.suiteId,
                status: assertionResults.every(a => a.passed) ? 'passed' : 'failed',
                responseTime,
                statusCode: response.status,
                response: response.data,
                headers: response.headers,
                assertions: assertionResults,
                error: null,
            };

            return result;
        } catch (error) {
            const endTime = performance.now();
            const responseTime = Math.round(endTime - startTime);

            return {
                testId: test.id,
                suiteId: test.suiteId,
                status: 'failed',
                responseTime,
                statusCode: 0,
                response: null,
                headers: {},
                assertions: [],
                error: error.message,
            };
        }
    }

    // Run test assertions
    async runAssertions(assertions, response) {
        const results = [];

        for (const assertion of assertions) {
            try {
                const result = await this.evaluateAssertion(assertion, response);
                results.push({
                    type: assertion.type,
                    expected: assertion.expected,
                    actual: result.actual,
                    passed: result.passed,
                    message: result.message,
                });
            } catch (error) {
                results.push({
                    type: assertion.type,
                    expected: assertion.expected,
                    actual: null,
                    passed: false,
                    message: error.message,
                });
            }
        }

        return results;
    }

    // Evaluate single assertion
    async evaluateAssertion(assertion, response) {
        switch (assertion.type) {
            case 'status_code':
                return this.assertStatusCode(assertion.expected, response.status);

            case 'response_time':
                return this.assertResponseTime(assertion.expected, response.responseTime);

            case 'contains':
                return this.assertContains(assertion.expected, response.data);

            case 'equals':
                return this.assertEquals(assertion.expected, assertion.path, response.data);

            case 'json_path':
                return this.assertJsonPath(assertion.path, assertion.expected, response.data);

            case 'header_exists':
                return this.assertHeaderExists(assertion.expected, response.headers);

            case 'header_equals':
                return this.assertHeaderEquals(assertion.key, assertion.expected, response.headers);

            case 'regex':
                return this.assertRegex(assertion.pattern, response.data);

            case 'not_null':
                return this.assertNotNull(assertion.path, response.data);

            case 'type':
                return this.assertType(assertion.expected, assertion.path, response.data);

            default:
                throw new Error(`Unknown assertion type: ${assertion.type}`);
        }
    }

    // Status code assertion
    assertStatusCode(expected, actual) {
        const passed = actual === expected;
        return {
            passed,
            actual,
            message: passed
                ? `Status code is ${actual}`
                : `Expected status ${expected}, got ${actual}`,
        };
    }

    // Response time assertion
    assertResponseTime(expected, actual) {
        const passed = actual <= expected;
        return {
            passed,
            actual,
            message: passed
                ? `Response time ${actual}ms is within ${expected}ms`
                : `Response time ${actual}ms exceeds ${expected}ms`,
        };
    }

    // Contains assertion
    assertContains(expected, data) {
        const dataStr = typeof data === 'string' ? data : JSON.stringify(data);
        const passed = dataStr.includes(expected);
        return {
            passed,
            actual: dataStr,
            message: passed
                ? `Response contains "${expected}"`
                : `Response does not contain "${expected}"`,
        };
    }

    // Equals assertion
    assertEquals(expected, path, data) {
        const actual = this.getValueByPath(data, path);
        const passed = JSON.stringify(actual) === JSON.stringify(expected);
        return {
            passed,
            actual,
            message: passed
                ? `Value at ${path} equals expected`
                : `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
        };
    }

    // JSON path assertion
    assertJsonPath(path, expected, data) {
        const actual = this.getValueByPath(data, path);
        const passed = actual !== undefined && JSON.stringify(actual) === JSON.stringify(expected);
        return {
            passed,
            actual,
            message: passed
                ? `JSON path ${path} matches expected value`
                : `JSON path ${path}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
        };
    }

    // Header exists assertion
    assertHeaderExists(headerName, headers) {
        const passed = headers.hasOwnProperty(headerName.toLowerCase());
        return {
            passed,
            actual: headers,
            message: passed
                ? `Header "${headerName}" exists`
                : `Header "${headerName}" does not exist`,
        };
    }

    // Header equals assertion
    assertHeaderEquals(headerName, expected, headers) {
        const actual = headers[headerName.toLowerCase()];
        const passed = actual === expected;
        return {
            passed,
            actual,
            message: passed
                ? `Header "${headerName}" equals expected value`
                : `Header "${headerName}": expected "${expected}", got "${actual}"`,
        };
    }

    // Regex assertion
    assertRegex(pattern, data) {
        const dataStr = typeof data === 'string' ? data : JSON.stringify(data);
        const regex = new RegExp(pattern);
        const passed = regex.test(dataStr);
        return {
            passed,
            actual: dataStr,
            message: passed
                ? `Response matches regex pattern`
                : `Response does not match regex pattern: ${pattern}`,
        };
    }

    // Not null assertion
    assertNotNull(path, data) {
        const actual = this.getValueByPath(data, path);
        const passed = actual !== null && actual !== undefined;
        return {
            passed,
            actual,
            message: passed
                ? `Value at ${path} is not null`
                : `Value at ${path} is null or undefined`,
        };
    }

    // Type assertion
    assertType(expectedType, path, data) {
        const actual = this.getValueByPath(data, path);
        const actualType = Array.isArray(actual) ? 'array' : typeof actual;
        const passed = actualType === expectedType;
        return {
            passed,
            actual: actualType,
            message: passed
                ? `Value at ${path} is of type ${actualType}`
                : `Expected type ${expectedType}, got ${actualType}`,
        };
    }

    // Get value by path (simple dot notation)
    getValueByPath(obj, path) {
        if (!path) return obj;
        return path.split('.').reduce((current, key) => {
            return current && current[key] !== undefined ? current[key] : undefined;
        }, obj);
    }

    // Run test suite
    async runTestSuite(suiteId, options = {}) {
        const tests = get(testCases).filter(test => test.suiteId === suiteId);

        if (tests.length === 0) {
            throw new Error('No tests found in suite');
        }

        isTestRunning.set(true);

        try {
            const results = [];

            if (options.parallel) {
                // Run tests in parallel
                const promises = tests.map(test => this.runTest(test.id, options));
                const settled = await Promise.allSettled(promises);

                settled.forEach((result, index) => {
                    if (result.status === 'fulfilled') {
                        results.push(result.value);
                    } else {
                        results.push({
                            testId: tests[index].id,
                            suiteId,
                            status: 'failed',
                            error: result.reason.message,
                            responseTime: 0,
                            statusCode: 0,
                            response: null,
                        });
                    }
                });
            } else {
                // Run tests sequentially
                for (const test of tests) {
                    try {
                        const result = await this.runTest(test.id, options);
                        results.push(result);
                    } catch (error) {
                        results.push({
                            testId: test.id,
                            suiteId,
                            status: 'failed',
                            error: error.message,
                            responseTime: 0,
                            statusCode: 0,
                            response: null,
                        });
                    }
                }
            }

            isTestRunning.set(false);

            uiStore.showNotification({
                type: 'success',
                message: `Test suite completed: ${results.filter(r => r.status === 'passed').length}/${results.length} passed`,
            });

            return results;
        } catch (error) {
            isTestRunning.set(false);
            throw error;
        }
    }

    // Get test by ID
    getTest(testId) {
        const tests = get(testCases);
        return tests.find(test => test.id === testId);
    }

    // Check if test is running
    isTestRunning(testId) {
        return this.runningTests.has(testId);
    }

    // Get running tests
    getRunningTests() {
        return Array.from(this.runningTests.entries()).map(([id, info]) => ({
            testId: id,
            ...info,
        }));
    }

    // Stop running test (if possible)
    stopTest(testId) {
        if (this.runningTests.has(testId)) {
            this.runningTests.delete(testId);
            return true;
        }
        return false;
    }

    // Stop all running tests
    stopAllTests() {
        this.runningTests.clear();
        isTestRunning.set(false);
    }

    // Generate test report
    generateReport(results) {
        const total = results.length;
        const passed = results.filter(r => r.status === 'passed').length;
        const failed = results.filter(r => r.status === 'failed').length;
        const avgResponseTime =
            total > 0 ? results.reduce((sum, r) => sum + r.responseTime, 0) / total : 0;

        return {
            summary: {
                total,
                passed,
                failed,
                successRate: ((passed / total) * 100).toFixed(1),
                avgResponseTime: Math.round(avgResponseTime),
            },
            results,
            timestamp: new Date().toISOString(),
        };
    }
}

// Create singleton instance
export const testRunner = new TestRunner();

export default testRunner;
