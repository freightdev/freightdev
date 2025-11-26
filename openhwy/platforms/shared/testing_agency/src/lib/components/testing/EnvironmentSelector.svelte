<script>
    import { currentEnvironment, environments } from '$lib/stores/services.js';
    import { ChevronDown, Globe } from 'lucide-svelte';

    let showDropdown = false;

    const envColors = {
        development: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
        staging: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200',
        production: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
    };

    function selectEnvironment(env) {
        currentEnvironment.set(env);
        showDropdown = false;
    }
</script>

// src/lib/components/testing/EnvironmentSelector.svelte
<div class="relative">
    <button
        class="inline-flex items-center px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-sm font-medium text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-600"
        on:click={() => (showDropdown = !showDropdown)}
    >
        <Globe class="h-4 w-4 mr-2" />
        <span class="capitalize">{$currentEnvironment}</span>
        <ChevronDown class="h-4 w-4 ml-2" />
    </button>

    {#if showDropdown}
        <div
            class="absolute z-10 mt-1 w-48 bg-white dark:bg-gray-800 shadow-lg rounded-md py-1 border border-gray-200 dark:border-gray-600"
        >
            {#each $environments as env}
                <button
                    class="w-full text-left px-4 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 flex items-center justify-between"
                    on:click={() => selectEnvironment(env)}
                >
                    <span class="capitalize">{env}</span>
                    <span
                        class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium {envColors[
                            env
                        ]}"
                    >
                        {env.slice(0, 3)}
                    </span>
                </button>
            {/each}
        </div>
    {/if}
</div>
