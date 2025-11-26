<!-- src/lib/components/dashboard/ServiceOverview.svelte -->
<script>
    import { serviceManager } from '$lib/services/serviceManager.js';
    import { services } from '$lib/stores/services.js';
    import { Activity, AlertTriangle, Plus, Server } from 'lucide-svelte';
    import Button from '../core/Button.svelte';

    function getStatusColor(status) {
        switch (status) {
            case 'active':
                return 'text-green-600 bg-green-100 dark:bg-green-900 dark:text-green-300';
            case 'inactive':
                return 'text-red-600 bg-red-100 dark:bg-red-900 dark:text-red-300';
            case 'checking':
                return 'text-yellow-600 bg-yellow-100 dark:bg-yellow-900 dark:text-yellow-300';
            default:
                return 'text-gray-600 bg-gray-100 dark:bg-gray-700 dark:text-gray-300';
        }
    }

    function getStatusIcon(status) {
        switch (status) {
            case 'active':
                return Activity;
            case 'inactive':
                return AlertTriangle;
            case 'checking':
                return Activity;
            default:
                return Server;
        }
    }

    async function checkHealth(serviceId) {
        await serviceManager.checkServiceHealth(serviceId);
    }
</script>

<div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
    <div class="flex items-center justify-between mb-6">
        <h2 class="text-lg font-semibold text-gray-900 dark:text-white">Services Overview</h2>
        <Button href="/services" size="sm">
            <Plus class="h-4 w-4 mr-2" />
            Add Service
        </Button>
    </div>

    {#if $services.length === 0}
        <div class="text-center py-12">
            <Server class="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-2">No Services Yet</h3>
            <p class="text-gray-600 dark:text-gray-400 mb-4">
                Get started by adding your first microservice
            </p>
            <Button href="/services">Add Your First Service</Button>
        </div>
    {:else}
        <div class="space-y-4">
            {#each $services as service}
                <div
                    class="flex items-center justify-between p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
                >
                    <div class="flex items-center space-x-4">
                        <div class="flex-shrink-0">
                            <svelte:component
                                this={getStatusIcon(service.status)}
                                class="h-5 w-5 {getStatusColor(service.status)}"
                            />
                        </div>

                        <div>
                            <h3 class="font-medium text-gray-900 dark:text-white">
                                {service.name}
                            </h3>
                            <p class="text-sm text-gray-600 dark:text-gray-400">
                                {service.baseUrl}
                            </p>
                        </div>
                    </div>

                    <div class="flex items-center space-x-3">
                        <span
                            class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium {getStatusColor(
                                service.status
                            )}"
                        >
                            {service.status || 'unknown'}
                        </span>

                        <Button size="sm" variant="ghost" on:click={() => checkHealth(service.id)}>
                            Check Health
                        </Button>
                    </div>
                </div>
            {/each}
        </div>
    {/if}
</div>
