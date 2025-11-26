<!-- src/lib/components/layout/Header.svelte -->
<script>
  import { Menu, Bell, Settings, User, Moon, Sun } from 'lucide-svelte';
  import { sidebarOpen, theme, uiStore } from '$lib/stores/ui.js';
  import Button from '../core/Button.svelte';

  function toggleSidebar() {
    uiStore.toggleSidebar();
  }

  function toggleTheme() {
    theme.update(current => current === 'light' ? 'dark' : 'light');
  }
</script>

<header class="bg-white dark:bg-gray-800 shadow-sm border-b border-gray-200 dark:border-gray-700 h-16 fixed top-0 left-0 right-0 z-50">
  <div class="flex items-center justify-between h-full px-4">
    <!-- Left Section -->
    <div class="flex items-center space-x-4">
      <Button variant="ghost" size="sm" on:click={toggleSidebar}>
        <Menu class="h-5 w-5" />
      </Button>

      <div class="flex items-center space-x-2">
        <div class="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
          <span class="text-white font-bold text-sm">MS</span>
        </div>
        <h1 class="text-xl font-semibold text-gray-900 dark:text-white">
          Microservices Test Suite
        </h1>
      </div>
    </div>

    <!-- Right Section -->
    <div class="flex items-center space-x-3">
      <Button variant="ghost" size="sm" on:click={toggleTheme}>
        {#if $theme === 'light'}
          <Moon class="h-4 w-4" />
        {:else}
          <Sun class="h-4 w-4" />
        {/if}
      </Button>

      <Button variant="ghost" size="sm">
        <Bell class="h-4 w-4" />
      </Button>

      <Button variant="ghost" size="sm">
        <Settings class="h-4 w-4" />
      </Button>

      <div class="w-8 h-8 bg-gray-300 dark:bg-gray-600 rounded-full flex items-center justify-center">
        <User class="h-4 w-4 text-gray-600 dark:text-gray-300" />
      </div>
    </div>
  </div>
</header>
