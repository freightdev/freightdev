<script>
    import { mockDataGenerator } from '$lib/services/mockDataGenerator.js';
    import { Copy, Database, RefreshCw, Wand2 } from 'lucide-svelte';
    import Button from '../core/Button.svelte';
    import Select from '../core/Select.svelte';

    let dataType = 'user';
    let count = 1;
    let generatedData = null;
    let copied = false;

    const dataTypes = [
        { value: 'user', label: 'User Data' },
        { value: 'order', label: 'Order Data' },
        { value: 'payment', label: 'Payment Data' },
    ];

    function generateData() {
        try {
            generatedData = mockDataGenerator.generateTestData(dataType, count);
        } catch (error) {
            console.error('Error generating data:', error);
        }
    }

    async function copyToClipboard() {
        if (generatedData) {
            try {
                await navigator.clipboard.writeText(JSON.stringify(generatedData, null, 2));
                copied = true;
                setTimeout(() => (copied = false), 2000);
            } catch (error) {
                console.error('Copy failed:', error);
            }
        }
    }

    function applyToRequest() {
        // Emit event to apply generated data to request body
        const event = new CustomEvent('applyMockData', {
            detail: { data: generatedData },
        });
        document.dispatchEvent(event);
    }
</script>

// src/lib/components/testing/MockDataPanel.svelte
<div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
    <div class="flex items-center mb-4">
        <Database class="h-5 w-5 text-purple-600 mr-2" />
        <h3 class="font-medium text-gray-900 dark:text-white">Mock Data Generator</h3>
    </div>

    <div class="grid grid-cols-2 gap-3 mb-4">
        <Select label="Data Type" options={dataTypes} bind:value={dataType} />

        <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Count
            </label>
            <input
                type="number"
                min="1"
                max="100"
                bind:value={count}
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white text-sm"
            />
        </div>
    </div>

    <div class="flex space-x-2 mb-4">
        <Button size="sm" on:click={generateData}>
            <Wand2 class="h-3 w-3 mr-1" />
            Generate
        </Button>

        {#if generatedData}
            <Button size="sm" variant="secondary" on:click={copyToClipboard}>
                <Copy class="h-3 w-3 mr-1" />
                {copied ? 'Copied!' : 'Copy'}
            </Button>

            <Button size="sm" variant="secondary" on:click={applyToRequest}>
                <RefreshCw class="h-3 w-3 mr-1" />
                Apply to Request
            </Button>
        {/if}
    </div>

    {#if generatedData}
        <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-3 max-h-64 overflow-y-auto">
            <pre class="text-xs font-mono text-gray-800 dark:text-gray-200 whitespace-pre-wrap">
        {JSON.stringify(generatedData, null, 2)}
      </pre>
        </div>
    {/if}
</div>
