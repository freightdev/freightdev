// src/lib/stores/config.js
import type { EnvironmentConfig, GlobalConfig, RequestConfig } from '$lib/types';
import { writable } from 'svelte/store';

/** -----------------------------
 * Writable stores
 * ----------------------------- */

export const globalConfig = writable<GlobalConfig>({
	defaultTimeout: 30000,
	maxRetries: 3,
	retryDelay: 1000,
	defaultHeaders: {
		'Content-Type': 'application/json'
	},
	environments: {
		development: { name: 'Development', baseUrls: {}, auth: {} },
		staging: { name: 'Staging', baseUrls: {}, auth: {} },
		production: { name: 'Production', baseUrls: {}, auth: {} }
	}
});

export const requestConfig = writable<RequestConfig>({
	timeout: 30000,
	followRedirects: true,
	validateSSL: true,
	retries: 3
});

/** -----------------------------
 * Store actions
 * ----------------------------- */

export const configStore = {
	updateGlobal: (updates: Partial<GlobalConfig>) => {
		globalConfig.update((config) => ({ ...config, ...updates }));
	},

	updateEnvironment: (
		env: keyof GlobalConfig['environments'],
		updates: Partial<EnvironmentConfig>
	) => {
		globalConfig.update((config) => ({
			...config,
			environments: {
				...config.environments,
				[env]: { ...config.environments[env], ...updates }
			}
		}));
	},

	updateRequest: (updates: Partial<RequestConfig>) => {
		requestConfig.update((config) => ({ ...config, ...updates }));
	}
};
