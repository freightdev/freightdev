<script>
    import Button from '$lib/components/core/Button.svelte';
    import { testSuites } from '$lib/stores/tests.js';
    import { Play, Plus, TestTube, Trash2 } from 'lucide-svelte';
</script>

// src/routes/test-suites/+page.svelte - Test Suites Management
<svelte:head>
    <title>Test Suites - Microservices Test Suite</title>
</svelte:head>

<div class="space-y-6">
    <!-- Page Header -->
    <div class="flex items-center justify-between">
        <div>
            <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Test Suites</h1>
            <p class="text-gray-600 dark:text-gray-400">Organize and manage your test cases</p>
        </div>

        <Button>
            <Plus class="h-4 w-4 mr-2" />
            Create Test Suite
        </Button>
    </div>

    {#if $testSuites.length === 0}
        <div class="text-center py-12">
            <TestTube class="h-16 w-16 text-gray-400 mx-auto mb-4" />
            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-2">
                No Test Suites Yet
            </h3>
            <p class="text-gray-600 dark:text-gray-400 mb-6">
                Create your first test suite to organize your API tests
            </p>
            <Button>
                <Plus class="h-4 w-4 mr-2" />
                Create Your First Test Suite
            </Button>
        </div>
    {:else}
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {#each $testSuites as suite}
                <div
                    class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6"
                >
                    <div class="flex items-start justify-between mb-4">
                        <div>
                            <h3 class="font-semibold text-gray-900 dark:text-white">
                                {suite.name}
                            </h3>
                            <p class="text-sm text-gray-600 dark:text-gray-400">
                                {suite.description || 'No description'}
                            </p>
                        </div>
                        <TestTube class="h-5 w-5 text-gray-400" />
                    </div>

                    <div class="flex items-center justify-between">
                        <span class="text-sm text-gray-600 dark:text-gray-400">
                            {suite.tests?.length || 0} tests
                        </span>

                        <div class="flex space-x-2">
                            <Button size="sm">
                                <Play class="h-3 w-3" />
                            </Button>
                            <Button size="sm" variant="ghost">
                                <Trash2 class="h-3 w-3 text-red-600" />
                            </Button>
                        </div>
                    </div>
                </div>
            {/each}
        </div>
    {/if}
</div>
