// Base JavaScript for AI Assistant

class AIAssistant {
    constructor() {
        this.theme = localStorage.getItem('theme') || 'system';
        this.modelStatus = {
            loaded: false,
            model: null,
            device: null
        };
        
        this.init();
    }

    init() {
        this.setupTheme();
        this.setupEventListeners();
        this.checkModelStatus();
        this.setupToastSystem();
        
        console.log('AI Assistant initialized');
    }

    // Theme management
    setupTheme() {
        const html = document.documentElement;
        
        if (this.theme === 'dark' || 
            (this.theme === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
            html.classList.add('dark');
        } else {
            html.classList.remove('dark');
        }
    }

    toggleTheme() {
        const html = document.documentElement;
        
        if (html.classList.contains('dark')) {
            html.classList.remove('dark');
            this.theme = 'light';
        } else {
            html.classList.add('dark');
            this.theme = 'dark';
        }
        
        localStorage.setItem('theme', this.theme);
        this.showToast('Theme changed', 'info');
    }

    // Event listeners
    setupEventListeners() {
        // Theme toggle
        const themeToggle = document.getElementById('theme-toggle');
        if (themeToggle) {
            themeToggle.addEventListener('click', () => this.toggleTheme());
        }

        // Mobile menu toggle
        const mobileMenuToggle = document.getElementById('mobile-menu-toggle');
        const mobileMenu = document.getElementById('mobile-menu');
        
        if (mobileMenuToggle && mobileMenu) {
            mobileMenuToggle.addEventListener('click', () => {
                mobileMenu.classList.toggle('hidden');
            });
        }

        // Close mobile menu when clicking outside
        document.addEventListener('click', (e) => {
            const mobileMenu = document.getElementById('mobile-menu');
            const mobileMenuToggle = document.getElementById('mobile-menu-toggle');
            
            if (mobileMenu && !mobileMenu.classList.contains('hidden')) {
                if (!mobileMenu.contains(e.target) && !mobileMenuToggle.contains(e.target)) {
                    mobileMenu.classList.add('hidden');
                }
            }
        });

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => this.handleKeyboardShortcuts(e));

        // Window resize handler
        window.addEventListener('resize', () => this.handleResize());
    }

    handleKeyboardShortcuts(e) {
        // Ctrl/Cmd + D: Toggle theme
        if ((e.ctrlKey || e.metaKey) && e.key === 'd') {
            e.preventDefault();
            this.toggleTheme();
        }

        // Ctrl/Cmd + /: Show help (can be overridden by specific pages)
        if ((e.ctrlKey || e.metaKey) && e.key === '/') {
            e.preventDefault();
            this.showHelp();
        }

        // Escape: Close modals/overlays
        if (e.key === 'Escape') {
            this.closeOverlays();
        }
    }

    handleResize() {
        // Close mobile menu on resize to desktop
        if (window.innerWidth >= 768) {
            const mobileMenu = document.getElementById('mobile-menu');
            if (mobileMenu) {
                mobileMenu.classList.add('hidden');
            }
        }
    }

    // Model status management
    async checkModelStatus() {
        try {
            const response = await fetch('/api/health/model');
            const data = await response.json();
            
            this.updateModelStatus(data);
        } catch (error) {
            console.error('Failed to check model status:', error);
            this.updateModelStatus({ loaded: false, error: 'Connection failed' });
        }

        // Check again in 30 seconds
        setTimeout(() => this.checkModelStatus(), 30000);
    }

    updateModelStatus(status) {
        const statusDot = document.getElementById('status-dot');
        const statusText = document.getElementById('status-text');
        const noModelBanner = document.getElementById('no-model-banner');

        if (!statusDot || !statusText) return;

        this.modelStatus = status;

        if (status.loaded) {
            statusDot.className = 'w-2 h-2 rounded-full bg-green-500 status-online';
            const modelName = status.model_name ? status.model_name.split('/').pop() : 'Unknown';
            statusText.textContent = `${modelName} (${status.device})`;

            // Hide "no model" banner
            if (noModelBanner) {
                noModelBanner.classList.add('hidden');
            }
        } else if (status.error) {
            statusDot.className = 'w-2 h-2 rounded-full bg-red-500';
            statusText.textContent = 'Model Error';

            // Show "no model" banner
            if (noModelBanner) {
                noModelBanner.classList.remove('hidden');
            }
        } else {
            statusDot.className = 'w-2 h-2 rounded-full bg-yellow-500';
            statusText.textContent = 'No model loaded';

            // Show "no model" banner
            if (noModelBanner) {
                noModelBanner.classList.remove('hidden');
            }
        }
    }

    // Toast notification system
    setupToastSystem() {
        this.toastContainer = document.getElementById('toast-container');
        this.toasts = [];
    }

    showToast(message, type = 'info', duration = 5000) {
        if (!this.toastContainer) return;

        const toast = this.createToastElement(message, type);
        this.toastContainer.appendChild(toast);
        this.toasts.push(toast);

        // Trigger animation
        requestAnimationFrame(() => {
            toast.classList.add('fade-in');
        });

        // Auto remove
        setTimeout(() => {
            this.removeToast(toast);
        }, duration);

        return toast;
    }

