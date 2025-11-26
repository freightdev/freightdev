<!-- src/lib/components/testing/ResponseViewer.svelte -->
<script>
    import { Code, Copy, Download, Eye, EyeOff, XCircle } from 'lucide-svelte';

    import Button from '../core/Button.svelte';

    export let response = null;
    export let error = null;
    export let loading = false;

    let activeTab = 'response'; // response, headers, raw
    let showPrettyJson = true;
    let copied = false;

    $: statusColor = getStatusColor(response?.status);
    $: formattedResponse = formatResponse(response?.data);
    $: responseSize = calculateSize(response?.data);

    function getStatusColor(status) {
        if (!status) return 'text-gray-500';
        if (status >= 200 && status < 300) return 'text-green-600 dark:text-green-400';
        if (status >= 300 && status < 400) return 'text-yellow-600 dark:text-yellow-400';
        if (status >= 400) return 'text-red-600 dark:text-red-400';
        return 'text-gray-500';
    }

    function formatResponse(data) {
        if (!data) return '';

        if (typeof data === 'object') {
            return showPrettyJson ? JSON.stringify(data, null, 2) : JSON.stringify(data);
        }

        return data.toString();
    }

    function calculateSize(data) {
        if (!data) return '0 B';

        const bytes = new Blob([typeof data === 'string' ? data : JSON.stringify(data)]).size;

        if (bytes < 1024) return `${bytes} B`;
        if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
        return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
    }

    async function copyToClipboard() {
        try {
            await navigator.clipboard.writeText(formattedResponse);
            copied = true;
            setTimeout(() => (copied = false), 2000);
        } catch (err) {
            console.error('Failed to copy:', err);
        }
    }

    function downloadResponse() {
        const blob = new Blob([formattedResponse], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `response-${Date.now()}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }
</script>

<div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
    <!-- Header -->
    <div class="p-4 border-b border-gray-200 dark:border-gray-700">
        <div class="flex items-center justify-between">
            <h2 class="text-lg font-semibold text-gray-900 dark:text-white">Response</h2>

            {#if response}
                <div class="flex items-center space-x-3">
                    <Button size="sm" variant="ghost" on:click={copyToClipboard}>
                        <Copy class="h-3 w-3 mr-1" />
                        {copied ? 'Copied!' : 'Copy'}
                    </Button>

                    <Button size="sm" variant="ghost" on:click={downloadResponse}>
                        <Download class="h-3 w-3 mr-1" />
                        Download
                    </Button>

                    <Button
                        size="sm"
                        variant="ghost"
                        on:click={() => (showPrettyJson = !showPrettyJson)}
                    >
                        {#if showPrettyJson}
                            <EyeOff class="h-3 w-3 mr-1" />
                            Compact
                        {:else}
                            <Eye class="h-3 w-3 mr-1" />
                            Pretty
                        {/if}
                    </Button>
                </div>
            {/if}
        </div>
    </div>

    <div class="p-4">
        {#if loading}
            <div class="flex items-center justify-center py-12">
                <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                <span class="ml-3 text-gray-600 dark:text-gray-400">Sending request...</span>
            </div>
        {:else if error}
            <div class="flex items-center justify-center py-12">
                <div class="text-center">
                    <XCircle class="h-12 w-12 text-red-500 mx-auto mb-4" />
                    <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-2">
                        Request Failed
                    </h3>
                    <p class="text-gray-600 dark:text-gray-400">{error.message}</p>
                </div>
            </div>
        {:else if !response}
            <div class="flex items-center justify-center py-12">
                <div class="text-center">
                    <Code class="h-12 w-12 text-gray-400 mx-auto mb-4" />
                    <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-2">
                        No Response Yet
                    </h3>
                    <p class="text-gray-600 dark:text-gray-400">
                        Send a request to see the response here
                    </p>
                </div>
            </div>
        {:else}
            <!-- Response Info -->
            <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
                <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-3 text-center">
                    <p class="text-sm text-gray-600 dark:text-gray-400">Status</p>
                    <p class="text-lg font-semibold {statusColor}">
                        {response.status}
                        {response.statusText}
                    </p>
                </div>

                <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-3 text-center">
                    <p class="text-sm text-gray-600 dark:text-gray-400">Time</p>
                    <p class="text-lg font-semibold text-gray-900 dark:text-white">
                        {response.responseTime}ms
                    </p>
                </div>

                <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-3 text-center">
                    <p class="text-sm text-gray-600 dark:text-gray-400">Size</p>
                    <p class="text-lg font-semibold text-gray-900 dark:text-white">
                        {responseSize}
                    </p>
                </div>

                <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-3 text-center">
                    <p class="text-sm text-gray-600 dark:text-gray-400">Type</p>
                    <p class="text-lg font-semibold text-gray-900 dark:text-white">
                        {response.headers['content-type']?.split(';')[0] || 'Unknown'}
                    </p>
                </div>
            </div>

            <!-- Tabs -->
            <div class="border-b border-gray-200 dark:border-gray-700 mb-4">
                <nav class="-mb-px flex space-x-8">
                    <button
                        class="py-2 px-1 border-b-2 font-medium text-sm {activeTab === 'response'
                            ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                            : 'border-transparent text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'}"
                        on:click={() => (activeTab = 'response')}
                    >
                        Response Body
                    </button>

                    <button
                        class="py-2 px-1 border-b-2 font-medium text-sm {activeTab === 'headers'
                            ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                            : 'border-transparent text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'}"
                        on:click={() => (activeTab = 'headers')}
                    >
                        Headers ({Object.keys(response.headers || {}).length})
                    </button>

                    <button
                        class="py-2 px-1 border-b-2 font-medium text-sm {activeTab === 'raw'
                            ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                            : 'border-transparent text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'}"
                        on:click={() => (activeTab = 'raw')}
                    >
                        Raw
                    </button>
                </nav>
            </div>

            <!-- Tab Content -->
            <div class="min-h-[300px]">
                {#if activeTab === 'response'}
                    <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-4 overflow-x-auto">
                        <pre
                            class="text-sm font-mono text-gray-800 dark:text-gray-200 whitespace-pre-wrap">{formattedResponse}</pre>
                    </div>
                {:else if activeTab === 'headers'}
                    <div class="space-y-2">
                        {#each Object.entries(response.headers || {}) as [key, value]}
                            <div
                                class="flex items-start space-x-4 p-3 bg-gray-50 dark:bg-gray-700 rounded-lg"
                            >
                                <div class="flex-shrink-0 w-1/3">
                                    <p class="font-medium text-gray-900 dark:text-white">{key}</p>
                                </div>
                                <div class="flex-1">
                                    <p class="text-gray-600 dark:text-gray-400 break-all">
                                        {value}
                                    </p>
                                </div>
                            </div>
                        {/each}

                        {#if Object.keys(response.headers || {}).length === 0}
                            <p class="text-center text-gray-500 dark:text-gray-400 py-8">
                                No response headers
                            </p>
                        {/if}
                    </div>
                {:else if activeTab === 'raw'}
                    <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-4 overflow-x-auto">
                        <pre
                            class="text-sm font-mono text-gray-800 dark:text-gray-200 whitespace-pre-wrap">{JSON.stringify(
                                response,
                                null,
                                2
                            )}</pre>
                    </div>
                {/if}
            </div>
        {/if}
    </div>
</div>
