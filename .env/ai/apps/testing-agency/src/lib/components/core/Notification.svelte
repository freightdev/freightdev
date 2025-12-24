<!-- src/lib/components/core/Notification.svelte -->
<script>
    import { notifications } from '$lib/stores/ui.js';
    import { AlertCircle, CheckCircle, Info, X } from 'lucide-svelte';
    import { onMount } from 'svelte';
    import Button from './Button.svelte';

    export let notification;

    const typeIcons = {
        success: CheckCircle,
        error: AlertCircle,
        warning: AlertCircle,
        info: Info,
    };

    const typeColors = {
        success:
            'bg-green-50 border-green-200 text-green-800 dark:bg-green-900 dark:border-green-700 dark:text-green-200',
        error: 'bg-red-50 border-red-200 text-red-800 dark:bg-red-900 dark:border-red-700 dark:text-red-200',
        warning:
            'bg-yellow-50 border-yellow-200 text-yellow-800 dark:bg-yellow-900 dark:border-yellow-700 dark:text-yellow-200',
        info: 'bg-blue-50 border-blue-200 text-blue-800 dark:bg-blue-900 dark:border-blue-700 dark:text-blue-200',
    };

    function removeNotification() {
        notifications.update(list => list.filter(n => n.id !== notification.id));
    }

    onMount(() => {
        const timer = setTimeout(removeNotification, 5000);
        return () => clearTimeout(timer);
    });
</script>

<div
    class="max-w-sm w-full bg-white dark:bg-gray-800 shadow-lg rounded-lg border {typeColors[
        notification.type
    ]} animate-in slide-in-from-right duration-300"
>
    <div class="p-4">
        <div class="flex items-start">
            <div class="flex-shrink-0">
                <svelte:component this={typeIcons[notification.type]} class="h-5 w-5" />
            </div>

            <div class="ml-3 w-0 flex-1">
                <p class="text-sm font-medium">
                    {notification.message}
                </p>
                {#if notification.description}
                    <p class="mt-1 text-sm opacity-75">
                        {notification.description}
                    </p>
                {/if}
            </div>

            <div class="ml-4 flex-shrink-0 flex">
                <Button variant="ghost" size="sm" on:click={removeNotification}>
                    <X class="h-4 w-4" />
                </Button>
            </div>
        </div>
    </div>
</div>
