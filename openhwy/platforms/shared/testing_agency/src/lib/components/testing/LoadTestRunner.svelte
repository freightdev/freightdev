<script>
    import { loadTester } from '$lib/services/loadTester.js';
    import { services } from '$lib/stores/services.js';
    import { Play, Square, Zap } from 'lucide-svelte';
    import { createEventDispatcher } from 'svelte';
    import Button from '../core/Button.svelte';
    import Input from '../core/Input.svelte';

    const dispatch = createEventDispatcher();

    export let serviceId = '';
    export let endpoint = '/';

    let config = {
        concurrency: 10,
        duration: 30,
        rampUpTime: 5,
        thinkTime: 100,
        method: 'GET',
    };

    let activeTestId = null;
    let results = null;
    let realTimeStats = null;

    $: selectedService = $services.find(s => s.id === serviceId);

    async function startLoadTest() {
        if (!serviceId || !endpoint) return;

        activeTestId = await loadTester.runLoadTest({
            serviceId,
            endpoint,
            ...config,
        });

        // Poll for real-time stats
        const pollInterval = setInterval(() => {
            if (!activeTestId) {
                clearInterval(pollInterval);
                return;
            }

            const test = loadTester.activeTests.get(activeTestId);
            if (test && test.active) {
                realTimeStats = { ...test.stats };
            } else {
                clearInterval(pollInterval);
                results = loadTester.getLoadTestResults(activeTestId);
                activeTestId = null;
                realTimeStats = null;
            }
        }, 1000);
    }

    function stopLoadTest() {
        if (activeTestId) {
            loadTester.stopLoadTest(activeTestId);
        }
    }

    function formatNumber(num) {
        return new Intl.NumberFormat().format(Math.round(num));
    }
</script>

