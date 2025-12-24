<!-- src/lib/components/testing/RequestBuilder.svelte -->
<script>
    import { Play, Plus, Trash2 } from 'lucide-svelte';
    import { createEventDispatcher, onMount } from 'svelte';

    import { serviceManager } from '$lib/services/serviceManager.js';
    import { services } from '$lib/stores/services.js';
    import Button from '../core/Button.svelte';
    import Input from '../core/Input.svelte';
    import Select from '../core/Select.svelte';

    const dispatch = createEventDispatcher();

    export let selectedServiceId = '';
    export let initialRequest = null;

    let request = {
        serviceId: '',
        method: 'GET',
        endpoint: '/',
        headers: {},
        params: {},
        body: '',
        bodyType: 'json',
        auth: {
            type: 'inherit',
        },
    };

    let activeTab = 'params'; // params, headers, body, auth
    let loading = false;

    const httpMethods = [
        { value: 'GET', label: 'GET' },
        { value: 'POST', label: 'POST' },
        { value: 'PUT', label: 'PUT' },
        { value: 'PATCH', label: 'PATCH' },
        { value: 'DELETE', label: 'DELETE' },
        { value: 'HEAD', label: 'HEAD' },
        { value: 'OPTIONS', label: 'OPTIONS' },
    ];

    const bodyTypes = [
        { value: 'json', label: 'JSON' },
        { value: 'text', label: 'Text' },
        { value: 'form', label: 'Form Data' },
        { value: 'none', label: 'No Body' },
    ];

    const authTypes = [
        { value: 'inherit', label: 'Inherit from Service' },
        { value: 'none', label: 'No Authentication' },
        { value: 'bearer', label: 'Bearer Token' },
        { value: 'apikey', label: 'API Key' },
        { value: 'basic', label: 'Basic Auth' },
    ];

    $: serviceOptions = $services.map(s => ({ value: s.id, label: s.name }));
    $: selectedService = $services.find(s => s.id === request.serviceId);
    $: fullUrl = selectedService
        ? serviceManager.buildEndpointUrl(selectedService.baseUrl, request.endpoint)
        : '';

    onMount(() => {
        if (selectedServiceId) {
            request.serviceId = selectedServiceId;
        }

        if (initialRequest) {
            request = { ...request, ...initialRequest };
        }
    });

    function addParam() {
        request.params = { ...request.params, '': '' };
    }

    function removeParam(key) {
        const newParams = { ...request.params };
        delete newParams[key];
        request.params = newParams;
    }

    function updateParamKey(oldKey, newKey) {
        if (oldKey !== newKey) {
            const newParams = { ...request.params };
            newParams[newKey] = newParams[oldKey] || '';
            delete newParams[oldKey];
            request.params = newParams;
        }
    }

    function updateParamValue(key, value) {
        request.params = { ...request.params, [key]: value };
    }

    function addHeader() {
        request.headers = { ...request.headers, '': '' };
    }

    function removeHeader(key) {
        const newHeaders = { ...request.headers };
        delete newHeaders[key];
        request.headers = newHeaders;
    }

    function updateHeaderKey(oldKey, newKey) {
        if (oldKey !== newKey) {
            const newHeaders = { ...request.headers };
            newHeaders[newKey] = newHeaders[oldKey] || '';
            delete newHeaders[oldKey];
            request.headers = newHeaders;
        }
    }

    function updateHeaderValue(key, value) {
        request.headers = { ...request.headers, [key]: value };
    }

    function validateRequest() {
        const errors = [];

        if (!request.serviceId) {
            errors.push('Please select a service');
        }

        if (!request.endpoint.trim()) {
            errors.push('Endpoint is required');
        }

        if (request.bodyType === 'json' && request.body.trim()) {
            try {
                JSON.parse(request.body);
            } catch (e) {
                errors.push('Invalid JSON in request body');
            }
        }

        return errors;
    }

    async function executeRequest() {
        const errors = validateRequest();
        if (errors.length > 0) {
            dispatch('error', { message: errors.join(', ') });
            return;
        }

        loading = true;
        dispatch('requestStart');

        try {
            const result = await serviceManager.testEndpoint(request.serviceId, request.endpoint, {
                method: request.method,
                headers: request.headers,
                params: request.params,
                body: request.bodyType === 'none' ? null : request.body,
                auth: request.auth.type === 'inherit' ? undefined : request.auth,
            });

            dispatch('response', result);
        } catch (error) {
            dispatch('error', { message: error.message });
        } finally {
            loading = false;
        }
    }

    function getBodyPlaceholder() {
        switch (request.bodyType) {
            case 'json':
                return '{\n  "key": "value"\n}';
            case 'form':
                return 'key1=value1&key2=value2';
            case 'text':
                return 'Raw text content';
            default:
                return '';
        }
    }
