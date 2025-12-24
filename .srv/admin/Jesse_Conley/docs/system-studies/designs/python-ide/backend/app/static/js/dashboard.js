/**
 * Agency Control Center - Dashboard JavaScript
 * Powers the entire control interface
 */

function dashboardApp() {
    return {
        // State
        loading: true,
        refreshing: false,
        currentView: 'dashboard',
        sidebarOpen: true,
        user: {},
        services: [],
        systemStats: {
            cpu_percent: 0,
            memory_percent: 0,
            disk_percent: 0
        },
        logs: [],
        selectedService: '',
        markdownContent: '# Welcome to Markdown Editor\n\nStart typing...',
        markdownPreview: '',
        uploadedFiles: [],
        uploadProgress: 0,
        lastUpdate: new Date().toLocaleTimeString(),

        // Initialization
        async init() {
            try {
                // Get token from localStorage
                const token = localStorage.getItem('agency_token');

                if (!token) {
                    window.location.href = '/login';
                    return;
                }

                // Set auth header
                this.authHeaders = {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                };

                // Load user info
                await this.loadUser();

                // Load initial data
                await this.refreshData();

                // Initial markdown render
                this.renderMarkdown();

                // Setup auto-refresh
                setInterval(() => this.refreshData(true), 5000);

                this.loading = false;
            } catch (error) {
                console.error('Initialization error:', error);
                localStorage.removeItem('agency_token');
                window.location.href = '/login';
            }
        },

        // User methods
        async loadUser() {
            const response = await fetch('/api/control/auth/me', {
                headers: this.authHeaders
            });

            if (!response.ok) {
                throw new Error('Failed to load user');
            }

            this.user = await response.json();
        },

        async logout() {
            await fetch('/api/control/auth/logout', {
                method: 'POST',
                headers: this.authHeaders
            });

            localStorage.removeItem('agency_token');
            window.location.href = '/login';
        },

        // Data loading
        async refreshData(silent = false) {
            if (!silent) {
                this.refreshing = true;
            }

            try {
                await Promise.all([
                    this.loadServices(),
                    this.loadSystemStats()
                ]);

                this.lastUpdate = new Date().toLocaleTimeString();
            } catch (error) {
                console.error('Refresh error:', error);
                this.showNotification('Failed to refresh data', 'error');
            } finally {
                this.refreshing = false;
            }
        },

        async loadServices() {
            const response = await fetch('/api/control/services', {
                headers: this.authHeaders
            });

            if (response.ok) {
                this.services = await response.json();
            }
        },

        async loadSystemStats() {
            const response = await fetch('/api/control/stats', {
                headers: this.authHeaders
            });

            if (response.ok) {
                this.systemStats = await response.json();
            }
        },

        // Service control
        async controlService(service, action) {
            try {
                const response = await fetch('/api/control/service/action', {
                    method: 'POST',
                    headers: this.authHeaders,
                    body: JSON.stringify({ service, action })
                });

                const result = await response.json();

                if (result.success) {
                    this.showNotification(`Service ${action}ed successfully`, 'success');
                    setTimeout(() => this.loadServices(), 2000);
                } else {
                    this.showNotification(result.message, 'error');
                }
            } catch (error) {
                this.showNotification('Failed to control service', 'error');
            }
        },

        async startAllServices() {
            if (!confirm('Start all services?')) return;

            for (const service of this.services) {
                if (service.status !== 'running') {
                    await this.controlService(service.name, 'start');
                }
            }

            this.showNotification('Starting all services...', 'info');
        },

        async stopAllServices() {
            if (!confirm('Stop ALL services? This will shut down the agency!')) return;

            for (const service of this.services) {
                if (service.status === 'running') {
                    await this.controlService(service.name, 'stop');
                }
            }

            this.showNotification('Stopping all services...', 'warning');
        },

        // Logs
        async loadLogs() {
            if (!this.selectedService) return;

            try {
                const response = await fetch('/api/control/logs', {
                    method: 'POST',
                    headers: this.authHeaders,
                    body: JSON.stringify({
                        service: this.selectedService,
                        lines: 100
                    })
                });

                const result = await response.json();

                if (result.success) {
                    this.logs = result.logs;
                } else {
                    this.logs = [];
                    this.showNotification('No logs available', 'warning');
                }
            } catch (error) {
                this.showNotification('Failed to load logs', 'error');
            }
        },

        // File handling
        async uploadFile(event) {
            const file = event.target.files[0];
            if (!file) return;

            const formData = new FormData();
            formData.append('file', file);

            this.uploadProgress = 0;

            try {
                const xhr = new XMLHttpRequest();

                xhr.upload.addEventListener('progress', (e) => {
                    if (e.lengthComputable) {
                        this.uploadProgress = Math.round((e.loaded / e.total) * 100);
                    }
                });

                xhr.addEventListener('load', () => {
                    if (xhr.status === 200) {
                        const result = JSON.parse(xhr.responseText);
                        this.uploadedFiles.unshift(result);
                        this.showNotification('File uploaded successfully', 'success');
                        this.uploadProgress = 0;
                    } else {
                        this.showNotification('Upload failed', 'error');
                        this.uploadProgress = 0;
                    }
                });

                xhr.open('POST', '/api/control/file/upload');
                xhr.setRequestHeader('Authorization', `Bearer ${localStorage.getItem('agency_token')}`);
                xhr.send(formData);

            } catch (error) {
                this.showNotification('Upload failed', 'error');
                this.uploadProgress = 0;
            }
        },

        handleFileDrop(event) {
            const file = event.dataTransfer.files[0];
            if (file) {
                this.uploadFile({ target: { files: [file] } });
            }
        },

        async downloadFile(filename) {
            window.open(`/api/control/file/download/${filename}`, '_blank');
        },

        // Markdown
        renderMarkdown() {
            // Simple markdown rendering (in production, use marked.js or similar)
            let html = this.markdownContent
                .replace(/^### (.*$)/gim, '<h3>$1</h3>')
                .replace(/^## (.*$)/gim, '<h2>$1</h2>')
                .replace(/^# (.*$)/gim, '<h1>$1</h1>')
                .replace(/\*\*(.*)\*\*/gim, '<strong>$1</strong>')
                .replace(/\*(.*)\*/gim, '<em>$1</em>')
                .replace(/\n/gim, '<br>');

            this.markdownPreview = html;
        },

        // Utilities
        getViewTitle() {
            const titles = {
                dashboard: 'Dashboard',
                services: 'Service Management',
                files: 'File Manager',
                markdown: 'Markdown Editor',
                logs: 'System Logs',
                settings: 'Settings'
            };
            return titles[this.currentView] || 'Dashboard';
        },

        showNotification(message, type = 'info') {
            // Create notification element
            const notification = document.createElement('div');
            notification.className = `fixed top-4 right-4 z-50 glass rounded-lg p-4 min-w-[300px] transform transition-all duration-300 translate-x-[400px]`;

            const colors = {
                success: 'border-green-500 bg-green-500/20',
                error: 'border-red-500 bg-red-500/20',
                warning: 'border-yellow-500 bg-yellow-500/20',
                info: 'border-blue-500 bg-blue-500/20'
            };

            notification.className += ` border ${colors[type]}`;

            const icons = {
                success: 'fa-check-circle text-green-400',
                error: 'fa-times-circle text-red-400',
                warning: 'fa-exclamation-triangle text-yellow-400',
                info: 'fa-info-circle text-blue-400'
            };

            notification.innerHTML = `
                <div class="flex items-center space-x-3">
                    <i class="fas ${icons[type]} text-xl"></i>
                    <span>${message}</span>
                </div>
            `;

            document.body.appendChild(notification);

            // Animate in
            setTimeout(() => {
                notification.style.transform = 'translateX(0)';
            }, 10);

            // Auto remove
            setTimeout(() => {
                notification.style.transform = 'translateX(400px)';
                setTimeout(() => notification.remove(), 300);
            }, 3000);
        }
    };
}

// Auto-login check on page load
document.addEventListener('DOMContentLoaded', () => {
    const token = localStorage.getItem('agency_token');
    if (!token && !window.location.pathname.includes('/login')) {
        window.location.href = '/login';
    }
});
