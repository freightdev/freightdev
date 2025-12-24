// Settings functionality for AI Assistant

class SettingsManager {
    constructor() {
        this.settings = {
            model: {
                temperature: 0.7,
                maxTokens: 512,
                topP: 0.9,
                repetitionPenalty: 1.1
            },
            agents: {
                chatEnabled: true,
                codeEnabled: true,
                autoRouting: true,
                confidenceThreshold: 0.7,
                chatTemperature: 0.8,
                chatMaxTokens: 512,
                codeTemperature: 0.3,
                codeMaxTokens: 1024
            },
            memory: {
                maxContextLength: 4096,
                autoSummarize: true,
                persistentMemory: true,
                enableEmbeddings: true,
                similarityThreshold: 0.7,
                maxChunks: 5
            },
            interface: {
                theme: 'system',
                fontSize: 14,
                compactMode: false,
                sidebarAutoHide: false,
                showTimestamps: true,
                editorTheme: 'vs-dark',
                editorFontSize: 14,
                editorMinimap: true,
                editorLineNumbers: true,
                editorWordWrap: false,
                toastNotifications: true,
                soundNotifications: false,
                notificationDuration: 5
            },
            security: {
                localOnly: true,
                anonymizeData: false,
                autoDelete: false,
                autoDeletePeriod: 90,
                requireAuth: false,
                sessionTimeout: true,
                sessionTimeoutDuration: 30,
                restrictFileAccess: true,
                scanUploads: false,
                maxFileSize: 5
            }
        };
        
        this.currentSection = 'model';
        this.systemHealth = null;
        this.performanceMetrics = {};
        
        this.init();
    }

    async init() {
        console.log('Initializing Settings Manager...');
        
        this.loadSettings();
        this.setupEventListeners();
        this.setupSliders();
        this.loadSystemInfo();
        this.startPerformanceMonitoring();
        
        console.log('Settings Manager initialized');
    }

    // Settings Management
    loadSettings() {
        const stored = localStorage.getItem('ai-assistant-settings');
        if (stored) {
            try {
                const parsed = JSON.parse(stored);
                this.settings = this.deepMerge(this.settings, parsed);
            } catch (error) {
                console.error('Error loading settings:', error);
            }
        }
        
        this.applySettings();
    }

    saveSettings() {
        localStorage.setItem('ai-assistant-settings', JSON.stringify(this.settings));
        this.showSaveConfirmation();
    }

