// src/lib/components/testing/RequestTemplates.svelte
<script>
  import { createEventDispatcher } from 'svelte';
  import { Template, ChevronRight } from 'lucide-svelte';
  import Button from '../core/Button.svelte';
  import { REQUEST_TEMPLATES } from '$lib/services/requestTemplates.js';

  const dispatch = createEventDispatcher();

  function applyTemplate(template) {
    dispatch('apply', template);
  }
</script>

<div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
  <div class="flex items-center mb-4">
    <Template class="h-5 w-5 text-blue-600 mr-2" />
    <h3 class="font-medium text-gray-900 dark:text-white">Request Templates</h3>
  </div>

  <div class="space-y-3">
    {#each Object.entries(REQUEST_TEMPLATES) as [category, templates]}
      <div>
        <h4 class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2 capitalize">
          {category} Service
        </h4>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
          {#each Object.entries(templates) as [key, template]}
            <button
              class="text-left p-2 text-sm rounded-md border border-gray-200 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors flex items-center justify-between group"
              on:click={() => applyTemplate(template)}
            >
              <span class="text-gray-900 dark:text-white">{template.name}</span>
              <ChevronRight class="h-3 w-3 text-gray-400 group-hover:text-gray-600 dark:group-hover:text-gray-300" />
            </button>
          {/each}
        </div>
      </div>
    {/each}
  </div>
</div>
