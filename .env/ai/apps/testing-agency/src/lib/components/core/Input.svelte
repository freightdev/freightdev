<!-- src/lib/components/core/Input.svelte -->
<script>
  import { createEventDispatcher } from 'svelte';

  const dispatch = createEventDispatcher();

  export let value = '';
  export let type = 'text';
  export let placeholder = '';
  export let label = '';
  export let error = '';
  export let disabled = false;
  export let required = false;
  export let id = '';

  const baseClasses = 'block w-full rounded-lg border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white shadow-sm focus:border-blue-500 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed';

  function handleInput(event) {
    value = event.target.value;
    dispatch('input', { value, event });
  }

  function handleChange(event) {
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

  <input
    {id}
    {type}
    {placeholder}
    {disabled}
    {required}
    {value}
    class="{baseClasses} {error ? 'border-red-300 focus:border-red-500 focus:ring-red-500' : ''}"
    on:input={handleInput}
    on:change={handleChange}
    on:blur
    on:focus
  />

  {#if error}
    <p class="text-sm text-red-600 dark:text-red-400">{error}</p>
  {/if}
</div>
