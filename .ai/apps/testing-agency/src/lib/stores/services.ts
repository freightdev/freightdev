// src/lib/stores/services.ts
import type { Service } from '$lib/types';
import { derived, writable } from 'svelte/store';
import { v4 as uuidv4 } from 'uuid';

// Writable stores
export const services = writable<Service[]>([]);
export const selectedService = writable<Service | null>(null);
export const environments = writable<string[]>(['development', 'staging', 'production']);
export const currentEnvironment = writable<string>('development');

// Replace 'any' with unknown, or define a proper type for your configs
export type ServiceConfig = Record<string, unknown>;
export const serviceConfigs = writable<Record<string, ServiceConfig>>({});

// Derived store for active services
export const activeServices = derived(services, ($services) =>
	$services.filter((service) => service.status === 'active')
);

// Service management
export const serviceStore = {
	add: (
		serviceData: Omit<Service, 'id' | 'status' | 'lastHealthCheck' | 'createdAt' | 'updatedAt'>
	) => {
		const newService: Service = {
			id: uuidv4(),
			status: 'unknown',
			lastHealthCheck: null,
			createdAt: new Date().toISOString(),
			updatedAt: new Date().toISOString(),
			...serviceData
		};

		services.update((list) => [...list, newService]);
		return newService;
	},

	update: (id: string, updates: Partial<Omit<Service, 'id' | 'createdAt'>>) => {
		services.update((list) =>
			list.map((service) =>
				service.id === id
					? { ...service, ...updates, updatedAt: new Date().toISOString() }
					: service
			)
		);
	},

	remove: (id: string) => {
		services.update((list) => list.filter((service) => service.id !== id));
	},

	setStatus: (id: string, status: Service['status']) => {
		services.update((list) =>
			list.map((service) =>
				service.id === id
					? { ...service, status, lastHealthCheck: new Date().toISOString() }
					: service
			)
		);
	}
};
