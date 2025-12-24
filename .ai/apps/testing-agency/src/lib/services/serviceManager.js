// src/lib/services/serviceManager.js
import { get } from 'svelte/store';
import { currentEnvironment, globalConfig, services, serviceStore } from '../stores';
import { uiStore } from '../stores/ui.js';
import { httpClient } from './httpClient.js';

class ServiceManager {
    constructor() {
        this.healthCheckInterval = null;
        this.healthCheckIntervalMs = 60000; // 1 minute
        this.healthCheckEndpoints = ['/health', '/ping', '/status', '/api/health'];
    }

    // Initialize service manager
    initialize() {
        this.startHealthCheckInterval();
        this.loadServicesFromStorage();
    }

    // Load services from localStorage
    loadServicesFromStorage() {
        try {
            const saved = localStorage.getItem('microservices-test-suite-services');
            if (saved) {
                const serviceList = JSON.parse(saved);
                services.set(serviceList);
            }
        } catch (error) {
            console.error('Failed to load services from storage:', error);
        }
    }

    // Save services to localStorage
    saveServicesToStorage() {
        try {
            const serviceList = get(services);
            localStorage.setItem('microservices-test-suite-services', JSON.stringify(serviceList));
        } catch (error) {
            console.error('Failed to save services to storage:', error);
        }
    }

    // Add a new service
    async addService(serviceData) {
        try {
            const service = serviceStore.add(serviceData);
            this.saveServicesToStorage();

            // Perform initial health check
            await this.checkServiceHealth(service.id);

            uiStore.showNotification({
                type: 'success',
                message: `Service "${service.name}" added successfully`,
            });

            return service;
        } catch (error) {
            uiStore.showNotification({
                type: 'error',
                message: `Failed to add service: ${error.message}`,
            });
            throw error;
        }
    }

    // Update service configuration
    async updateService(id, updates) {
        try {
            serviceStore.update(id, updates);
            this.saveServicesToStorage();

            // Re-check health after update
            await this.checkServiceHealth(id);

            uiStore.showNotification({
                type: 'success',
                message: 'Service updated successfully',
            });
        } catch (error) {
            uiStore.showNotification({
                type: 'error',
                message: `Failed to update service: ${error.message}`,
            });
            throw error;
        }
    }

    // Remove a service
    removeService(id) {
        try {
            serviceStore.remove(id);
            this.saveServicesToStorage();

            uiStore.showNotification({
                type: 'success',
                message: 'Service removed successfully',
            });
        } catch (error) {
            uiStore.showNotification({
                type: 'error',
                message: `Failed to remove service: ${error.message}`,
            });
            throw error;
        }
    }

    // Get service by ID
    getService(id) {
        const serviceList = get(services);
        return serviceList.find(service => service.id === id);
    }

    // Get service configuration for current environment
    getServiceConfig(service) {
        const environment = get(currentEnvironment);
        const config = get(globalConfig);

        const envConfig = config.environments?.[environment] || {};
        const serviceConfig = envConfig.services?.[service.id] || {};

        return {
            baseUrl: serviceConfig.baseUrl || service.baseUrl,
            auth: serviceConfig.auth || service.auth || {},
            headers: {
                ...service.headers,
                ...serviceConfig.headers,
            },
            timeout: serviceConfig.timeout || config.defaultTimeout,
        };
    }

    // Perform health check on a service
    async checkServiceHealth(serviceId) {
        const service = this.getService(serviceId);
        if (!service) return;

        try {
            serviceStore.setStatus(serviceId, 'checking');

            const config = this.getServiceConfig(service);
            const healthEndpoint = await this.findHealthEndpoint(config.baseUrl, config);

            if (healthEndpoint) {
                const response = await httpClient.get(healthEndpoint, {
                    timeout: 5000,
                    retries: 1,
                    headers: config.headers,
                    auth: config.auth,
                });

                serviceStore.setStatus(serviceId, response.status === 200 ? 'active' : 'inactive');
                return true;
            } else {
                serviceStore.setStatus(serviceId, 'unknown');
                return false;
            }
        } catch (error) {
            serviceStore.setStatus(serviceId, 'inactive');
            return false;
        }
    }

    // Find working health endpoint
    async findHealthEndpoint(baseUrl, config) {
        for (const endpoint of this.healthCheckEndpoints) {
            try {
                const url = baseUrl.endsWith('/')
                    ? baseUrl + endpoint.slice(1)
                    : baseUrl + endpoint;
                await httpClient.get(url, {
                    timeout: 3000,
                    retries: 0,
                    headers: config.headers,
                    auth: config.auth,
                });
                return url;
            } catch (error) {
                continue;
            }
        }
        return null;
    }

