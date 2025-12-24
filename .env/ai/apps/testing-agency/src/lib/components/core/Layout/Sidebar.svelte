k<!-- src/lib/components/layout/Sidebar.svelte -->
<script>
  import { page } from '$app/stores';
  import {
    Home,
    Server,
    TestTube,
    Activity,
    Settings,
    FileText,k
    Play,
    BarChart3,
    Shield,
    Monitor
  } from 'lucide-svelte';
  import SidebarLink from './SidebarLink.svelte';
  import SidebarSection from './SidebarSection.svelte';
  import { services, activeServices } from '$lib/stores/services.js';
  import { testSuites } from '$lib/stores/tests.js';
</script>

<aside class="w-64 bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700 fixed left-0 top-16 bottom-0 z-40 overflow-y-auto">
  <nav class="p-4 space-y-2">
    <!-- Main Navigation -->
    <SidebarSection title="Main">
      <SidebarLink href="/" icon={Home} label="Dashboard" />
      <SidebarLink href="/services" icon={Server} label="Services" badge={$services.length} />
      <SidebarLink href="/test-suites" icon={TestTube} label="Test Suites" badge={$testSuites.length} />
      <SidebarLink href="/testing" icon={Play} label="Testing Playground" />
    </SidebarSection>

    <!-- Monitoring & Analytics -->
    <SidebarSection title="Monitoring">
      <SidebarLink href="/monitoring" icon={Monitor} label="Dashboard" />
      <SidebarLink href="/monitoring/metrics" icon={BarChart3} label="Metrics" />
      <SidebarLink href="/monitoring/logs" icon={FileText} label="Logs" />
    </SidebarSection>

    <!-- Advanced Testing -->
    <SidebarSection title="Advanced">
      <SidebarLink href="/performance" icon={Activity} label="Performance" />
      <SidebarLink href="/security" icon={Shield} label="Security Testing" />
    </SidebarSection>

    <!-- Configuration -->
    <SidebarSection title="Configuration">
      <SidebarLink href="/configuration" icon={Settings} label="Settings" />
    </SidebarSection>

    <!-- Quick Stats -->
    <div class="mt-8 p-4 bg-gray-50 dark:bg-gray-700 rounded-lg">
      <h3 class="text-sm font-medium text-gray-900 dark:text-white mb-2">Quick Stats</h3>
      <div class="space-y-2 text-xs">
        <div class="flex justify-between">
          <span class="text-gray-600 dark:text-gray-400">Active Services</span>
          <span class="font-medium text-green-600 dark:text-green-400">{$activeServices.length}</span>
        </div>
        <div class="flex justify-between">
          <span class="text-gray-600 dark:text-gray-400">Total Tests</span>
          <span class="font-medium text-blue-600 dark:text-blue-400">{$testSuites.reduce((sum, suite) => sum + (suite.tests?.length || 0), 0)}</span>
        </div>
      </div>
    </div>
  </nav>
</aside>
