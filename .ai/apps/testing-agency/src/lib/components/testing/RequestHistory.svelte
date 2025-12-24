<script>
    import { httpClient } from '$lib/services/httpClient.js';
    import { formatRelativeTime } from '$lib/utils/formatters.js';
    import { Bookmark, Clock, RotateCcw, Trash2 } from 'lucide-svelte';
    import Button from '../core/Button.svelte';

    export let onReplay = () => {};
    export let onSave = () => {};

    let history = [];
    let selectedRequest = null;

    $: history = httpClient.getHistory();

    function replayRequest(request) {
        onReplay({
            method: request.method,
            endpoint: request.url.split('/').slice(3).join('/'), // Remove protocol and domain
            // Would need to restore headers, body, etc. from stored request
        });
    }

    function saveAsTest(request) {
        onSave(request);
    }

    function clearHistory() {
        httpClient.clearHistory();
        history = [];
    }

    function getStatusColor(status) {
        if (typeof status === 'number') {
            if (status >= 200 && status < 300) return 'text-green-600';
            if (status >= 400) return 'text-red-600';
            return 'text-yellow-600';
        }
        return 'text-red-600';
    }
</script>

// src/lib/components/testing/RequestHistory.svelte
<div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
    <div class="p-4 border-b border-gray-200 dark:border-gray-700">
        <div class="flex items-center justify-between">
            <div class="flex items-center">
                <Clock class="h-5 w-5 text-gray-400 mr-2" />
                <h3 class="font-medium text-gray-900 dark:text-white">Request History</h3>
            </div>

            {#if history.length > 0}
                <Button size="sm" variant="ghost" on:click={clearHistory}>
                    <Trash2 class="h-3 w-3 mr-1" />
                    Clear
                </Button>
            {/if}
        </div>
    </div>

    <div class="max-h-96 overflow-y-auto">
        {#if history.length === 0}
            <div class="p-8 text-center">
                <Clock class="h-8 w-8 text-gray-400 mx-auto mb-2" />
                <p class="text-gray-500 dark:text-gray-400">No requests yet</p>
            </div>
        {:else}
            <div class="divide-y divide-gray-200 dark:divide-gray-700">
                {#each history as request}
                    <div class="p-4 hover:bg-gray-50 dark:hover:bg-gray-700">
                        <div class="flex items-center justify-between">
                            <div class="flex-1">
                                <div class="flex items-center space-x-3">
                                    <span
                                        class="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-gray-100 dark:bg-gray-600 text-gray-800 dark:text-gray-200"
                                    >
                                        {request.method}
                                    </span>
                                    <span
                                        class="text-sm font-medium text-gray-900 dark:text-white truncate"
                                    >
                                        {request.url.split('/').pop() || '/'}
                                    </span>
                                    <span
                                        class="text-sm font-medium {getStatusColor(request.status)}"
                                    >
                                        {request.status}
                                    </span>
                                    <span class="text-xs text-gray-500 dark:text-gray-400">
                                        {request.responseTime}ms
                                    </span>
                                </div>
                                <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                                    {formatRelativeTime(request.timestamp)}
                                </p>
                            </div>

                            <div class="flex items-center space-x-1">
                                <Button
                                    size="sm"
                                    variant="ghost"
                                    on:click={() => replayRequest(request)}
                                >
                                    <RotateCcw class="h-3 w-3" />
                                </Button>
                                <Button
                                    size="sm"
                                    variant="ghost"
                                    on:click={() => saveAsTest(request)}
                                >
                                    <Bookmark class="h-3 w-3" />
                                </Button>
                            </div>
                        </div>
                    </div>
                {/each}
            </div>
        {/if}
    </div>
</div>
