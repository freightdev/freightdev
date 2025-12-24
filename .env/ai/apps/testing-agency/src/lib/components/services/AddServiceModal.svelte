<!-- src/lib/components/services/AddServiceModal.svelte -->
<script>
    import { Plus, Server } from 'lucide-svelte';
    import { createEventDispatcher } from 'svelte';

    import { serviceManager } from '$lib/services/serviceManager.js';
    import Button from '../core/Button.svelte';
    import Input from '../core/Input.svelte';
    import Select from '../core/Select.svelte';

    const dispatch = createEventDispatcher();

    let formData = {
        name: '',
        baseUrl: '',
        description: '',
        auth: {
            type: 'none',
        },
        headers: {},
    };

    let errors = {};
    let loading = false;

    const authTypes = [
        { value: 'none', label: 'No Authentication' },
        { value: 'bearer', label: 'Bearer Token' },
        { value: 'apikey', label: 'API Key' },
        { value: 'basic', label: 'Basic Auth' },
    ];

    function validateForm() {
        errors = {};

        if (!formData.name.trim()) {
            errors.name = 'Service name is required';
        }

        if (!formData.baseUrl.trim()) {
            errors.baseUrl = 'Base URL is required';
        } else if (!isValidUrl(formData.baseUrl)) {
            errors.baseUrl = 'Please enter a valid URL';
        }

        if (formData.auth.type === 'bearer' && !formData.auth.token) {
            errors.authToken = 'Bearer token is required';
        }

        if (formData.auth.type === 'apikey' && (!formData.auth.key || !formData.auth.value)) {
            errors.authKey = 'API key name and value are required';
        }

        if (
            formData.auth.type === 'basic' &&
            (!formData.auth.username || !formData.auth.password)
        ) {
            errors.authBasic = 'Username and password are required';
        }

        return Object.keys(errors).length === 0;
    }

    function isValidUrl(string) {
        try {
            new URL(string);
            return true;
        } catch (_) {
            return false;
        }
    }

    async function handleSubmit() {
        if (!validateForm()) return;

        loading = true;

        try {
            await serviceManager.addService(formData);
            dispatch('close');
        } catch (error) {
            errors.submit = error.message;
        } finally {
            loading = false;
        }
    }

    function addCustomHeader() {
        formData.headers = { ...formData.headers, '': '' };
    }

    function removeCustomHeader(key) {
        const newHeaders = { ...formData.headers };
        delete newHeaders[key];
        formData.headers = newHeaders;
    }

    function updateHeaderKey(oldKey, newKey) {
        const newHeaders = { ...formData.headers };
        if (oldKey !== newKey) {
            newHeaders[newKey] = newHeaders[oldKey] || '';
            delete newHeaders[oldKey];
            formData.headers = newHeaders;
        }
    }

    function updateHeaderValue(key, value) {
        formData.headers = { ...formData.headers, [key]: value };
    }
</script>

<form on:submit|preventDefault={handleSubmit} class="space-y-6">
    <!-- Basic Information -->
    <div class="space-y-4">
        <h3 class="text-lg font-medium text-gray-900 dark:text-white">Basic Information</h3>

        <Input
            label="Service Name"
            placeholder="e.g., User Service"
            bind:value={formData.name}
            error={errors.name}
            required
        />

        <Input
            label="Base URL"
            placeholder="https://api.example.com"
            bind:value={formData.baseUrl}
            error={errors.baseUrl}
            required
        />

        <Input
            label="Description"
            placeholder="Brief description of the service"
            bind:value={formData.description}
        />
    </div>

    <!-- Authentication -->
    <div class="space-y-4">
        <h3 class="text-lg font-medium text-gray-900 dark:text-white">Authentication</h3>

        <Select label="Authentication Type" options={authTypes} bind:value={formData.auth.type} />

        {#if formData.auth.type === 'bearer'}
            <Input
                label="Bearer Token"
                placeholder="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
                bind:value={formData.auth.token}
                error={errors.authToken}
                required
            />
        {:else if formData.auth.type === 'apikey'}
            <div class="grid grid-cols-2 gap-4">
                <Input
                    label="Header Name"
                    placeholder="X-API-Key"
                    bind:value={formData.auth.key}
                    error={errors.authKey}
                    required
                />
                <Input
                    label="API Key Value"
                    placeholder="your-api-key-here"
                    bind:value={formData.auth.value}
                    error={errors.authKey}
                    required
                />
            </div>
        {:else if formData.auth.type === 'basic'}
            <div class="grid grid-cols-2 gap-4">
                <Input
                    label="Username"
                    bind:value={formData.auth.username}
                    error={errors.authBasic}
                    required
                />
                <Input
                    label="Password"
                    type="password"
                    bind:value={formData.auth.password}
                    error={errors.authBasic}
                    required
                />
            </div>
        {/if}
    </div>

    <!-- Custom Headers -->
    <div class="space-y-4">
        <div class="flex items-center justify-between">
            <h3 class="text-lg font-medium text-gray-900 dark:text-white">Custom Headers</h3>
            <Button type="button" size="sm" variant="secondary" on:click={addCustomHeader}>
                <Plus class="h-3 w-3 mr-1" />
                Add Header
            </Button>
        </div>

        {#each Object.entries(formData.headers) as [key, value], index}
            <div class="grid grid-cols-2 gap-4">
                <Input
                    placeholder="Header Name"
                    value={key}
                    on:input={e => updateHeaderKey(key, e.detail.value)}
                />
                <div class="flex space-x-2">
                    <Input
                        placeholder="Header Value"
                        {value}
                        on:input={e => updateHeaderValue(key, e.detail.value)}
                    />
                    <Button
                        type="button"
                        size="sm"
                        variant="ghost"
                        on:click={() => removeCustomHeader(key)}
                    >
                        <Trash2 class="h-3 w-3 text-red-600" />
                    </Button>
                </div>
            </div>
        {/each}
    </div>

    <!-- Error Display -->
    {#if errors.submit}
        <div
            class="bg-red-50 dark:bg-red-900 border border-red-200 dark:border-red-700 rounded-lg p-4"
        >
            <p class="text-sm text-red-600 dark:text-red-400">{errors.submit}</p>
        </div>
    {/if}

    <!-- Form Actions -->
    <div class="flex justify-end space-x-3 pt-6 border-t border-gray-200 dark:border-gray-700">
        <Button type="button" variant="secondary" on:click={() => dispatch('close')}>Cancel</Button>

        <Button type="submit" {loading}>
            <Server class="h-4 w-4 mr-2" />
            Add Service
        </Button>
    </div>
</form>