</script>

<div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
    <!-- Header -->
    <div class="p-4 border-b border-gray-200 dark:border-gray-700">
        <div class="flex items-center justify-between">
            <h2 class="text-lg font-semibold text-gray-900 dark:text-white">Request Builder</h2>
            <Button on:click={executeRequest} {loading}>
                <Play class="h-4 w-4 mr-2" />
                Send Request
            </Button>
        </div>
    </div>

    <div class="p-4 space-y-4">
        <!-- Service & Method Selection -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <Select
                label="Service"
                options={serviceOptions}
                bind:value={request.serviceId}
                placeholder="Select a service..."
                required
            />

            <Select label="Method" options={httpMethods} bind:value={request.method} />

            <Input
                label="Endpoint"
                placeholder="/api/users"
                bind:value={request.endpoint}
                required
            />
        </div>

        <!-- URL Preview -->
        {#if fullUrl}
            <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-3">
                <p class="text-sm text-gray-600 dark:text-gray-400 mb-1">Full URL:</p>
                <p class="font-mono text-sm break-all">{fullUrl}</p>
            </div>
        {/if}

        <!-- Tabs -->
        <div class="border-b border-gray-200 dark:border-gray-700">
            <nav class="-mb-px flex space-x-8">
                <button
                    class="py-2 px-1 border-b-2 font-medium text-sm {activeTab === 'params'
                        ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                        : 'border-transparent text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'}"
                    on:click={() => (activeTab = 'params')}
                >
                    Query Parameters
                </button>

                <button
                    class="py-2 px-1 border-b-2 font-medium text-sm {activeTab === 'headers'
                        ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                        : 'border-transparent text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'}"
                    on:click={() => (activeTab = 'headers')}
                >
                    Headers
                </button>

                <button
                    class="py-2 px-1 border-b-2 font-medium text-sm {activeTab === 'body'
                        ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                        : 'border-transparent text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'}"
                    on:click={() => (activeTab = 'body')}
                >
                    Request Body
                </button>

                <button
                    class="py-2 px-1 border-b-2 font-medium text-sm {activeTab === 'auth'
                        ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                        : 'border-transparent text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'}"
                    on:click={() => (activeTab = 'auth')}
                >
                    Authentication
                </button>
            </nav>
        </div>

        <!-- Tab Content -->
        <div class="min-h-[200px]">
            {#if activeTab === 'params'}
                <div class="space-y-3">
                    <div class="flex items-center justify-between">
                        <h3 class="text-sm font-medium text-gray-900 dark:text-white">
                            Query Parameters
                        </h3>
                        <Button size="sm" variant="secondary" on:click={addParam}>
                            <Plus class="h-3 w-3 mr-1" />
                            Add Parameter
                        </Button>
                    </div>

                    {#each Object.entries(request.params) as [key, value]}
                        <div class="grid grid-cols-2 gap-4">
                            <Input
                                placeholder="Parameter name"
                                value={key}
                                on:input={e => updateParamKey(key, e.detail.value)}
                            />
                            <div class="flex space-x-2">
                                <Input
                                    placeholder="Parameter value"
                                    {value}
                                    on:input={e => updateParamValue(key, e.detail.value)}
                                />
                                <Button size="sm" variant="ghost" on:click={() => removeParam(key)}>
                                    <Trash2 class="h-3 w-3 text-red-600" />
                                </Button>
                            </div>
                        </div>
                    {/each}

                    {#if Object.keys(request.params).length === 0}
                        <p class="text-gray-500 dark:text-gray-400 text-center py-8">
                            No query parameters added
                        </p>
                    {/if}
                </div>
            {:else if activeTab === 'headers'}
                <div class="space-y-3">
                    <div class="flex items-center justify-between">
                        <h3 class="text-sm font-medium text-gray-900 dark:text-white">
                            Request Headers
                        </h3>
                        <Button size="sm" variant="secondary" on:click={addHeader}>
                            <Plus class="h-3 w-3 mr-1" />
                            Add Header
                        </Button>
                    </div>

                    {#each Object.entries(request.headers) as [key, value]}
                        <div class="grid grid-cols-2 gap-4">
                            <Input
                                placeholder="Header name"
                                value={key}
                                on:input={e => updateHeaderKey(key, e.detail.value)}
                            />
                            <div class="flex space-x-2">
                                <Input
                                    placeholder="Header value"
                                    {value}
                                    on:input={e => updateHeaderValue(key, e.detail.value)}
                                />
                                <Button
                                    size="sm"
                                    variant="ghost"
                                    on:click={() => removeHeader(key)}
                                >
                                    <Trash2 class="h-3 w-3 text-red-600" />
                                </Button>
                            </div>
                        </div>
                    {/each}

                    {#if Object.keys(request.headers).length === 0}
                        <p class="text-gray-500 dark:text-gray-400 text-center py-8">
                            No custom headers added
                        </p>
                    {/if}
                </div>
            {:else if activeTab === 'body'}
                <div class="space-y-4">
                    <div class="flex items-center justify-between">
                        <h3 class="text-sm font-medium text-gray-900 dark:text-white">
                            Request Body
                        </h3>
                        <Select options={bodyTypes} bind:value={request.bodyType} />
                    </div>

                    {#if request.bodyType !== 'none'}
                        <div
                            class="border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden"
                        >
                            <textarea
                                class="w-full h-40 p-3 bg-gray-50 dark:bg-gray-700 font-mono text-sm resize-none focus:outline-none focus:ring-2 focus:ring-blue-500 text-gray-900 dark:text-gray-100"
                                placeholder={getBodyPlaceholder()}
                                bind:value={request.body}
                            ></textarea>
                        </div>
                    {:else}
                        <p class="text-gray-500 dark:text-gray-400 text-center py-8">
                            No request body
                        </p>
                    {/if}
                </div>
            {:else if activeTab === 'auth'}
                <div class="space-y-4">
                    <h3 class="text-sm font-medium text-gray-900 dark:text-white">
                        Authentication Override
                    </h3>

                    <Select
                        label="Authentication Type"
                        options={authTypes}
                        bind:value={request.auth.type}
                    />

                    {#if request.auth.type === 'bearer'}
                        <Input
                            label="Bearer Token"
                            placeholder="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
                            bind:value={request.auth.token}
                        />
                    {:else if request.auth.type === 'apikey'}
                        <div class="grid grid-cols-2 gap-4">
                            <Input
                                label="Header Name"
                                placeholder="X-API-Key"
                                bind:value={request.auth.key}
                            />
                            <Input
                                label="API Key Value"
                                placeholder="your-api-key-here"
                                bind:value={request.auth.value}
                            />
                        </div>
                    {:else if request.auth.type === 'basic'}
                        <div class="grid grid-cols-2 gap-4">
                            <Input label="Username" bind:value={request.auth.username} />
                            <Input
                                label="Password"
                                type="password"
                                bind:value={request.auth.password}
                            />
                        </div>
                    {:else if request.auth.type === 'inherit'}
                        <p class="text-gray-600 dark:text-gray-400 text-sm">
                            Using authentication configuration from the selected service.
                        </p>
                    {:else}
                        <p class="text-gray-600 dark:text-gray-400 text-sm">
                            No authentication will be used for this request.
                        </p>
                    {/if}
                </div>
            {/if}
        </div>
    </div>
</div>
