// ui.ts
import type { Component } from 'svelte';
import { writable } from 'svelte/store';

export type Notification = {
	type?: 'info' | 'success' | 'error' | 'warning';
	message: string;
	id?: number;
	timestamp?: string;
};

export type ModalProps = Record<string, unknown>;
export type ModalComponent = Component<ModalProps>;

export const sidebarOpen = writable(true);
export const theme = writable<'light' | 'dark'>('light');
export const notifications = writable<Notification[]>([]);
export const loading = writable(false);
export const modal = writable<{
	open: boolean;
	component: ModalComponent | null;
	props: ModalProps;
}>({
	open: false,
	component: null,
	props: {}
});

export const uiStore = {
	showNotification: (notification: Notification) => {
		const id = Date.now();
		const newNotification: Notification = {
			id,
			type: notification.type || 'info',
			message: notification.message,
			timestamp: new Date().toISOString()
		};
		notifications.update((list) => [...list, newNotification]);

		setTimeout(() => {
			notifications.update((list) => list.filter((n) => n.id !== id));
		}, 5000);
	},

	openModal: (component: ModalComponent, props: ModalProps = {}) => {
		modal.set({ open: true, component, props });
	},

	closeModal: () => {
		modal.set({ open: false, component: null, props: {} });
	},

	toggleSidebar: () => {
		sidebarOpen.update((open) => !open);
	}
};