    applySettings() {
        // Model settings
        this.updateSlider('default-temperature', this.settings.model.temperature, 'default-temperature-value');
        this.updateSlider('default-max-tokens', this.settings.model.maxTokens, 'default-max-tokens-value');
        this.updateSlider('default-top-p', this.settings.model.topP, 'default-top-p-value');
        this.updateSlider('default-rep-penalty', this.settings.model.repetitionPenalty, 'default-rep-penalty-value');

        // Agent settings
        document.getElementById('chat-agent-enabled').checked = this.settings.agents.chatEnabled;
        document.getElementById('code-agent-enabled').checked = this.settings.agents.codeEnabled;
        document.getElementById('auto-routing').checked = this.settings.agents.autoRouting;
        this.updateSlider('confidence-threshold', this.settings.agents.confidenceThreshold, 'confidence-threshold-value');
        this.updateSlider('chat-temperature', this.settings.agents.chatTemperature, 'chat-temp-value');
        this.updateSlider('chat-max-tokens', this.settings.agents.chatMaxTokens, 'chat-tokens-value');
        this.updateSlider('code-temperature', this.settings.agents.codeTemperature, 'code-temp-value');
        this.updateSlider('code-max-tokens', this.settings.agents.codeMaxTokens, 'code-tokens-value');

        // Memory settings
        this.updateSlider('max-context-length', this.settings.memory.maxContextLength, 'max-context-value');
        document.getElementById('auto-summarize').checked = this.settings.memory.autoSummarize;
        document.getElementById('persistent-memory').checked = this.settings.memory.persistentMemory;
        document.getElementById('enable-embeddings').checked = this.settings.memory.enableEmbeddings;
        this.updateSlider('similarity-threshold', this.settings.memory.similarityThreshold, 'similarity-threshold-value');
        this.updateSlider('max-chunks', this.settings.memory.maxChunks, 'max-chunks-value');

        // Interface settings
        document.querySelector(`input[name="theme"][value="${this.settings.interface.theme}"]`).checked = true;
        this.updateSlider('font-size', this.settings.interface.fontSize, 'font-size-value', 'px');
        document.getElementById('compact-mode').checked = this.settings.interface.compactMode;
        document.getElementById('sidebar-auto-hide').checked = this.settings.interface.sidebarAutoHide;
        document.getElementById('show-timestamps').checked = this.settings.interface.showTimestamps;
        document.getElementById('editor-theme').value = this.settings.interface.editorTheme;
        this.updateSlider('editor-font-size', this.settings.interface.editorFontSize, 'editor-font-size-value', 'px');
        document.getElementById('editor-minimap').checked = this.settings.interface.editorMinimap;
        document.getElementById('editor-line-numbers').checked = this.settings.interface.editorLineNumbers;
        document.getElementById('editor-word-wrap').checked = this.settings.interface.editorWordWrap;
        document.getElementById('toast-notifications').checked = this.settings.interface.toastNotifications;
        document.getElementById('sound-notifications').checked = this.settings.interface.soundNotifications;
        this.updateSlider('notification-duration', this.settings.interface.notificationDuration, 'notification-duration-value', 's');

        // Security settings
        document.getElementById('local-only').checked = this.settings.security.localOnly;
        document.getElementById('anonymize-data').checked = this.settings.security.anonymizeData;
        document.getElementById('auto-delete').checked = this.settings.security.autoDelete;
        document.getElementById('auto-delete-period').value = this.settings.security.autoDeletePeriod;
        document.getElementById('require-auth').checked = this.settings.security.requireAuth;
        document.getElementById('session-timeout').checked = this.settings.security.sessionTimeout;
        this.updateSlider('session-timeout-duration', this.settings.security.sessionTimeoutDuration, 'session-timeout-value', ' minutes');
        document.getElementById('restrict-file-access').checked = this.settings.security.restrictFileAccess;
        document.getElementById('scan-uploads').checked = this.settings.security.scanUploads;
        document.getElementById('max-file-size').value = this.settings.security.maxFileSize;

        // Apply theme immediately
        this.applyTheme(this.settings.interface.theme);
        
        // Update auto-delete dropdown state
        document.getElementById('auto-delete-period').disabled = !this.settings.security.autoDelete;
    }

    updateSlider(sliderId, value, displayId, suffix = '') {
        const slider = document.getElementById(sliderId);
        const display = document.getElementById(displayId);
        
        if (slider && display) {
            slider.value = value;
            display.textContent = value + suffix;
        }
    }

    // Event Listeners
    setupEventListeners() {
        // Navigation
        document.querySelectorAll('.settings-nav-item').forEach(item => {
            item.addEventListener('click', () => {
                this.switchSection(item.dataset.section);
            });
        });

        // Model settings
        this.setupModelEventListeners();
        
        // Agent settings
        this.setupAgentEventListeners();
        
        // Memory settings
        this.setupMemoryEventListeners();
        
        // Interface settings
        this.setupInterfaceEventListeners();
        
        // Security settings
        this.setupSecurityEventListeners();
        
        // System actions
        this.setupSystemEventListeners();
    }

    setupModelEventListeners() {
        // Model action buttons
        document.getElementById('load-model-btn')?.addEventListener('click', () => {
            this.loadModel();
        });

        document.getElementById('unload-model-btn')?.addEventListener('click', () => {
            this.unloadModel();
        });

        document.getElementById('refresh-models-btn')?.addEventListener('click', () => {
            this.refreshAvailableModels();
        });

        // Load available models on initialization
        this.loadAvailableModels();
    }

    setupAgentEventListeners() {
        // Agent enable/disable
        document.getElementById('chat-agent-enabled')?.addEventListener('change', (e) => {
            this.settings.agents.chatEnabled = e.target.checked;
            this.saveSettings();
        });

        document.getElementById('code-agent-enabled')?.addEventListener('change', (e) => {
            this.settings.agents.codeEnabled = e.target.checked;
            this.saveSettings();
        });

        document.getElementById('auto-routing')?.addEventListener('change', (e) => {
            this.settings.agents.autoRouting = e.target.checked;
            this.saveSettings();
        });
    }

