<script>
    import { CheckCircle, Plus, Trash2, XCircle } from 'lucide-svelte';
    import { createEventDispatcher } from 'svelte';
    import Button from '../core/Button.svelte';
    import Input from '../core/Input.svelte';
    import Select from '../core/Select.svelte';

    const dispatch = createEventDispatcher();

    export let response = null;
    export let assertions = [];

    const assertionTypes = [
        { value: 'status_code', label: 'Status Code' },
        { value: 'response_time', label: 'Response Time (ms)' },
        { value: 'contains', label: 'Response Contains' },
        { value: 'json_path', label: 'JSON Path Equals' },
        { value: 'header_exists', label: 'Header Exists' },
        { value: 'not_null', label: 'Field Not Null' },
    ];

    function addAssertion() {
        assertions = [
            ...assertions,
            {
                id: Date.now(),
                type: 'status_code',
                expected: '200',
                path: '',
                description: '',
            },
        ];
    }

    function removeAssertion(id) {
        assertions = assertions.filter(a => a.id !== id);
    }

    function updateAssertion(id, field, value) {
        assertions = assertions.map(a => (a.id === id ? { ...a, [field]: value } : a));
    }

    function runAssertions() {
        if (!response) return;

        const results = assertions.map(assertion => {
            let passed = false;
            let actual = null;

            try {
                switch (assertion.type) {
                    case 'status_code':
                        actual = response.status;
                        passed = actual === parseInt(assertion.expected);
                        break;
                    case 'response_time':
                        actual = response.responseTime;
                        passed = actual <= parseInt(assertion.expected);
                        break;
                    case 'contains':
                        actual = JSON.stringify(response.data);
                        passed = actual.includes(assertion.expected);
                        break;
                    case 'json_path':
                        actual = getJsonPath(response.data, assertion.path);
                        passed = actual === assertion.expected;
                        break;
                    case 'header_exists':
                        passed = response.headers.hasOwnProperty(assertion.expected.toLowerCase());
                        actual = passed ? 'exists' : 'missing';
                        break;
                    case 'not_null':
                        actual = getJsonPath(response.data, assertion.path);
                        passed = actual !== null && actual !== undefined;
                        break;
                }
            } catch (error) {
                passed = false;
                actual = error.message;
            }

            return { ...assertion, passed, actual };
        });

        dispatch('results', results);
        return results;
    }

    function getJsonPath(obj, path) {
        return path
            .split('.')
            .reduce(
                (current, key) => (current && current[key] !== undefined ? current[key] : null),
                obj
            );
    }
</script>

// src/lib/components/testing/ResponseAssertion.svelte
<div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
    <div class="flex items-center justify-between mb-4">
        <h3 class="font-medium text-gray-900 dark:text-white">Response Assertions</h3>
        <div class="flex space-x-2">
            <Button size="sm" variant="secondary" on:click={addAssertion}>
                <Plus class="h-3 w-3 mr-1" />
                Add Assertion
            </Button>
            {#if response && assertions.length > 0}
                <Button size="sm" on:click={runAssertions}>
                    <CheckCircle class="h-3 w-3 mr-1" />
                    Test Assertions
                </Button>
            {/if}
        </div>
    </div>

    {#if assertions.length === 0}
        <p class="text-gray-500 dark:text-gray-400 text-center py-8">
            No assertions configured. Add assertions to validate responses automatically.
        </p>
    {:else}
        <div class="space-y-3">
            {#each assertions as assertion}
                <div class="border border-gray-200 dark:border-gray-600 rounded-lg p-3">
                    <div class="grid grid-cols-1 md:grid-cols-4 gap-3 mb-2">
                        <Select
                            options={assertionTypes}
                            bind:value={assertion.type}
                            on:change={e => updateAssertion(assertion.id, 'type', e.detail.value)}
                        />

                        {#if assertion.type === 'json_path' || assertion.type === 'not_null'}
                            <Input
                                placeholder="JSON path (e.g., data.user.id)"
                                value={assertion.path}
                                on:input={e =>
                                    updateAssertion(assertion.id, 'path', e.detail.value)}
                            />
                        {/if}

                        {#if assertion.type !== 'not_null'}
                            <Input
                                placeholder="Expected value"
                                value={assertion.expected}
                                on:input={e =>
                                    updateAssertion(assertion.id, 'expected', e.detail.value)}
                            />
                        {/if}

                        <div class="flex items-center space-x-2">
                            <Button
                                size="sm"
                                variant="ghost"
                                on:click={() => removeAssertion(assertion.id)}
                            >
                                <Trash2 class="h-3 w-3 text-red-600" />
                            </Button>

                            {#if assertion.passed !== undefined}
                                {#if assertion.passed}
                                    <CheckCircle class="h-4 w-4 text-green-600" />
                                {:else}
                                    <XCircle class="h-4 w-4 text-red-600" />
                                {/if}
                            {/if}
                        </div>
                    </div>

                    {#if assertion.passed !== undefined}
                        <div
                            class="text-xs {assertion.passed
                                ? 'text-green-600'
                                : 'text-red-600'} mt-2"
                        >
                            Expected: {assertion.expected} | Actual: {assertion.actual}
                        </div>
                    {/if}
                </div>
            {/each}
        </div>
    {/if}
</div>
