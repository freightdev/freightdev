<!-- src/lib/components/dashboard/RecentActivity.svelte -->
<script>
    import { CheckCircle, Clock, XCircle } from 'lucide-svelte';

    export let requestHistory = [];

    function getStatusColor(status) {
        if (typeof status === 'number') {
            if (status >= 200 && status < 300) return 'text-green-600';
            if (status >= 400) return 'text-red-600';
            return 'text-yellow-600';
        }
        return 'text-red-600';
    }

    function getStatusIcon(status) {
        if (typeof status === 'number' && status >= 200 && status < 300) {
            return CheckCircle;
        }
        return XCircle;
    }

    function formatTime(timestamp) {
        return new Date(timestamp).toLocaleTimeString();
    }
</script>

<div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
    <div class="flex items-center justify-between mb-6">
        <h2 class="text-lg font-semibold text-gray-900 dark:text-white">Recent Activity</h2>
        <Clock class="h-5 w-5 text-gray-400" />
    </div>

    {#if requestHistory.length === 0}
        <div class="text-center py-8">
            <Activity class="h-8 w-8 text-gray-400 mx-auto mb-2" />
            <p class="text-gray-600 dark:text-gray-400">No recent activity</p>
        </div>
    {:else}
        <div class="space-y-3">
            {#each requestHistory as request}
                <div
                    class="flex items-center justify-between p-3 border border-gray-100 dark:border-gray-700 rounded-lg"
                >
                    <div class="flex items-center space-x-3">
                        <svelte:component
                            this={getStatusIcon(request.status)}
                            class="h-4 w-4 {getStatusColor(request.status)}"
                        />

                        <div>
                            <p class="text-sm font-medium text-gray-900 dark:text-white">
                                {request.method}
                                {request.url.split('/').pop() || '/'}
                            </p>
                            <p class="text-xs text-gray-600 dark:text-gray-400">
                                {formatTime(request.timestamp)}
                            </p>
                        </div>
                    </div>

                    <div class="text-right">
                        <p class="text-sm font-medium {getStatusColor(request.status)}">
                            {request.status}
                        </p>
                        <p class="text-xs text-gray-600 dark:text-gray-400">
                            {request.responseTime}ms
                        </p>
                    </div>
                </div>
            {/each}
        </div>
    {/if}
</div>