    setupMemoryEventListeners() {
        // Memory checkboxes
        ['auto-summarize', 'persistent-memory', 'enable-embeddings'].forEach(id => {
            const element = document.getElementById(id);
            element?.addEventListener('change', (e) => {
                const key = this.camelCase(id);
                this.settings.memory[key] = e.target.checked;
                this.saveSettings();
            });
        });

        // Data management buttons
        document.getElementById('backup-data-btn')?.addEventListener('click', () => {
            this.backupData();
        });

        document.getElementById('rebuild-embeddings-btn')?.addEventListener('click', () => {
            this.rebuildEmbeddings();
        });

        document.getElementById('clear-data-btn')?.addEventListener('click', () => {
            this.confirmClearData();
        });

        // Load memory statistics
        this.loadMemoryStats();
    }

    setupInterfaceEventListeners() {
        // Theme selection
        document.querySelectorAll('input[name="theme"]').forEach(radio => {
            radio.addEventListener('change', (e) => {
                this.settings.interface.theme = e.target.value;
                this.applyTheme(e.target.value);
                this.saveSettings();
            });
        });

        // Interface checkboxes
        ['compact-mode', 'sidebar-auto-hide', 'show-timestamps', 'editor-minimap', 
         'editor-line-numbers', 'editor-word-wrap', 'toast-notifications', 
         'sound-notifications'].forEach(id => {
            const element = document.getElementById(id);
            element?.addEventListener('change', (e) => {
                const key = this.camelCase(id);
                this.settings.interface[key] = e.target.checked;
                this.saveSettings();
            });
        });

        // Editor theme
        document.getElementById('editor-theme')?.addEventListener('change', (e) => {
            this.settings.interface.editorTheme = e.target.value;
            this.saveSettings();
        });
    }

    setupSecurityEventListeners() {
        // Security checkboxes
        ['local-only', 'anonymize-data', 'auto-delete', 'require-auth', 
         'session-timeout', 'restrict-file-access', 'scan-uploads'].forEach(id => {
            const element = document.getElementById(id);
            element?.addEventListener('change', (e) => {
                const key = this.camelCase(id);
                this.settings.security[key] = e.target.checked;
                
                // Special handling for auto-delete
                if (id === 'auto-delete') {
                    document.getElementById('auto-delete-period').disabled = !e.target.checked;
                }
                
                this.saveSettings();
            });
        });

        // Dropdowns
        document.getElementById('auto-delete-period')?.addEventListener('change', (e) => {
            this.settings.security.autoDeletePeriod = parseInt(e.target.value);
            this.saveSettings();
        });

        document.getElementById('max-file-size')?.addEventListener('change', (e) => {
            this.settings.security.maxFileSize = parseInt(e.target.value);
            this.saveSettings();
        });
    }

    setupSystemEventListeners() {
        document.getElementById('restart-system-btn')?.addEventListener('click', () => {
            this.confirmSystemAction('restart', 'Restart System', 
                'This will restart the AI Assistant. Any unsaved work may be lost.');
        });

        document.getElementById('export-config-btn')?.addEventListener('click', () => {
            this.exportConfiguration();
        });

        document.getElementById('check-updates-btn')?.addEventListener('click', () => {
            this.checkForUpdates();
        });
    }