    createToastElement(message, type) {
        const toast = document.createElement('div');
        toast.className = `toast toast-${type} fade-in`;
        
        const icons = {
            success: '✓',
            error: '✕', 
            warning: '⚠',
            info: 'ℹ'
        };

        toast.innerHTML = `
            <div class="p-4">
                <div class="flex items-start">
                    <div class="flex-shrink-0">
                        <span class="text-lg">${icons[type] || icons.info}</span>
                    </div>
                    <div class="ml-3 w-0 flex-1 pt-0.5">
                        <p class="text-sm font-medium text-gray-900 dark:text-gray-100">${message}</p>
                    </div>
                    <div class="ml-4 flex-shrink-0 flex">
                        <button class="toast-close inline-flex text-gray-400 hover:text-gray-500 focus:outline-none">
                            <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                                <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path>
                            </svg>
                        </button>
                    </div>
                </div>
            </div>
        `;

        // Close button handler
        const closeBtn = toast.querySelector('.toast-close');
        closeBtn.addEventListener('click', () => this.removeToast(toast));

        return toast;
    }

    removeToast(toast) {
        if (!toast.parentNode) return;

        toast.classList.remove('fade-in');
        toast.classList.add('fade-out');

        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
            this.toasts = this.toasts.filter(t => t !== toast);
        }, 300);
    }

    // Loading overlay
    showLoading(message = 'Loading...') {
        const overlay = document.getElementById('loading-overlay');
        if (overlay) {
            overlay.querySelector('div div').textContent = message;
            overlay.classList.remove('hidden');
        }
    }

    hideLoading() {
        const overlay = document.getElementById('loading-overlay');
        if (overlay) {
            overlay.classList.add('hidden');
        }
    }

    // Modal/overlay management
    closeOverlays() {
        // Close mobile menu
        const mobileMenu = document.getElementById('mobile-menu');
        if (mobileMenu && !mobileMenu.classList.contains('hidden')) {
            mobileMenu.classList.add('hidden');
        }

        // Close any open modals (to be implemented by specific pages)
        document.dispatchEvent(new CustomEvent('closeModals'));
    }

    // Help system
    showHelp() {
        // Default help - can be overridden by specific pages
        this.showToast('Keyboard shortcuts: Ctrl+D (theme), Ctrl+/ (help), Esc (close)', 'info', 8000);
    }

    // HTTP utilities
    async apiRequest(url, options = {}) {
        const defaultOptions = {
            headers: {
                'Content-Type': 'application/json',
            }
        };

        const finalOptions = { ...defaultOptions, ...options };
        
        if (finalOptions.body && typeof finalOptions.body !== 'string') {
            finalOptions.body = JSON.stringify(finalOptions.body);
        }

        try {
            const response = await fetch(url, finalOptions);
            
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const contentType = response.headers.get('content-type');
            if (contentType && contentType.includes('application/json')) {
                return await response.json();
            } else {
                return await response.text();
            }
        } catch (error) {
            console.error('API request failed:', error);
            this.showToast(`Request failed: ${error.message}`, 'error');
            throw error;
        }
    }

    // WebSocket utilities
    createWebSocket(url, options = {}) {
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}${url}`;
        
        const ws = new WebSocket(wsUrl);
        
        ws.onopen = () => {
            console.log('WebSocket connected:', url);
            if (options.onOpen) options.onOpen();
        };
        
        ws.onerror = (error) => {
            console.error('WebSocket error:', error);
            this.showToast('Connection error', 'error');
            if (options.onError) options.onError(error);
        };
        
        ws.onclose = () => {
            console.log('WebSocket disconnected:', url);
            if (options.onClose) options.onClose();
        };
        
        ws.onmessage = (event) => {
            try {
                const data = JSON.parse(event.data);
                if (options.onMessage) options.onMessage(data);
            } catch (error) {
                console.error('WebSocket message parse error:', error);
                if (options.onMessage) options.onMessage(event.data);
            }
        };
        
        return ws;
    }

    // Utility methods
    debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }

    throttle(func, limit) {
        let inThrottle;
        return function() {
            const args = arguments;
            const context = this;
            if (!inThrottle) {
                func.apply(context, args);
                inThrottle = true;
                setTimeout(() => inThrottle = false, limit);
            }
        };
    }

    formatFileSize(bytes) {
        if (bytes === 0) return '0 B';
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
    }

    formatTimeAgo(date) {
        const now = new Date();
        const diffInSeconds = Math.floor((now - new Date(date)) / 1000);
        
        if (diffInSeconds < 60) return `${diffInSeconds}s ago`;
        if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)}m ago`;
        if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)}h ago`;
        return `${Math.floor(diffInSeconds / 86400)}d ago`;
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.aiAssistant = new AIAssistant();
});

// Export for modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AIAssistant;
}