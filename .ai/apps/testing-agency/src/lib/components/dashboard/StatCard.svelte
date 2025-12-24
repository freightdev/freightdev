<!-- src/lib/components/dashboard/StatCard.svelte -->
<script>
    export let title;
    export let value;
    export let icon;
    export let color = 'blue';
    export let description = '';

    const colorClasses = {
        blue: 'text-blue-600 dark:text-blue-400',
        green: 'text-green-600 dark:text-green-400',
        red: 'text-red-600 dark:text-red-400',
        yellow: 'text-yellow-600 dark:text-yellow-400',
    };
</script>

<div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
    <div class="flex items-center">
        <div class="flex-shrink-0">
            <div
                class="w-8 h-8 bg-gray-100 dark:bg-gray-700 rounded-lg flex items-center justify-center"
            >
                <svelte:component this={icon} class="h-4 w-4 {colorClasses[color]}" />
            </div>
        </div>

        <div class="ml-4 flex-1">
            <p class="text-sm font-medium text-gray-600 dark:text-gray-400">{title}</p>
            <p class="text-2xl font-bold text-gray-900 dark:text-white">{value}</p>
            {#if description}
                <p class="text-xs text-gray-500 dark:text-gray-500 mt-1">{description}</p>
            {/if}
        </div>
    </div>
</div>