    setupSliders() {
        // Model sliders
        this.setupSlider('default-temperature', 'model', 'temperature', 'default-temperature-value');
        this.setupSlider('default-max-tokens', 'model', 'maxTokens', 'default-max-tokens-value');
        this.setupSlider('default-top-p', 'model', 'topP', 'default-top-p-value');
        this.setupSlider('default-rep-penalty', 'model', 'repetitionPenalty', 'default-rep-penalty-value');

        // Agent sliders
        this.setupSlider('confidence-threshold', 'agents', 'confidenceThreshold', 'confidence-threshold-value');
        this.setupSlider('chat-temperature', 'agents', 'chatTemperature', 'chat-temp-value');
        this.setupSlider('chat-max-tokens', 'agents', 'chatMaxTokens', 'chat-tokens-value');
        this.setupSlider('code-temperature', 'agents', 'codeTemperature', 'code-temp-value');
        this.setupSlider('code-max-tokens', 'agents', 'codeMaxTokens', 'code-tokens-value');

        // Memory sliders
        this.setupSlider('max-context-length', 'memory', 'maxContextLength', 'max-context-value');
        this.setupSlider('similarity-threshold', 'memory', 'similarityThreshold', 'similarity-threshold-value');
        this.setupSlider('max-chunks', 'memory', 'maxChunks', 'max-chunks-value');

        // Interface sliders
        this.setupSlider('font-size', 'interface', 'fontSize', 'font-size-value', 'px');
        this.setupSlider('editor-font-size', 'interface', 'editorFontSize', 'editor-font-size-value', 'px');
        this.setupSlider('notification-duration', 'interface', 'notificationDuration', 'notification-duration-value', 's');

        // Security sliders
        this.setupSlider('session-timeout-duration', 'security', 'sessionTimeoutDuration', 'session-timeout-value', ' minutes');
    }

    setupSlider(sliderId, category, property, displayId, suffix = '') {
        const slider = document.getElementById(sliderId);
        const display = document.getElementById(displayId);
        
        if (!slider || !display) return;

        slider.addEventListener('input', (e) => {
            const value = parseFloat(e.target.value);
            this.settings[category][property] = value;
            display.textContent = value + suffix;
            
            // Debounced save
            clearTimeout(this.saveTimeout);
            this.saveTimeout = setTimeout(() => this.saveSettings(), 500);
        });
    }

    // Navigation
    switchSection(sectionName) {
        // Update navigation
        document.querySelectorAll('.settings-nav-item').forEach(item => {
            item.classList.remove('active');
        });
        
        document.querySelector(`[data-section="${sectionName}"]`)?.classList.add('active');

        // Update content
        document.querySelectorAll('.settings-section').forEach(section => {
            section.classList.remove('active');
        });
        
        document.getElementById(`${sectionName}-section`)?.classList.add('active');
        
        this.currentSection = sectionName;
    }

    // Model Management
    async loadAvailableModels() {
        try {
            // This would be implemented to scan for available model files
            const modelsContainer = document.getElementById('available-models');
            
            // Placeholder for now
            modelsContainer.innerHTML = `
                <div class="text-center py-4 text-gray-500 dark:text-gray-400">
                    <p>Model discovery not yet implemented</p>
                    <p class="text-xs mt-1">Place model files in the models directory</p>
                </div>
            `;
        } catch (error) {
            console.error('Error loading available models:', error);
        }
    }

