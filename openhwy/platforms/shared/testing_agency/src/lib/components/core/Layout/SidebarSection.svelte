<!-- src/lib/components/layout/SidebarSection.svelte -->
<script>
  export let title;
</script>

<div class="mb-4">
  <h3 class="px-3 mb-2 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
    {title}
  </h3>
  <div class="space-y-1">
    <slot />
  </div>
</div>
