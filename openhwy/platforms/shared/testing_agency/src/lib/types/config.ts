// src/lib/types/config.ts

export type EnvironmentConfig = {
	name: string;
	baseUrls: Record<string, string>;
	auth: Record<string, unknown>;
};

export type GlobalConfig = {
	defaultTimeout: number;
	maxRetries: number;
	retryDelay: number;
	defaultHeaders: Record<string, string>;
	environments: {
		development: EnvironmentConfig;
		staging: EnvironmentConfig;
		production: EnvironmentConfig;
	};
};

export type RequestConfig = {
	timeout: number;
	followRedirects: boolean;
	validateSSL: boolean;
	retries: number;
};
