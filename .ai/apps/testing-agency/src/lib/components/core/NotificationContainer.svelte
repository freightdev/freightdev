<!-- src/lib/components/core/NotificationContainer.svelte -->
<script>
    import { notifications } from '$lib/stores/ui.js';
    import Notification from './Notification.svelte';
</script>

<div class="fixed top-4 right-4 z-50 space-y-2">
    {#each $notifications as notification (notification.id)}
        <Notification {notification} />
    {/each}
</div>
