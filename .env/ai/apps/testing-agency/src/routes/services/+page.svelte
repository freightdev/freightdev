<!-- src/routes/services/+page.svelte - Services Management Page -->
<script>
    import Button from '$lib/components/core/Button.svelte';
    import Input from '$lib/components/core/Input.svelte';
    import AddServiceModal from '$lib/components/services/AddServiceModal.svelte';
    import ServiceCard from '$lib/components/services/ServiceCard.svelte';
    import { Plus, Search } from 'lucide-svelte';

    import { services } from '$lib/stores/services.js';
    import { uiStore } from '$lib/stores/ui.js';

    let searchQuery = '';
    let statusFilter = 'all';

    $: filteredServices = $services.filter(service => {
        const matchesSearch =
            service.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
            service.baseUrl.toLowerCase().includes(searchQuery.toLowerCase());
        const matchesStatus = statusFilter === 'all' || service.status === statusFilter;
        return matchesSearch && matchesStatus;
    });

    function openAddServiceModal() {
        uiStore.openModal(AddServiceModal, { title: 'Add New Service' });
    }
</script>

<svelte:head>
    <title>Services - Microservices Test Suite</title>
</svelte:head>

<div class="space-y-6">
    <!-- Page Header -->
    <div class="flex items-center justify-between">
        <div>
            <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Services</h1>
            <p class="text-gray-600 dark:text-gray-400">Manage your microservices configuration</p>
        </div>

        <Button on:click={openAddServiceModal}>
            <Plus class="h-4 w-4 mr-2" />
            Add Service
        </Button>
    </div>

    <!-- Filters and Search -->
    <div
        class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4"
    >
        <div class="flex flex-col sm:flex-row gap-4">
            <div class="flex-1">
                <Input placeholder="Search services..." bind:value={searchQuery}>
                    <Search slot="icon" class="h-4 w-4" />
                </Input>
            </div>

            <div class="sm:w-48">
                <select
                    bind:value={statusFilter}
                    class="block w-full rounded-lg border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                >
                    <option value="all">All Status</option>
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                    <option value="checking">Checking</option>
                    <option value="unknown">Unknown</option>
                </select>
            </div>
        </div>
    </div>

    <!-- Services Grid -->
    {#if filteredServices.length === 0}
        <div class="text-center py-12">
            <Server class="h-16 w-16 text-gray-400 mx-auto mb-4" />
            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-2">
                {searchQuery ? 'No services found' : 'No services configured'}
            </h3>
            <p class="text-gray-600 dark:text-gray-400 mb-6">
                {searchQuery
                    ? 'Try adjusting your search criteria'
                    : 'Add your first microservice to get started with testing'}
            </p>
            {#if !searchQuery}
                <Button on:click={openAddServiceModal}>
                    <Plus class="h-4 w-4 mr-2" />
                    Add Your First Service
                </Button>
            {/if}
        </div>
    {:else}
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {#each filteredServices as service}
                <ServiceCard {service} />
            {/each}
        </div>
    {/if}
</div>