    // Check health of all services
    async checkAllServicesHealth() {
        const serviceList = get(services);
        const promises = serviceList.map(service => this.checkServiceHealth(service.id));
        await Promise.allSettled(promises);
    }

    // Start automated health check interval
    startHealthCheckInterval() {
        if (this.healthCheckInterval) {
            clearInterval(this.healthCheckInterval);
        }

        this.healthCheckInterval = setInterval(() => {
            this.checkAllServicesHealth();
        }, this.healthCheckIntervalMs);
    }

    // Stop automated health check interval
    stopHealthCheckInterval() {
        if (this.healthCheckInterval) {
            clearInterval(this.healthCheckInterval);
            this.healthCheckInterval = null;
        }
    }

    // Test service endpoint
    async testEndpoint(serviceId, endpoint, options = {}) {
        const service = this.getService(serviceId);
        if (!service) throw new Error('Service not found');

        const config = this.getServiceConfig(service);
        const url = this.buildEndpointUrl(config.baseUrl, endpoint);

        const requestConfig = {
            method: options.method || 'GET',
            url,
            headers: { ...config.headers, ...options.headers },
            auth: options.auth || config.auth,
            body: options.body,
            params: options.params,
            timeout: options.timeout || config.timeout,
        };

        try {
            const response = await httpClient.request(requestConfig);
            return {
                success: true,
                response,
                error: null,
            };
        } catch (error) {
            return {
                success: false,
                response: null,
                error: error.message,
            };
        }
    }

    // Build full endpoint URL
    buildEndpointUrl(baseUrl, endpoint) {
        if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
            return endpoint;
        }

        const base = baseUrl.endsWith('/') ? baseUrl.slice(0, -1) : baseUrl;
        const path = endpoint.startsWith('/') ? endpoint : '/' + endpoint;

        return base + path;
    }

    // Discover service endpoints (if OpenAPI/Swagger is available)
    async discoverEndpoints(serviceId) {
        const service = this.getService(serviceId);
        if (!service) return [];

        const config = this.getServiceConfig(service);
        const swaggerEndpoints = ['/swagger.json', '/api-docs', '/docs/swagger.json'];

        for (const endpoint of swaggerEndpoints) {
            try {
                const url = this.buildEndpointUrl(config.baseUrl, endpoint);
                const response = await httpClient.get(url, {
                    headers: config.headers,
                    auth: config.auth,
                    timeout: 10000,
                });

                if (response.data && response.data.paths) {
                    return this.parseSwaggerPaths(response.data.paths);
                }
            } catch (error) {
                continue;
            }
        }

        return [];
    }

    // Parse Swagger/OpenAPI paths
    parseSwaggerPaths(paths) {
        const endpoints = [];

        Object.entries(paths).forEach(([path, methods]) => {
            Object.entries(methods).forEach(([method, details]) => {
                endpoints.push({
                    path,
                    method: method.toUpperCase(),
                    summary: details.summary || '',
                    description: details.description || '',
                    parameters: details.parameters || [],
                    responses: details.responses || {},
                });
            });
        });

        return endpoints;
    }

    // Get service statistics
    getServiceStats(serviceId) {
        const history = httpClient.getHistory();
        const service = this.getService(serviceId);

        if (!service) return null;

        const config = this.getServiceConfig(service);
        const serviceRequests = history.filter(req => req.url.startsWith(config.baseUrl));

        const total = serviceRequests.length;
        const successful = serviceRequests.filter(
            req => typeof req.status === 'number' && req.status >= 200 && req.status < 400
        ).length;

        const avgResponseTime =
            total > 0 ? serviceRequests.reduce((sum, req) => sum + req.responseTime, 0) / total : 0;

        return {
            total,
            successful,
            failed: total - successful,
            successRate: total > 0 ? ((successful / total) * 100).toFixed(1) : 0,
            avgResponseTime: Math.round(avgResponseTime),
        };
    }

    // Export service configuration
    exportService(serviceId) {
        const service = this.getService(serviceId);
        if (!service) return null;

        return {
            ...service,
            exportedAt: new Date().toISOString(),
            version: '1.0',
        };
    }

    // Import service configuration
    async importService(serviceData) {
        try {
            // Remove import metadata
            const { exportedAt, version, id, ...cleanServiceData } = serviceData;

            const service = await this.addService(cleanServiceData);

            uiStore.showNotification({
                type: 'success',
                message: 'Service imported successfully',
            });

            return service;
        } catch (error) {
            uiStore.showNotification({
                type: 'error',
                message: `Failed to import service: ${error.message}`,
            });
            throw error;
        }
    }

    // Cleanup
    destroy() {
        this.stopHealthCheckInterval();
    }
}

// Create singleton instance
export const serviceManager = new ServiceManager();

export default serviceManager;
