// src/lib/services/loadTester.js
// Advanced Load Testing Engine

export class LoadTester {
    constructor() {
        this.activeTests = new Map();
        this.results = [];
    }

    async runLoadTest(config) {
        const {
            serviceId,
            endpoint,
            method = 'GET',
            concurrency = 10,
            duration = 30, // seconds
            rampUpTime = 5, // seconds
            headers = {},
            body = null,
            thinkTime = 0, // milliseconds between requests per user
        } = config;

        const testId = `load-test-${Date.now()}`;
        const startTime = Date.now();
        const endTime = startTime + duration * 1000;

        const stats = {
            testId,
            totalRequests: 0,
            successfulRequests: 0,
            failedRequests: 0,
            responseTimes: [],
            errors: [],
            throughput: 0,
            averageResponseTime: 0,
            percentiles: {},
            startTime,
            endTime: null,
        };

        this.activeTests.set(testId, { config, stats, active: true });

        // Ramp up users gradually
        const usersPerSecond = concurrency / rampUpTime;
        const activeWorkers = [];

        for (let i = 0; i < concurrency; i++) {
            const delay = (i / usersPerSecond) * 1000; // Stagger user start times

            setTimeout(() => {
                if (this.activeTests.get(testId)?.active) {
                    const worker = this.createLoadTestWorker(testId, config, stats);
                    activeWorkers.push(worker);
                }
            }, delay);
        }

        // Stop test after duration
        setTimeout(() => {
            const test = this.activeTests.get(testId);
            if (test) {
                test.active = false;
                stats.endTime = Date.now();
                stats.throughput = stats.totalRequests / ((stats.endTime - stats.startTime) / 1000);
                stats.averageResponseTime =
                    stats.responseTimes.length > 0
                        ? stats.responseTimes.reduce((a, b) => a + b, 0) /
                          stats.responseTimes.length
                        : 0;
                stats.percentiles = this.calculatePercentiles(stats.responseTimes);

                this.results.push(stats);
            }
        }, duration * 1000);

        return testId;
    }

    async createLoadTestWorker(testId, config, stats) {
        const { serviceManager } = await import('./serviceManager.js');

        while (this.activeTests.get(testId)?.active) {
            const requestStart = Date.now();

            try {
                await serviceManager.testEndpoint(config.serviceId, config.endpoint, {
                    method: config.method,
                    headers: config.headers,
                    body: config.body,
                    timeout: 10000, // 10 second timeout for load testing
                });

                const responseTime = Date.now() - requestStart;
                stats.totalRequests++;
                stats.successfulRequests++;
                stats.responseTimes.push(responseTime);
            } catch (error) {
                stats.totalRequests++;
                stats.failedRequests++;
                stats.errors.push({
                    timestamp: Date.now(),
                    error: error.message,
                });
            }

            // Think time between requests
            if (config.thinkTime > 0) {
                await this.delay(config.thinkTime);
            }
        }
    }

    calculatePercentiles(responseTimes) {
        if (responseTimes.length === 0) return {};

        const sorted = [...responseTimes].sort((a, b) => a - b);
        return {
            p50: this.percentile(sorted, 0.5),
            p75: this.percentile(sorted, 0.75),
            p90: this.percentile(sorted, 0.9),
            p95: this.percentile(sorted, 0.95),
            p99: this.percentile(sorted, 0.99),
        };
    }

    percentile(sorted, p) {
        const index = Math.ceil(sorted.length * p) - 1;
        return sorted[index] || 0;
    }

    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    stopLoadTest(testId) {
        const test = this.activeTests.get(testId);
        if (test) {
            test.active = false;
        }
    }

    getLoadTestResults(testId) {
        return this.results.find(r => r.testId === testId);
    }

    getAllResults() {
        return this.results;
    }
}

export const loadTester = new LoadTester();
