// IDE functionality for AI Assistant

class IDE {
    constructor() {
        this.editor = null;
        this.openFiles = new Map(); // filename -> file data
        this.activeFile = null;
        this.fileTree = null;
        this.chatWebSocket = null;
        this.terminalWebSocket = null;
        this.currentTheme = 'vs-dark';
        
        this.init();
    }

    async init() {
        console.log('Initializing IDE...');
        
        await this.setupMonacoEditor();
        this.setupEventListeners();
        this.setupChat();
        this.loadFileTree();
        this.setupKeyboardShortcuts();
        
        console.log('IDE initialized successfully');
    }

    // Monaco Editor Setup
    async setupMonacoEditor() {
        return new Promise((resolve) => {
            require.config({ 
                paths: { 
                    'vs': 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.44.0/min/vs' 
                } 
            });
            
            require(['vs/editor/editor.main'], () => {
                // Set theme based on current UI theme
                const isDark = document.documentElement.classList.contains('dark');
                this.currentTheme = isDark ? 'vs-dark' : 'vs';
                
                // Configure Monaco
                monaco.editor.defineTheme('ai-dark', {
                    base: 'vs-dark',
                    inherit: true,
                    rules: [],
                    colors: {
                        'editor.background': '#1e1e2e',
                        'editor.foreground': '#cdd6f4',
                        'editorLineNumber.foreground': '#6c7086',
                        'editor.selectionBackground': '#313244',
                        'editor.inactiveSelectionBackground': '#2a2a3a'
                    }
                });
                
                this.editor = monaco.editor.create(document.getElementById('monaco-container'), {
                    value: '',
                    language: 'plaintext',
                    theme: isDark ? 'ai-dark' : 'vs',
                    automaticLayout: true,
                    fontSize: 14,
                    lineNumbers: 'on',
                    roundedSelection: false,
                    scrollBeyondLastLine: false,
                    minimap: { enabled: true },
                    contextmenu: true,
                    selectOnLineNumbers: true
                });
                
                // Setup editor event listeners
                this.editor.onDidChangeModelContent(() => {
                    this.onEditorContentChange();
                });
                
                resolve();
            });
        });
    }

    onEditorContentChange() {
        if (this.activeFile) {
            const content = this.editor.getValue();
            const fileData = this.openFiles.get(this.activeFile);
            
            if (fileData) {
                fileData.modified = fileData.originalContent !== content;
                fileData.content = content;
                
                // Update tab indicator
                this.updateTabModifiedIndicator(this.activeFile, fileData.modified);
                
                // Enable/disable save button
                document.getElementById('save-file-btn').disabled = !fileData.modified;
            }
        }
        
        this.updateTokenCount();
    }

    updateTabModifiedIndicator(filename, isModified) {
        const tab = document.querySelector(`[data-file="${filename}"]`);
        if (tab) {
            const indicator = tab.querySelector('.modified-indicator');
            if (isModified && !indicator) {
                const dot = document.createElement('span');
                dot.className = 'modified-indicator w-2 h-2 bg-ai-blue rounded-full';
                tab.appendChild(dot);
            } else if (!isModified && indicator) {
                indicator.remove();
            }
        }
    }

    updateTokenCount() {
        const content = document.getElementById('chat-input')?.value || '';
        const tokenCount = Math.ceil(content.split(' ').length * 1.3);
        const tokenElement = document.getElementById('token-count');
        if (tokenElement) {
            tokenElement.textContent = `${tokenCount} tokens`;
        }
    }

    // File Management
    async loadFileTree() {
        try {
            const response = await fetch('/api/ide/files/tree');
            const data = await response.json();
            
            if (data.error) {
                throw new Error(data.error);
            }
            
            this.fileTree = data;
            this.renderFileTree(data);
        } catch (error) {
            console.error('Error loading file tree:', error);
            window.aiAssistant.showToast('Failed to load file tree', 'error');
        }
    }

    renderFileTree(tree, container = null, level = 0) {
        if (!container) {
            container = document.getElementById('file-tree');
            container.innerHTML = '';
        }

        if (tree.children) {
            tree.children.forEach(item => {
                const element = this.createFileTreeItem(item, level);
                container.appendChild(element);
                
                if (item.type === 'directory' && item.children) {
                    const childContainer = document.createElement('div');
                    childContainer.className = 'ml-4 hidden';
                    childContainer.id = `folder-${item.path}`;
                    this.renderFileTree(item, childContainer, level + 1);
                    container.appendChild(childContainer);
                }
            });
        }
    }