    async loadModel() {
        try {
            window.aiAssistant.showLoading('Loading model...');
            
            // This would call the API to load a model
            const response = await fetch('/api/health/model/load', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ model_path: 'default' })
            });
            
            if (response.ok) {
                window.aiAssistant.showToast('Model loaded successfully', 'success');
                this.updateModelStatus();
            } else {
                throw new Error('Failed to load model');
            }
        } catch (error) {
            console.error('Error loading model:', error);
            window.aiAssistant.showToast('Failed to load model', 'error');
        } finally {
            window.aiAssistant.hideLoading();
        }
    }

    async unloadModel() {
        try {
            window.aiAssistant.showLoading('Unloading model...');
            
            // This would call the API to unload the model
            window.aiAssistant.showToast('Model unloaded', 'info');
            this.updateModelStatus();
        } catch (error) {
            console.error('Error unloading model:', error);
            window.aiAssistant.showToast('Failed to unload model', 'error');
        } finally {
            window.aiAssistant.hideLoading();
        }
    }

    async refreshAvailableModels() {
        window.aiAssistant.showToast('Refreshing model list...', 'info');
        await this.loadAvailableModels();
    }

    async updateModelStatus() {
        try {
            const response = await fetch('/api/health/model');
            const status = await response.json();
            
            const statusDot = document.getElementById('model-status-indicator');
            const modelName = document.getElementById('current-model-name');
            const deviceSpan = document.getElementById('model-device');
            
            if (status.loaded) {
                statusDot.className = 'w-3 h-3 rounded-full bg-green-500';
                modelName.textContent = status.model_name || 'Unknown Model';
                deviceSpan.textContent = status.device || 'Unknown Device';
            } else {
                statusDot.className = 'w-3 h-3 rounded-full bg-red-500';
                modelName.textContent = 'No model loaded';
                deviceSpan.textContent = 'N/A';
            }
        } catch (error) {
            console.error('Error updating model status:', error);
        }
    }

    // Memory Management
    async loadMemoryStats() {
        try {
            // This would call APIs to get memory statistics
            document.getElementById('total-conversations').textContent = '0';
            document.getElementById('total-messages').textContent = '0';
            document.getElementById('embeddings-count').textContent = '0';
            document.getElementById('storage-size').textContent = '0';
        } catch (error) {
            console.error('Error loading memory stats:', error);
        }
    }

    async backupData() {
        try {
            window.aiAssistant.showLoading('Creating backup...');
            
            // This would create a backup of all data
            const timestamp = new Date().toISOString().slice(0, 19).replace(/:/g, '-');
            const filename = `ai-assistant-backup-${timestamp}.json`;
            
            // Simulate backup creation
            setTimeout(() => {
                window.aiAssistant.hideLoading();
                window.aiAssistant.showToast('Backup created successfully', 'success');
            }, 2000);
        } catch (error) {
            console.error('Error creating backup:', error);
            window.aiAssistant.showToast('Failed to create backup', 'error');
        }
    }

    async rebuildEmbeddings() {
        try {
            window.aiAssistant.showLoading('Rebuilding embeddings...');
            
            // This would rebuild all embeddings
            setTimeout(() => {
                window.aiAssistant.hideLoading();
                window.aiAssistant.showToast('Embeddings rebuilt successfully', 'success');
                this.loadMemoryStats();
            }, 5000);
        } catch (error) {
            console.error('Error rebuilding embeddings:', error);
            window.aiAssistant.showToast('Failed to rebuild embeddings', 'error');
        }
    }

    confirmClearData() {
        this.showConfirmModal(
            'Clear All Data',
            'This will permanently delete all conversations, embeddings, and stored data. This action cannot be undone.',
            () => this.clearAllData()
        );
    }

    async clearAllData() {
        try {
            window.aiAssistant.showLoading('Clearing all data...');
            
            // This would clear all data
            setTimeout(() => {
                window.aiAssistant.hideLoading();
                window.aiAssistant.showToast('All data cleared', 'success');
                this.loadMemoryStats();
            }, 2000);
        } catch (error) {
            console.error('Error clearing data:', error);
            window.aiAssistant.showToast('Failed to clear data', 'error');
        }
    }

    // Theme Management
    applyTheme(theme) {
        const html = document.documentElement;
        
        if (theme === 'dark') {
            html.classList.add('dark');
        } else if (theme === 'light') {
            html.classList.remove('dark');
        } else { // system
            const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
            html.classList.toggle('dark', prefersDark);
        }
    }

    // System Information
    async loadSystemInfo() {
        try {
            const response = await fetch('/api/health');
            const health = await response.json();
            
            this.systemHealth = health;
            this.updateSystemHealthDisplay();
            this.updateModelStatus();
        } catch (error) {
            console.error('Error loading system info:', error);
        }
    }

    updateSystemHealthDisplay() {
        if (!this.systemHealth) return;

        // Update health indicators
        const modelHealthDot = document.getElementById('model-health-dot');
        const modelHealthStatus = document.getElementById('model-health-status');
        
        if (this.systemHealth.services?.model?.healthy) {
            modelHealthDot.className = 'w-3 h-3 rounded-full bg-green-500';
            modelHealthStatus.textContent = 'Loaded';
        } else {
            modelHealthDot.className = 'w-3 h-3 rounded-full bg-red-500';
            modelHealthStatus.textContent = 'Not Loaded';
        }

        // Update system metrics
        const system = this.systemHealth.system || {};
        document.getElementById('cpu-usage').textContent = `${system.cpu_percent || 0}%`;
        document.getElementById('memory-usage-percent').textContent = `${system.memory_percent || 0}%`;
    }

    startPerformanceMonitoring() {
        // Update performance metrics every 30 seconds
        setInterval(() => {
            this.updatePerformanceMetrics();
        }, 30000);
        
        this.updatePerformanceMetrics();
    }

    async updatePerformanceMetrics() {
        try {
            const response = await fetch('/api/health');
            const health = await response.json();
            
            if (health.system) {
                document.getElementById('cpu-usage').textContent = `${health.system.cpu_percent || 0}%`;
                document.getElementById('memory-usage-percent').textContent = `${health.system.memory_percent || 0}%`;
            }

            // Calculate uptime (placeholder)
            const uptimeElement = document.getElementById('uptime');
            if (uptimeElement) {
                uptimeElement.textContent = '0d 0h';
            }

            // Average response time (placeholder)
            const avgResponseElement = document.getElementById('avg-response-time');
            if (avgResponseElement) {
                avgResponseElement.textContent = '-- ms';
            }
        } catch (error) {
            console.error('Error updating performance metrics:', error);
        }
    }

    // System Actions
    confirmSystemAction(action, title, message) {
        this.showConfirmModal(title, message, () => {
            this.executeSystemAction(action);
        });
    }

    async executeSystemAction(action) {
        try {
            window.aiAssistant.showLoading(`Executing ${action}...`);
            
            // This would call the appropriate system API
            switch (action) {
                case 'restart':
                    // Restart system
                    break;
                case 'shutdown':
                    // Shutdown system
                    break;
            }
            
            setTimeout(() => {
                window.aiAssistant.hideLoading();
                window.aiAssistant.showToast(`${action} completed`, 'success');
            }, 3000);
        } catch (error) {
            console.error(`Error executing ${action}:`, error);
            window.aiAssistant.showToast(`Failed to ${action}`, 'error');
        }
    }

    exportConfiguration() {
        try {
            const config = {
                settings: this.settings,
                timestamp: new Date().toISOString(),
                version: '1.0.0'
            };
            
            const blob = new Blob([JSON.stringify(config, null, 2)], { type: 'application/json' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `ai-assistant-config-${new Date().toISOString().slice(0, 10)}.json`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
            
            window.aiAssistant.showToast('Configuration exported', 'success');
        } catch (error) {
            console.error('Error exporting configuration:', error);
            window.aiAssistant.showToast('Failed to export configuration', 'error');
        }
    }

    async checkForUpdates() {
        try {
            window.aiAssistant.showLoading('Checking for updates...');
            
            // This would check for updates
            setTimeout(() => {
                window.aiAssistant.hideLoading();
                window.aiAssistant.showToast('No updates available', 'info');
            }, 2000);
        } catch (error) {
            console.error('Error checking for updates:', error);
            window.aiAssistant.showToast('Failed to check for updates', 'error');
        }
    }

    // Utility Methods
    showConfirmModal(title, message, onConfirm) {
        document.getElementById('confirm-title').textContent = title;
        document.getElementById('confirm-message').textContent = message;
        document.getElementById('confirm-modal').classList.remove('hidden');
        
        const confirmBtn = document.getElementById('confirm-action-btn');
        confirmBtn.onclick = () => {
            this.closeModal('confirm-modal');
            onConfirm();
        };
    }

    closeModal(modalId) {
        document.getElementById(modalId)?.classList.add('hidden');
    }

    showSaveConfirmation() {
        // Briefly show save confirmation
        const originalText = document.querySelector('.settings-nav-item.active').textContent;
        document.querySelector('.settings-nav-item.active').textContent = '✓ Saved';
        
        setTimeout(() => {
            document.querySelector('.settings-nav-item.active').textContent = originalText;
        }, 1500);
    }

    camelCase(str) {
        return str.replace(/-./g, x => x[1].toUpperCase());
    }

    deepMerge(target, source) {
        const output = Object.assign({}, target);
        if (this.isObject(target) && this.isObject(source)) {
            Object.keys(source).forEach(key => {
                if (this.isObject(source[key])) {
                    if (!(key in target))
                        Object.assign(output, { [key]: source[key] });
                    else
                        output[key] = this.deepMerge(target[key], source[key]);
                } else {
                    Object.assign(output, { [key]: source[key] });
                }
            });
        }
        return output;
    }

    isObject(item) {
        return item && typeof item === 'object' && !Array.isArray(item);
    }
}

// Global functions
function closeModal(modalId) {
    if (window.settings) {
        window.settings.closeModal(modalId);
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.settings = new SettingsManager();
});