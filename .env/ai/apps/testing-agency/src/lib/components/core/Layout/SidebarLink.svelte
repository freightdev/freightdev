<!-- src/lib/components/layout/SidebarLink.svelte -->
<script>
  import { page } from '$app/stores';

  export let href;
  export let icon;
  export let label;
  export let badge = null;

  $: isActive = $page.url.pathname === href || ($page.url.pathname.startsWith(href) && href !== '/');
</script>

<a
  {href}
  class="flex items-center justify-between w-full px-3 py-2 text-sm font-medium rounded-lg transition-colors duration-200 {
    isActive
      ? 'bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300'
      : 'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700'
  }"
>
  <div class="flex items-center space-x-3">
    <svelte:component this={icon} class="h-4 w-4 flex-shrink-0" />
    <span>{label}</span>
  </div>

  {#if badge !== null}
    <span class="inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-white bg-blue-600 rounded-full">
      {badge}
    </span>
  {/if}
</a>
