<!-- src/lib/components/core/Modal.svelte -->
<script>
	import { modal, uiStore } from '$lib/stores/ui.js';
	import { X } from 'lucide-svelte';
	import Button from './Button.svelte';

	function closeModal() {
		uiStore.closeModal();
	}

	function handleBackdropClick(event) {
		if (event.target === event.currentTarget) {
			closeModal();
		}
	}

	function handleKeydown(event) {
		if (event.key === 'Escape') {
			closeModal();
		}
	}
</script>

ds{#if $modal.open}
	<!-- Backdrop -->
	<div
		class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
		role="presentation"
		on:click={handleBackdropClick}
	>
		<!-- Modal -->
		<div
			class="max-h-[90vh] w-full max-w-md overflow-y-auto rounded-lg bg-white shadow-xl dark:bg-gray-800"
			role="dialog"
			aria-modal="true"
			aria-labelledby="modal-title"
		>
			<!-- Modal Header -->
			<div
				class="flex items-center justify-between border-b border-gray-200 p-6 dark:border-gray-700"
			>
				<h3 id="modal-title" class="text-lg font-semibold text-gray-900 dark:text-white">
					{$modal.props?.title || 'Modal'}
				</h3>
				<Button variant="ghost" size="sm" on:click={closeModal} aria-label="Close">
					<X class="h-4 w-4" />
				</Button>
			</div>

			<!-- Modal Content -->
			<div class="p-6">
				{#if $modal.component}
					<svelte:component this={$modal.component} {...$modal.props} on:close={closeModal} />
				{/if}
			</div>
		</div>
	</div>
{/if}

<!-- Escape key handler must be top-level -->
<svelte:window
	on:keydown={(e) => {
		if ($modal.open) handleKeydown(e);
	}}
/>
