// src/lib/services/httpClient.js
import { get } from 'svelte/store';
import { requestConfig } from '../stores/config.js';

class HTTPClient {
    constructor() {
        this.requestHistory = [];
        this.interceptors = {
            request: [],
            response: [],
        };
    }

    // Add request interceptor
    addRequestInterceptor(interceptor) {
        this.interceptors.request.push(interceptor);
    }

    // Add response interceptor
    addResponseInterceptor(interceptor) {
        this.interceptors.response.push(interceptor);
    }

    // Apply request interceptors
    async applyRequestInterceptors(config) {
        let modifiedConfig = { ...config };

        for (const interceptor of this.interceptors.request) {
            modifiedConfig = await interceptor(modifiedConfig);
        }

        return modifiedConfig;
    }

    // Apply response interceptors
    async applyResponseInterceptors(response, config) {
        let modifiedResponse = response;

        for (const interceptor of this.interceptors.response) {
            modifiedResponse = await interceptor(modifiedResponse, config);
        }

        return modifiedResponse;
    }

    // Build fetch options from config
    buildFetchOptions(config) {
        const options = {
            method: config.method || 'GET',
            headers: { ...config.headers },
        };

        // Add body for methods that support it
        if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(options.method) && config.body) {
            if (typeof config.body === 'string') {
                options.body = config.body;
            } else if (config.body instanceof FormData) {
                options.body = config.body;
                // Remove Content-Type header for FormData (browser sets it automatically)
                delete options.headers['Content-Type'];
            } else {
                options.body = JSON.stringify(config.body);
                if (!options.headers['Content-Type']) {
                    options.headers['Content-Type'] = 'application/json';
                }
            }
        }

        return options;
    }

    // Build URL with query parameters
    buildURL(baseUrl, params = {}) {
        const url = new URL(baseUrl);

        Object.entries(params).forEach(([key, value]) => {
            if (value !== null && value !== undefined && value !== '') {
                url.searchParams.append(key, value);
            }
        });

        return url.toString();
    }

    // Add authentication to request
    addAuthentication(config, auth) {
        if (!auth || !auth.type) return config;

        const headers = { ...config.headers };

        switch (auth.type) {
            case 'bearer':
                if (auth.token) {
                    headers['Authorization'] = `Bearer ${auth.token}`;
                }
                break;

            case 'apikey':
                if (auth.key && auth.value) {
                    headers[auth.key] = auth.value;
                }
                break;

            case 'basic':
                if (auth.username && auth.password) {
                    const credentials = btoa(`${auth.username}:${auth.password}`);
                    headers['Authorization'] = `Basic ${credentials}`;
                }
                break;

            case 'custom':
                if (auth.headers) {
                    Object.assign(headers, auth.headers);
                }
                break;
        }

        return { ...config, headers };
    }

    // Execute HTTP request with retry logic
    async executeRequest(config) {
        const globalConfig = get(requestConfig);
        const maxRetries = config.retries ?? globalConfig.retries ?? 3;
        const timeout = config.timeout ?? globalConfig.timeout ?? 30000;

        let lastError;

        for (let attempt = 0; attempt <= maxRetries; attempt++) {
            try {
                const controller = new AbortController();
                const timeoutId = setTimeout(() => controller.abort(), timeout);

                const fetchOptions = {
                    ...this.buildFetchOptions(config),
                    signal: controller.signal,
                };

                const startTime = performance.now();
                const response = await fetch(config.url, fetchOptions);
                const endTime = performance.now();

                clearTimeout(timeoutId);

                const responseTime = Math.round(endTime - startTime);

                // Parse response body
                let responseData;
                const contentType = response.headers.get('content-type') || '';

                if (contentType.includes('application/json')) {
                    responseData = await response.json();
                } else if (contentType.includes('text/')) {
                    responseData = await response.text();
                } else {
                    responseData = await response.arrayBuffer();
                }

                const result = {
                    status: response.status,
                    statusText: response.statusText,
                    headers: Object.fromEntries(response.headers.entries()),
                    data: responseData,
                    responseTime,
                    config,
                    request: {
                        url: config.url,
                        method: config.method,
                        headers: config.headers,
                        body: config.body,
                    },
                };

                // Apply response interceptors
                return await this.applyResponseInterceptors(result, config);
            } catch (error) {
                lastError = error;

                if (error.name === 'AbortError') {
                    throw new Error(`Request timeout after ${timeout}ms`);
                }

                // Don't retry on certain errors
                if (attempt === maxRetries || this.isNonRetryableError(error)) {
                    break;
                }

                // Wait before retrying
                await this.delay(config.retryDelay ?? 1000);
            }
        }

        throw lastError;
    }

    // Check if error should not be retried
    isNonRetryableError(error) {
        return (
            error.name === 'AbortError' ||
            error.name === 'TypeError' ||
            (error.response && error.response.status < 500)
        );
    }

    // Delay utility for retries
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    // Main request method
    async request(config) {
        try {
            // Apply request interceptors
            const processedConfig = await this.applyRequestInterceptors(config);

            // Build full URL
            processedConfig.url = this.buildURL(processedConfig.url, processedConfig.params);

            // Add authentication
            if (processedConfig.auth) {
                Object.assign(
                    processedConfig,
                    this.addAuthentication(processedConfig, processedConfig.auth)
                );
            }

            // Execute request
            const response = await this.executeRequest(processedConfig);

            // Add to history
            this.addToHistory(processedConfig, response);

            return response;
        } catch (error) {
            // Add failed request to history
            this.addToHistory(config, null, error);
            throw error;
        }
    }

    // Add request to history
    addToHistory(config, response, error = null) {
        const historyEntry = {
            id: Date.now().toString(),
            timestamp: new Date().toISOString(),
            method: config.method,
            url: config.url,
            status: response?.status || 'Error',
            responseTime: response?.responseTime || 0,
            error: error?.message || null,
        };

        this.requestHistory.unshift(historyEntry);

        // Keep only last 100 requests
        if (this.requestHistory.length > 100) {
            this.requestHistory = this.requestHistory.slice(0, 100);
        }
    }

    // Convenience methods
    get(url, config = {}) {
        return this.request({ ...config, method: 'GET', url });
    }

    post(url, data, config = {}) {
        return this.request({ ...config, method: 'POST', url, body: data });
    }

    put(url, data, config = {}) {
        return this.request({ ...config, method: 'PUT', url, body: data });
    }

    patch(url, data, config = {}) {
        return this.request({ ...config, method: 'PATCH', url, body: data });
    }

    delete(url, config = {}) {
        return this.request({ ...config, method: 'DELETE', url });
    }

    // Get request history
    getHistory() {
        return [...this.requestHistory];
    }

    // Clear history
    clearHistory() {
        this.requestHistory = [];
    }
}

// Create singleton instance
export const httpClient = new HTTPClient();

// Default request interceptor for logging
httpClient.addRequestInterceptor(async config => {
    console.log('Making request:', config.method, config.url);
    return config;
});

// Default response interceptor for logging
httpClient.addResponseInterceptor(async (response, config) => {
    console.log('Response received:', response.status, config.url);
    return response;
});

export default httpClient;