    createFileTreeItem(item, level) {
        const div = document.createElement('div');
        div.className = item.type === 'directory' ? 'folder-item' : 'file-item';
        
        if (item.type === 'directory') {
            div.innerHTML = `
                <svg class="chevron w-4 h-4 text-gray-400 transform transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
                </svg>
                <svg class="icon w-4 h-4 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z"/>
                </svg>
                <span>${item.name}</span>
            `;
            
            div.addEventListener('click', () => this.toggleFolder(item.path));
        } else {
            const icon = this.getFileIcon(item.language || item.extension);
            div.innerHTML = `
                <div class="w-4 h-4"></div>
                ${icon}
                <span>${item.name}</span>
                <span class="text-xs text-gray-400 ml-auto">${window.aiAssistant.formatFileSize(item.size)}</span>
            `;
            
            div.addEventListener('click', () => this.openFile(item.path));
            div.addEventListener('contextmenu', (e) => this.showFileContextMenu(e, item));
        }
        
        return div;
    }

    getFileIcon(type) {
        const icons = {
            python: '🐍',
            javascript: '📜',
            typescript: '📘',
            rust: '🦀',
            html: '🌐',
            css: '🎨',
            json: '📋',
            yaml: '⚙️',
            markdown: '📝',
            default: '📄'
        };
        
        return `<span class="text-sm">${icons[type] || icons.default}</span>`;
    }

    toggleFolder(path) {
        const folder = document.getElementById(`folder-${path}`);
        const folderItem = document.querySelector(`[data-path="${path}"]`);
        
        if (folder) {
            folder.classList.toggle('hidden');
            if (folderItem) {
                folderItem.classList.toggle('expanded');
            }
        }
    }