// src/lib/components/testing/LoadTestRunner.svelte
<div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
    <div class="flex items-center justify-between mb-6">
        <div class="flex items-center">
            <Zap class="h-5 w-5 text-yellow-600 mr-2" />
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Load Testing</h3>
        </div>

        {#if activeTestId}
            <Button variant="danger" on:click={stopLoadTest}>
                <Square class="h-4 w-4 mr-2" />
                Stop Test
            </Button>
        {:else}
            <Button on:click={startLoadTest} disabled={!serviceId || !endpoint}>
                <Play class="h-4 w-4 mr-2" />
                Start Load Test
            </Button>
        {/if}
    </div>

    <!-- Configuration -->
    {#if !activeTestId && !results}
        <div class="grid grid-cols-2 gap-4 mb-6">
            <Input
                label="Concurrent Users"
                type="number"
                bind:value={config.concurrency}
                placeholder="10"
            />
            <Input
                label="Duration (seconds)"
                type="number"
                bind:value={config.duration}
                placeholder="30"
            />
            <Input
                label="Ramp-up Time (seconds)"
                type="number"
                bind:value={config.rampUpTime}
                placeholder="5"
            />
            <Input
                label="Think Time (ms)"
                type="number"
                bind:value={config.thinkTime}
                placeholder="100"
            />
        </div>
    {/if}

    <!-- Real-time Stats -->
    {#if realTimeStats}
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
            <div class="bg-blue-50 dark:bg-blue-900 rounded-lg p-4 text-center">
                <div class="text-2xl font-bold text-blue-600 dark:text-blue-300">
                    {formatNumber(realTimeStats.totalRequests)}
                </div>
                <div class="text-sm text-blue-600 dark:text-blue-400">Total Requests</div>
            </div>

            <div class="bg-green-50 dark:bg-green-900 rounded-lg p-4 text-center">
                <div class="text-2xl font-bold text-green-600 dark:text-green-300">
                    {formatNumber(realTimeStats.successfulRequests)}
                </div>
                <div class="text-sm text-green-600 dark:text-green-400">Successful</div>
            </div>

            <div class="bg-red-50 dark:bg-red-900 rounded-lg p-4 text-center">
                <div class="text-2xl font-bold text-red-600 dark:text-red-300">
                    {formatNumber(realTimeStats.failedRequests)}
                </div>
                <div class="text-sm text-red-600 dark:text-red-400">Failed</div>
            </div>

            <div class="bg-yellow-50 dark:bg-yellow-900 rounded-lg p-4 text-center">
                <div class="text-2xl font-bold text-yellow-600 dark:text-yellow-300">
                    {realTimeStats.responseTimes.length > 0
                        ? Math.round(
                              realTimeStats.responseTimes.slice(-10).reduce((a, b) => a + b, 0) /
                                  realTimeStats.responseTimes.slice(-10).length
                          )
                        : 0}ms
                </div>
                <div class="text-sm text-yellow-600 dark:text-yellow-400">Avg Response Time</div>
            </div>
        </div>

        <div class="mb-4">
            <div class="bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                <div
                    class="bg-blue-600 h-2 rounded-full transition-all duration-1000"
                    style="width: {((Date.now() - realTimeStats.startTime) /
                        (config.duration * 1000)) *
                        100}%"
                ></div>
            </div>
            <div class="text-xs text-gray-500 dark:text-gray-400 mt-1 text-center">
                Test Progress
            </div>
        </div>
    {/if}

    <!-- Final Results -->
    {#if results}
        <div class="space-y-6">
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div class="text-center">
                    <div class="text-2xl font-bold text-gray-900 dark:text-white">
                        {formatNumber(results.throughput)}
                    </div>
                    <div class="text-sm text-gray-600 dark:text-gray-400">Requests/sec</div>
                </div>

                <div class="text-center">
                    <div class="text-2xl font-bold text-gray-900 dark:text-white">
                        {Math.round(results.averageResponseTime)}ms
                    </div>
                    <div class="text-sm text-gray-600 dark:text-gray-400">Avg Response</div>
                </div>

                <div class="text-center">
                    <div class="text-2xl font-bold text-gray-900 dark:text-white">
                        {((results.successfulRequests / results.totalRequests) * 100).toFixed(1)}%
                    </div>
                    <div class="text-sm text-gray-600 dark:text-gray-400">Success Rate</div>
                </div>

                <div class="text-center">
                    <div class="text-2xl font-bold text-gray-900 dark:text-white">
                        {Math.round(results.percentiles.p95 || 0)}ms
                    </div>
                    <div class="text-sm text-gray-600 dark:text-gray-400">95th Percentile</div>
                </div>
            </div>

            <!-- Percentiles -->
            <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
                <h4 class="font-medium text-gray-900 dark:text-white mb-3">
                    Response Time Percentiles
                </h4>
                <div class="grid grid-cols-5 gap-4 text-sm">
                    <div class="text-center">
                        <div class="font-semibold">50th</div>
                        <div class="text-gray-600 dark:text-gray-400">
                            {Math.round(results.percentiles.p50 || 0)}ms
                        </div>
                    </div>
                    <div class="text-center">
                        <div class="font-semibold">75th</div>
                        <div class="text-gray-600 dark:text-gray-400">
                            {Math.round(results.percentiles.p75 || 0)}ms
                        </div>
                    </div>
                    <div class="text-center">
                        <div class="font-semibold">90th</div>
                        <div class="text-gray-600 dark:text-gray-400">
                            {Math.round(results.percentiles.p90 || 0)}ms
                        </div>
                    </div>
                    <div class="text-center">
                        <div class="font-semibold">95th</div>
                        <div class="text-gray-600 dark:text-gray-400">
                            {Math.round(results.percentiles.p95 || 0)}ms
                        </div>
                    </div>
                    <div class="text-center">
                        <div class="font-semibold">99th</div>
                        <div class="text-gray-600 dark:text-gray-400">
                            {Math.round(results.percentiles.p99 || 0)}ms
                        </div>
                    </div>
                </div>
            </div>

            <div class="flex justify-center">
                <Button variant="secondary" on:click={() => (results = null)}>
                    Run Another Test
                </Button>
            </div>
        </div>
    {/if}
</div>
