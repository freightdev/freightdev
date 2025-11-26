<!-- src/lib/components/core/Editor.svelte -->
<script lang="ts">
	import { createEventDispatcher, onMount } from 'svelte';

	// Event typing
	type EditorChangeEvent = { value: string };

	const dispatch = createEventDispatcher<{ change: EditorChangeEvent }>();

	// Props with types
	export let value: string = '';
	export let language: string = 'json';
	export let placeholder: string = '';
	export let readonly: boolean = false;

	let editor: HTMLTextAreaElement | null = null;
	let container: HTMLDivElement | null = null;

	onMount(() => {
		// Simple fallback editor (will be replaced with CodeMirror in future)
		return () => {
			// Cleanup
		};
	});

	function handleInput(event: Event) {
		const target = event.target as HTMLTextAreaElement;
		value = target.value;
		dispatch('change', { value });
	}
</script>

<div bind:this={container} class="relative">
	<textarea
		bind:this={editor}
		class="h-full min-h-[200px] w-full resize-none rounded-lg border border-gray-600 bg-gray-900 p-3 font-mono text-sm text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
		{placeholder}
		{readonly}
		bind:value
		on:input={handleInput}
	/>
</div>