    async openFile(path) {
        try {
            // Check if file is already open
            if (this.openFiles.has(path)) {
                this.switchToFile(path);
                return;
            }

            const response = await fetch('/api/ide/files/read', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ path })
            });
            
            const data = await response.json();
            
            if (data.error) {
                if (data.is_binary) {
                    window.aiAssistant.showToast('Cannot open binary file', 'warning');
                    return;
                }
                throw new Error(data.error);
            }

            // Add to open files
            const fileData = {
                path,
                content: data.content,
                originalContent: data.content,
                language: data.language,
                modified: false
            };
            
            this.openFiles.set(path, fileData);
            this.createTab(path, fileData);
            this.switchToFile(path);
            
            window.aiAssistant.showToast(`Opened ${path}`, 'success');
            
        } catch (error) {
            console.error('Error opening file:', error);
            window.aiAssistant.showToast(`Failed to open file: ${error.message}`, 'error');
        }
    }

    createTab(filename, fileData) {
        const tabsContainer = document.getElementById('editor-tabs');
        
        // Remove placeholder if it exists
        const placeholder = tabsContainer.querySelector('.text-center');
        if (placeholder) {
            placeholder.remove();
        }

        const tab = document.createElement('div');
        tab.className = 'editor-tab';
        tab.dataset.file = filename;
        
        const icon = this.getFileIcon(fileData.language);
        tab.innerHTML = `
            <span class="flex items-center space-x-2">
                ${icon}
                <span>${filename.split('/').pop()}</span>
            </span>
            <button class="close-btn ml-2">
                <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6m0 12L6 6"/>
                </svg>
            </button>
        `;

        tab.addEventListener('click', (e) => {
            if (!e.target.closest('.close-btn')) {
                this.switchToFile(filename);
            }
        });

        tab.querySelector('.close-btn').addEventListener('click', (e) => {
            e.stopPropagation();
            this.closeFile(filename);
        });

        tabsContainer.appendChild(tab);
    }

    switchToFile(filename) {
        const fileData = this.openFiles.get(filename);
        if (!fileData) return;

        this.activeFile = filename;
        
        // Update editor
        this.editor.setValue(fileData.content);
        monaco.editor.setModelLanguage(this.editor.getModel(), fileData.language);
        
        // Update UI
        this.updateActiveTab(filename);
        this.updateCurrentFileInfo(fileData);
        
        document.getElementById('save-file-btn').disabled = !fileData.modified;
    }

    updateActiveTab(filename) {
        document.querySelectorAll('.editor-tab').forEach(tab => {
            tab.classList.remove('active');
        });
        
        const activeTab = document.querySelector(`[data-file="${filename}"]`);
        if (activeTab) {
            activeTab.classList.add('active');
        }
    }

    updateCurrentFileInfo(fileData) {
        const info = document.getElementById('current-file-info');
        if (info) {
            const lines = fileData.content.split('\n').length;
            info.textContent = `${fileData.path} (${lines} lines, ${fileData.language})`;
        }
    }

    async closeFile(filename) {
        const fileData = this.openFiles.get(filename);
        if (!fileData) return;

        // Check for unsaved changes
        if (fileData.modified) {
            const confirmed = confirm(`${filename} has unsaved changes. Close anyway?`);
            if (!confirmed) return;
        }

        // Remove from open files
        this.openFiles.delete(filename);
        
        // Remove tab
        const tab = document.querySelector(`[data-file="${filename}"]`);
        if (tab) {
            tab.remove();
        }

        // Switch to another file or show placeholder
        if (this.activeFile === filename) {
            const remainingFiles = Array.from(this.openFiles.keys());
            if (remainingFiles.length > 0) {
                this.switchToFile(remainingFiles[0]);
            } else {
                this.showEditorPlaceholder();
            }
        }
    }

    showEditorPlaceholder() {
        this.activeFile = null;
        this.editor.setValue('');
        
        const tabsContainer = document.getElementById('editor-tabs');
        if (tabsContainer.children.length === 0) {
            tabsContainer.innerHTML = `
                <div class="text-center py-2 text-gray-500 dark:text-gray-400 text-sm">
                    No files open
                </div>
            `;
        }
        
        document.getElementById('current-file-info').textContent = 'No file selected';
        document.getElementById('save-file-btn').disabled = true;
    }

    async saveFile() {
        if (!this.activeFile) return;
        
        const fileData = this.openFiles.get(this.activeFile);
        if (!fileData || !fileData.modified) return;

        try {
            window.aiAssistant.showLoading('Saving file...');
            
            const response = await fetch('/api/ide/files/write', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    path: fileData.path,
                    content: fileData.content
                })
            });

            const result = await response.json();
            
            if (result.error) {
                throw new Error(result.error);
            }

            // Update file data
            fileData.originalContent = fileData.content;
            fileData.modified = false;
            
            // Update UI
            this.updateTabModifiedIndicator(this.activeFile, false);
            document.getElementById('save-file-btn').disabled = true;
            
            window.aiAssistant.showToast(`Saved ${this.activeFile}`, 'success');
            
        } catch (error) {
            console.error('Error saving file:', error);
            window.aiAssistant.showToast(`Failed to save file: ${error.message}`, 'error');
        } finally {
            window.aiAssistant.hideLoading();
        }
    }

    // Event Listeners
    setupEventListeners() {
        // File operations
        document.getElementById('new-file-btn')?.addEventListener('click', () => {
            this.showModal('new-file-modal');
        });

        document.getElementById('save-file-btn')?.addEventListener('click', () => {
            this.saveFile();
        });

        document.getElementById('create-file-btn')?.addEventListener('click', () => {
            this.createNewFile();
        });

        // Sidebar tabs
        document.querySelectorAll('.sidebar-tab').forEach(tab => {
            tab.addEventListener('click', () => {
                this.switchSidebarTab(tab.dataset.tab);
            });
        });

        // Layout controls
        document.getElementById('layout-toggle')?.addEventListener('click', () => {
            this.toggleBottomPanel();
        });

        document.getElementById('toggle-chat')?.addEventListener('click', () => {
            this.toggleChatSidebar();
        });

        // Chat
        document.getElementById('send-message')?.addEventListener('click', () => {
            this.sendChatMessage();
        });

        document.getElementById('chat-input')?.addEventListener('input', () => {
            this.updateTokenCount();
        });

        document.getElementById('chat-input')?.addEventListener('keydown', (e) => {
            if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
                this.sendChatMessage();
            }
        });

        // Git operations
        document.getElementById('git-commit')?.addEventListener('click', () => {
            this.showCommitModal();
        });

        // Theme change listener
        const observer = new MutationObserver(() => {
            if (this.editor) {
                const isDark = document.documentElement.classList.contains('dark');
                this.editor.updateOptions({ theme: isDark ? 'ai-dark' : 'vs' });
            }
        });
        
        observer.observe(document.documentElement, {
            attributes: true,
            attributeFilter: ['class']
        });
    }

    setupKeyboardShortcuts() {
        document.addEventListener('keydown', (e) => {
            // Ctrl+S: Save file
            if ((e.ctrlKey || e.metaKey) && e.key === 's') {
                e.preventDefault();
                this.saveFile();
            }
            
            // Ctrl+N: New file
            if ((e.ctrlKey || e.metaKey) && e.key === 'n') {
                e.preventDefault();
                this.showModal('new-file-modal');
            }
            
            // Ctrl+`: Toggle terminal
            if ((e.ctrlKey || e.metaKey) && e.key === '`') {
                e.preventDefault();
                this.toggleBottomPanel();
            }
        });
    }

    // Chat System
    setupChat() {
        // Initialize chat WebSocket connection
        this.chatWebSocket = window.aiAssistant.createWebSocket('/api/chat/ws/ide-user', {
            onMessage: (data) => this.handleChatMessage(data),
            onError: (error) => console.error('Chat WebSocket error:', error)
        });
    }

    sendChatMessage() {
        const input = document.getElementById('chat-input');
        const message = input.value.trim();
        
        if (!message) return;

        // Add user message to chat
        this.addChatMessage(message, 'user');
        
        // Get current context
        const context = this.getChatContext();
        
        // Send to WebSocket
        if (this.chatWebSocket && this.chatWebSocket.readyState === WebSocket.OPEN) {
            this.chatWebSocket.send(JSON.stringify({
                type: 'chat',
                message: message,
                agent_type: document.getElementById('agent-selector').value,
                context: context
            }));
        }

        input.value = '';
        this.updateTokenCount();
    }

    getChatContext() {
        let context = '';
        
        if (this.activeFile) {
            const fileData = this.openFiles.get(this.activeFile);
            if (fileData) {
                context += `Current file: ${this.activeFile} (${fileData.language})\n`;
                context += `Content:\n${fileData.content.substring(0, 2000)}\n\n`;
            }
        }
        
        return context;
    }

    handleChatMessage(data) {
        if (data.type === 'response') {
            this.addChatMessage(data.message, 'assistant');
        } else if (data.type === 'typing') {
            this.showTypingIndicator();
        } else if (data.type === 'error') {
            window.aiAssistant.showToast(`Chat error: ${data.message}`, 'error');
        }
    }

    addChatMessage(message, role) {
        const messagesContainer = document.getElementById('chat-messages');
        
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${role}`;
        
        const avatar = role === 'user' ? 'You' : 'AI';
        const avatarClass = role === 'user' ? 'user' : 'assistant';
        
        messageDiv.innerHTML = `
            <div class="message-avatar ${avatarClass}">${avatar}</div>
            <div class="message-content">
                <div class="message-text">
                    <p>${this.formatMessage(message)}</p>
                </div>
                <div class="message-time">${new Date().toLocaleTimeString()}</div>
            </div>
        `;
        
        messagesContainer.appendChild(messageDiv);
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }

    formatMessage(message) {
        // Basic markdown-like formatting
        return message
            .replace(/```(\w+)?\n([\s\S]*?)```/g, '<pre><code class="language-$1">$2</code></pre>')
            .replace(/`([^`]+)`/g, '<code>$1</code>')
            .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
            .replace(/\*([^*]+)\*/g, '<em>$1</em>');
    }

    // UI Management
    switchSidebarTab(tabName) {
        document.querySelectorAll('.sidebar-tab').forEach(tab => {
            tab.classList.remove('active');
        });
        
        document.querySelectorAll('.sidebar-panel').forEach(panel => {
            panel.classList.remove('active');
        });
        
        document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');
        document.getElementById(`${tabName}-panel`).classList.add('active');
    }

    toggleBottomPanel() {
        const panel = document.getElementById('bottom-panel');
        panel.classList.toggle('hidden');
        
        if (!panel.classList.contains('hidden')) {
            this.initializeTerminal();
        }
    }

    toggleChatSidebar() {
        const sidebar = document.getElementById('chat-sidebar');
        sidebar.classList.toggle('hidden');
    }

    showModal(modalId) {
        document.getElementById(modalId).classList.remove('hidden');
    }

    async createNewFile() {
        const name = document.getElementById('new-file-name').value;
        const type = document.getElementById('new-file-type').value;
        
        if (!name) {
            window.aiAssistant.showToast('Please enter a file name', 'warning');
            return;
        }

        try {
            const response = await fetch('/api/ide/files/create', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    path: name,
                    content: '',
                    type: 'file'
                })
            });

            const result = await response.json();
            
            if (result.error) {
                throw new Error(result.error);
            }

            // Close modal
            this.closeModal('new-file-modal');
            
            // Refresh file tree
            await this.loadFileTree();
            
            // Open the new file
            await this.openFile(name);
            
            window.aiAssistant.showToast(`Created ${name}`, 'success');
            
        } catch (error) {
            console.error('Error creating file:', error);
            window.aiAssistant.showToast(`Failed to create file: ${error.message}`, 'error');
        }
    }

    closeModal(modalId) {
        document.getElementById(modalId).classList.add('hidden');
        
        // Clear form inputs
        const modal = document.getElementById(modalId);
        modal.querySelectorAll('input, textarea').forEach(input => {
            input.value = '';
        });
    }

    // Terminal functionality (basic implementation)
    initializeTerminal() {
        // This would be expanded with a proper terminal implementation
        console.log('Terminal initialized');
    }
}

// Global modal close function
function closeModal(modalId) {
    if (window.ide) {
        window.ide.closeModal(modalId);
    }
}

// Initialize IDE when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.ide = new IDE();
});