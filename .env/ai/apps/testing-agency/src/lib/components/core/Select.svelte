<!-- src/lib/components/core/Select.svelte -->
<script>
    import { ChevronDown } from 'lucide-svelte';
    import { createEventDispatcher } from 'svelte';

    const dispatch = createEventDispatcher();

    export let value = '';
    export let options = []; // Array of {value, label} objects
    export let placeholder = 'Select option...';
    export let label = '';
    export let error = '';
    export let disabled = false;
    export let required = false;
    export let id = '';

    const baseClasses =
        'block w-full rounded-lg border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white shadow-sm focus:border-blue-500 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed';

    function handleChange(event) {
        value = event.target.value;
        dispatch('change', { value, event });
    }
</script>

<div class="space-y-1">
    {#if label}
        <label for={id} class="block text-sm font-medium text-gray-700 dark:text-gray-300">
            {label}
            {#if required}
                <span class="text-red-500">*</span>
            {/if}
        </label>
    {/if}

    <div class="relative">
        <select
            {id}
            {disabled}
            {required}
            bind:value
            class="{baseClasses} {error
                ? 'border-red-300 focus:border-red-500 focus:ring-red-500'
                : ''} appearance-none pr-10"
            on:change={handleChange}
            on:blur
            on:focus
        >
            {#if placeholder}
                <option value="" disabled>{placeholder}</option>
            {/if}
            {#each options as option}
                <option value={option.value}>{option.label}</option>
            {/each}
        </select>

        <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
            <ChevronDown class="h-4 w-4 text-gray-400" />
        </div>
    </div>

    {#if error}
        <p class="text-sm text-red-600 dark:text-red-400">{error}</p>
    {/if}
</div>
