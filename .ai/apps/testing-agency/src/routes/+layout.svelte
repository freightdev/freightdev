<!-- src/routes/+layout.svelte -->
<script>
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import Header from '$lib/components/layout/Header.svelte';
  import Sidebar from '$lib/components/layout/Sidebar.svelte';
  import NotificationContainer from '$lib/components/core/NotificationContainer.svelte';
  import Modal from '$lib/components/core/Modal.svelte';

  import { sidebarOpen, theme } from '$lib/stores/ui.js';
  import { serviceManager } from '$lib/services/serviceManager.js';

  import '../app.css';

  onMount(() => {
    // Initialize service manager
    serviceManager.initialize();

    // Load theme from localStorage
    const savedTheme = localStorage.getItem('microservices-test-suite-theme') || 'light';
    theme.set(savedTheme);

    // Apply theme to document
    theme.subscribe(value => {
      document.documentElement.setAttribute('data-theme', value);
      localStorage.setItem('microservices-test-suite-theme', value);
    });
  });
</script>

<div class="min-h-screen bg-gray-50 dark:bg-gray-900 transition-colors duration-200">
  <!-- Header -->
  <Header />

  <div class="flex pt-16">
    <!-- Sidebar -->
    {#if $sidebarOpen}
      <Sidebar />
    {/if}

    <!-- Main Content -->
    <main class="flex-1 transition-all duration-200 {$sidebarOpen ? 'ml-64' : 'ml-0'}">
      <div class="p-6">
        <slot />
      </div>
    </main>
  </div>

  <!-- Global Notifications -->
  <NotificationContainer />

  <!-- Global Modal -->
  <Modal />
</div>
