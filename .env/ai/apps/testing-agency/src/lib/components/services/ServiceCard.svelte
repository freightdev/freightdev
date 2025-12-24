<!-- src/lib/components/services/ServiceCard.svelte -->
<script>
    import {
        Activity,
        AlertTriangle,
        ExternalLink,
        Server,
        Settings,
        TestTube,
        Trash2,
    } from 'lucide-svelte';
    import { createEventDispatcher } from 'svelte';

    import { serviceManager } from '$lib/services/serviceManager.js';
    import { uiStore } from '$lib/stores/ui.js';
    import Button from '../core/Button.svelte';

    export let service;

    const dispatch = createEventDispatcher();

    function getStatusColor(status) {
        switch (status) {
            case 'active':
                return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200';
            case 'inactive':
                return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200';
            case 'checking':
                return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200';
            default:
                return 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200';
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

    async function checkHealth() {
        await serviceManager.checkServiceHealth(service.id);
    }

    function editService() {
        // TODO: Open edit service modal
        uiStore.showNotification({
            type: 'info',
            message: 'Edit service functionality coming soon',
        });
    }

    function deleteService() {
        if (confirm(`Are you sure you want to delete "${service.name}"?`)) {
            serviceManager.removeService(service.id);
        }
    }

    function testService() {
        window.location.href = `/services/${service.id}/test`;
    }

    function formatDate(dateString) {
        return new Date(dateString).toLocaleDateString();
    }
</script>

<div
    class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6 hover:shadow-lg transition-shadow"
>
    <!-- Header -->
    <div class="flex items-start justify-between mb-4">
        <div class="flex items-center space-x-3">
            <div
                class="w-10 h-10 bg-gray-100 dark:bg-gray-700 rounded-lg flex items-center justify-center"
            >
                <Server class="h-5 w-5 text-gray-600 dark:text-gray-400" />
            </div>

            <div>
                <h3 class="font-semibold text-gray-900 dark:text-white">{service.name}</h3>
                <p class="text-sm text-gray-600 dark:text-gray-400">
                    {service.description || 'No description'}
                </p>
            </div>
        </div>

        <div class="flex items-center space-x-2">
            <span
                class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium {getStatusColor(
                    service.status
                )}"
            >
                <svelte:component this={getStatusIcon(service.status)} class="h-3 w-3 mr-1" />
                {service.status || 'unknown'}
            </span>
        </div>
    </div>

    <!-- URL -->
    <div class="mb-4">
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-1">Base URL</p>
        <div class="flex items-center space-x-2">
            <p
                class="text-sm font-mono bg-gray-100 dark:bg-gray-700 px-2 py-1 rounded flex-1 truncate"
            >
                {service.baseUrl}
            </p>
            <Button
                size="sm"
                variant="ghost"
                on:click={() => window.open(service.baseUrl, '_blank')}
            >
                <ExternalLink class="h-3 w-3" />
            </Button>
        </div>
    </div>

    <!-- Metadata -->
    <div class="grid grid-cols-2 gap-4 mb-4 text-xs text-gray-600 dark:text-gray-400">
        <div>
            <p class="font-medium">Created</p>
            <p>{formatDate(service.createdAt)}</p>
        </div>
        <div>
            <p class="font-medium">Last Check</p>
            <p>{service.lastHealthCheck ? formatDate(service.lastHealthCheck) : 'Never'}</p>
        </div>
    </div>

    <!-- Actions -->
    <div
        class="flex items-center justify-between pt-4 border-t border-gray-200 dark:border-gray-700"
    >
        <div class="flex space-x-2">
            <Button size="sm" on:click={testService}>
                <TestTube class="h-3 w-3 mr-1" />
                Test
            </Button>

            <Button size="sm" variant="secondary" on:click={checkHealth}>
                <Activity class="h-3 w-3 mr-1" />
                Health Check
            </Button>
        </div>

        <div class="flex space-x-1">
            <Button size="sm" variant="ghost" on:click={editService}>
                <Settings class="h-3 w-3" />
            </Button>

            <Button size="sm" variant="ghost" on:click={deleteService}>
                <Trash2 class="h-3 w-3 text-red-600" />
            </Button>
        </div>
    </div>
</div>
