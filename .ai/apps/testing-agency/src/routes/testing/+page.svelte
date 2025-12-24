<!-- src/routes/testing/+page.svelte - Enhanced -->
<script>
    import { Save, Server } from 'lucide-svelte';
    import { onMount } from 'svelte';

    import Button from '$lib/components/core/Button.svelte';
    import EnvironmentSelector from '$lib/components/testing/EnvironmentSelector.svelte';
    import RequestBuilder from '$lib/components/testing/RequestBuilder.svelte';
    import RequestHistory from '$lib/components/testing/RequestHistory.svelte';
    import RequestTemplates from '$lib/components/testing/RequestTemplates.svelte';
    import ResponseAssertion from '$lib/components/testing/ResponseAssertion.svelte';
    import ResponseViewer from '$lib/components/testing/ResponseViewer.svelte';

    import { services } from '$lib/stores/services.js';
    import { uiStore } from '$lib/stores/ui.js';

    let response = null;
    let error = null;
    let loading = false;
    let selectedServiceId = '';
    let assertions = [];
    let assertionResults = [];
    let requestBuilderRef;

    onMount(() => {
        if ($services.length > 0) {
            selectedServiceId = $services[0].id;
        }
    });

    function handleResponse(event) {
        response = event.detail.response;
        error = event.detail.error;
        loading = false;

        // Auto-run assertions if any exist
        if (assertions.length > 0) {
            runAssertions();
        }
    }

    function handleError(event) {
        error = event.detail;
        response = null;
        loading = false;

        uiStore.showNotification({
            type: 'error',
            message: event.detail.message,
        });
    }

    function handleRequestStart() {
        loading = true;
        error = null;
        response = null;
    }

    function applyTemplate(template) {
        // Apply template to request builder
        if (requestBuilderRef) {
            requestBuilderRef.applyTemplate(template);
        }
    }

    function runAssertions() {
        if (!response) return;
        // Assertion logic would be handled by ResponseAssertion component
    }

    function handleAssertionResults(event) {
        assertionResults = event.detail;

        const passed = assertionResults.filter(r => r.passed).length;
        const total = assertionResults.length;

        uiStore.showNotification({
            type: passed === total ? 'success' : 'warning',
            message: `Assertions: ${passed}/${total} passed`,
        });
    }
</script>

<svelte:head>
    <title>Testing Playground - Microservices Test Suite</title>
</svelte:head>

<div class="space-y-6">
    <!-- Page Header -->
    <div class="flex items-center justify-between">
        <div>
            <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Testing Playground</h1>
            <p class="text-gray-600 dark:text-gray-400">
                Build and execute HTTP requests with advanced testing capabilities
            </p>
        </div>

        <div class="flex items-center space-x-3">
            <EnvironmentSelector />

            <Button href="/test-suites" variant="secondary">
                <Save class="h-4 w-4 mr-2" />
                Save as Test
            </Button>

            <Button href="/services" variant="secondary">
                <Server class="h-4 w-4 mr-2" />
                Manage Services
            </Button>
        </div>
    </div>

    {#if $services.length === 0}
        <div class="text-center py-12">
            <Server class="h-16 w-16 text-gray-400 mx-auto mb-4" />
            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-2">
                No Services Configured
            </h3>
            <p class="text-gray-600 dark:text-gray-400 mb-6">
                Add a service first to start testing your APIs
            </p>
            <Button href="/services">
                <Server class="h-4 w-4 mr-2" />
                Add Your First Service
            </Button>
        </div>
    {:else}
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <!-- Left Column - Templates & History -->
            <div class="space-y-6">
                <RequestTemplates on:apply={applyTemplate} />
                <RequestHistory />
            </div>

            <!-- Middle Column - Request Builder -->
            <div>
                <RequestBuilder
                    bind:this={requestBuilderRef}
                    {selectedServiceId}
                    on:response={handleResponse}
                    on:error={handleError}
                    on:requestStart={handleRequestStart}
                />
            </div>

            <!-- Right Column - Response & Assertions -->
            <div class="space-y-6">
                <ResponseViewer {response} {error} {loading} />
                <ResponseAssertion {response} bind:assertions on:results={handleAssertionResults} />
            </div>
        </div>
    {/if}
</div>
