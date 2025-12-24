<!-- src/routes/+page.svelte - Main Dashboard -->
<script>
    import { Activity, CheckCircle, Server, TestTube, XCircle } from 'lucide-svelte';
    import { onMount } from 'svelte';

    import Button from '$lib/components/core/Button.svelte';
    import RecentActivity from '$lib/components/dashboard/RecentActivity.svelte';
    import ServiceOverview from '$lib/components/dashboard/ServiceOverview.svelte';
    import StatCard from '$lib/components/dashboard/StatCard.svelte';

    import { httpClient } from '$lib/services/httpClient.js';
    import { activeServices, services } from '$lib/stores/services.js';
    import { testStats } from '$lib/stores/tests.js';

    let requestHistory = [];

    onMount(() => {
        requestHistory = httpClient.getHistory().slice(0, 10);
    });

    $: inactiveServices = $services.length - $activeServices.length;
</script>

<svelte:head>
    <title>Dashboard - Microservices Test Suite</title>
</svelte:head>

<div class="space-y-6">
    <!-- Page Header -->
    <div class="flex items-center justify-between">
        <div>
            <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Dashboard</h1>
            <p class="text-gray-600 dark:text-gray-400">Monitor and test your microservices</p>
        </div>

        <div class="flex space-x-3">
            <Button href="/services" variant="secondary">
                <Server class="h-4 w-4 mr-2" />
                Manage Services
            </Button>
            <Button href="/testing">
                <TestTube class="h-4 w-4 mr-2" />
                Start Testing
            </Button>
        </div>
    </div>

    <!-- Stats Overview -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
            title="Active Services"
            value={$activeServices.length}
            icon={Server}
            color="green"
            description={`${inactiveServices} inactive`}
        />

        <StatCard
            title="Total Tests"
            value={$testStats.total}
            icon={TestTube}
            color="blue"
            description={`${$testStats.successRate}% success rate`}
        />

        <StatCard
            title="Passed Tests"
            value={$testStats.passed}
            icon={CheckCircle}
            color="green"
            description="Last 24 hours"
        />

        <StatCard
            title="Failed Tests"
            value={$testStats.failed}
            icon={XCircle}
            color="red"
            description="Require attention"
        />
    </div>

    <!-- Main Content Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Services Overview -->
        <div class="lg:col-span-2">
            <ServiceOverview />
        </div>

        <!-- Recent Activity -->
        <div class="lg:col-span-1">
            <RecentActivity {requestHistory} />
        </div>
    </div>

    <!-- Quick Actions -->
    <div
        class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6"
    >
        <h2 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Quick Actions</h2>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <Button href="/services" variant="secondary" class="justify-start">
                <Server class="h-4 w-4 mr-3" />
                Add New Service
            </Button>

            <Button href="/test-suites" variant="secondary" class="justify-start">
                <TestTube class="h-4 w-4 mr-3" />
                Create Test Suite
            </Button>

            <Button href="/testing" variant="secondary" class="justify-start">
                <Activity class="h-4 w-4 mr-3" />
                Run Quick Test
            </Button>
        </div>
    </div>
</div>
