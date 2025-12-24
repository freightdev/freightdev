// Chat functionality for AI Assistant

class ChatInterface {
    constructor() {
        this.websocket = null;
        this.currentConversationId = null;
        this.messageCount = 0;
        this.conversations = [];
        this.isTyping = false;
        this.settings = {
            temperature: 0.7,
            maxTokens: 512,
            autoScroll: true,
            showTimestamps: true,
            syntaxHighlight: true
        };
        
        this.init();
    }

    async init() {
        console.log('Initializing Chat Interface...');
        
        this.loadSettings();
        this.setupEventListeners();
        this.setupWebSocket();
        this.loadConversations();
        this.updateInputState();        
        console.log('Chat Interface initialized');
    }

    // WebSocket Setup
    setupWebSocket() {
        const userId = Date.now();
        const protocol = window.location.protocol === "https:" ? "wss" : "ws";
        const host = window.location.host; // includes port if non-default
        const wsUrl = `${protocol}://${host}/ws/chat-user/${userId}`;
        
        this.websocket = new WebSocket(wsUrl);
    
        this.websocket.onopen = () => {
            console.log('Chat WebSocket connected');
            this.updateConnectionStatus(true);
        };
    
        this.websocket.onmessage = (event) => {
            const data = JSON.parse(event.data);
            this.handleWebSocketMessage(data);
        };
    
        this.websocket.onerror = (error) => {
            console.error('Chat WebSocket error:', error);
            this.updateConnectionStatus(false);
        };
    
        this.websocket.onclose = () => {
            console.log('Chat WebSocket disconnected');
            this.updateConnectionStatus(false);
            setTimeout(() => this.setupWebSocket(), 5000);
        };
    }


    handleWebSocketMessage(data) {
        switch (data.type) {
            case 'message_received':
                // Message was received by server
                break;
                
            case 'typing':
                this.showTypingIndicator();
                break;
                
            case 'response':
                this.hideTypingIndicator();
                this.addMessage(data.message, 'assistant', {
                    messageId: data.message_id,
                    agentType: data.agent_type,
                    generationTime: data.generation_time
                });
                this.updateGenerationStats(data.generation_time);
                break;
                
            case 'error':
                this.hideTypingIndicator();
                window.aiAssistant.showToast(`Chat error: ${data.message}`, 'error');
                break;
                
            default:
                console.log('Unknown message type:', data.type);
        }
    }

    updateConnectionStatus(connected) {
        const statusDot = document.getElementById('chat-status-dot');
        const statusText = document.getElementById('chat-status-text');
        
        if (statusDot && statusText) {
            if (connected) {
                statusDot.className = 'w-2 h-2 rounded-full bg-green-500';
                statusText.textContent = 'Connected';
            } else {
                statusDot.className = 'w-2 h-2 rounded-full bg-red-500';
                statusText.textContent = 'Disconnected';
            }
        }
    }

    // Event Listeners
    setupEventListeners() {
        // Send message
        document.getElementById('send-btn')?.addEventListener('click', () => {
            this.sendMessage();
        });

        // Input handling
        const chatInput = document.getElementById('chat-input');
        chatInput?.addEventListener('input', () => {
            this.updateInputState();
            this.updateCharCount();
        });

        chatInput?.addEventListener('keydown', (e) => {
            if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
                e.preventDefault();
                this.sendMessage();
            }
        });

        // Suggestion buttons
        document.querySelectorAll('.suggestion-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const suggestion = e.currentTarget.querySelector('.font-medium').textContent;
                this.fillInputWithSuggestion(suggestion);
            });
        });

        // Agent selector
        document.getElementById('agent-selector')?.addEventListener('change', (e) => {
            this.updateAgentInfo(e.target.value);
        });

        // UI controls
        document.getElementById('conversations-btn')?.addEventListener('click', () => {
            this.toggleConversationsSidebar();
        });

        document.getElementById('new-chat-btn')?.addEventListener('click', () => {
            this.startNewConversation();
        });

        document.getElementById('chat-settings-btn')?.addEventListener('click', () => {
            this.showSettings();
        });

        // File upload
        document.getElementById('attach-btn')?.addEventListener('click', () => {
            this.showFileUpload();
        });

        // Settings
        this.setupSettingsListeners();
    }

    setupSettingsListeners() {
        // Temperature slider
        const tempSlider = document.getElementById('temperature-slider');
        const tempValue = document.getElementById('temperature-value');
        
        tempSlider?.addEventListener('input', (e) => {
            const value = parseFloat(e.target.value);
            tempValue.textContent = value.toFixed(1);
            this.settings.temperature = value;
            this.saveSettings();
        });

        // Max tokens slider
        const tokensSlider = document.getElementById('max-tokens-slider');
        const tokensValue = document.getElementById('max-tokens-value');
        
        tokensSlider?.addEventListener('input', (e) => {
            const value = parseInt(e.target.value);
            tokensValue.textContent = value;
            this.settings.maxTokens = value;
            this.saveSettings();
        });

        // Checkboxes
        ['auto-scroll', 'show-timestamps', 'code-syntax-highlight'].forEach(id => {
            const checkbox = document.getElementById(id);
            checkbox?.addEventListener('change', (e) => {
                const key = id.replace('-', '').replace('-', '');
                this.settings[key] = e.target.checked;
                this.saveSettings();
            });
        });

        // Export buttons
        document.getElementById('export-md')?.addEventListener('click', () => {
            this.exportConversation('markdown');
        });

        document.getElementById('export-json')?.addEventListener('click', () => {
            this.exportConversation('json');
        });
    }

    // Message Handling
    sendMessage() {
        const input = document.getElementById('chat-input');
        const message = input.value.trim();
        
        if (!message) return;

        // Add user message to UI
        this.addMessage(message, 'user');
        
        // Clear input
        input.value = '';
        this.updateInputState();

        // Hide suggestions after first message
        this.hideSuggestions();

        // Send via WebSocket
        if (this.websocket && this.websocket.readyState === WebSocket.OPEN) {
            this.websocket.send(JSON.stringify({
                type: 'chat',
                message: message,
                conversation_id: this.currentConversationId,
                agent_type: document.getElementById('agent-selector').value,
                temperature: this.settings.temperature,
                max_tokens: this.settings.maxTokens
            }));
        } else {
            window.aiAssistant.showToast('Connection lost. Please wait...', 'warning');
        }
    }

    addMessage(content, role, metadata = {}) {
        const messagesContainer = document.getElementById('chat-messages');
        
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${role} chat-bubble`;
        
        const timestamp = new Date().toLocaleTimeString();
        const avatar = this.getMessageAvatar(role, metadata.agentType);
        
        messageDiv.innerHTML = `
            <div class="flex space-x-4">
                <div class="message-avatar ${role}">
                    ${avatar}
                </div>
                <div class="message-content flex-1">
                    <div class="message-text prose dark:prose-invert max-w-none">
                        ${this.formatMessage(content, role)}
                    </div>
                    ${this.settings.showTimestamps ? `<div class="message-time">${timestamp}</div>` : ''}
                    <div class="message-actions mt-2 space-x-2">
                        <button class="copy-message text-xs text-gray-500 hover:text-gray-700 dark:hover:text-gray-300" title="Copy message">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"/>
                            </svg>
                        </button>
                        ${role === 'assistant' ? `
                        <button class="regenerate-message text-xs text-gray-500 hover:text-gray-700 dark:hover:text-gray-300" title="Regenerate response">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
                            </svg>
                        </button>
                        ` : ''}
                    </div>
                </div>
            </div>
        `;

        // Add event listeners for message actions
        this.setupMessageActions(messageDiv);
        
        messagesContainer.appendChild(messageDiv);
        
        this.messageCount++;
        this.updateConversationInfo();
        
        if (this.settings.autoScroll) {
            this.scrollToBottom();
        }
    }

    getMessageAvatar(role, agentType) {
        if (role === 'user') {
            return `<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
            </svg>`;
        }
        
        // AI avatars based on agent type
        const agentIcons = {
            chat: `<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-3.582 8-8 8a8.955 8.955 0 01-2.172-.268c-.77-.268-1.645-.268-2.208.268L5.172 22H3a2 2 0 01-2-2V12C1 7.582 4.582 4 9 4h12c4.418 0 8 3.582 8 8z"/>
            </svg>`,
            code: `<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"/>
            </svg>`,
            codriver: `<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364-.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"/>
            </svg>`
        };
        
        return agentIcons[agentType] || agentIcons.chat;
    }

    formatMessage(content, role) {
        if (role === 'user') {
            return this.escapeHtml(content).replace(/\n/g, '<br>');
        }
        
        // Format assistant messages with markdown-like formatting
        let formatted = content;
        
        // Code blocks with syntax highlighting
        formatted = formatted.replace(/```(\w+)?\n([\s\S]*?)```/g, (match, lang, code) => {
            const language = lang || 'text';
            const escapedCode = this.escapeHtml(code.trim());
            
            return `<div class="code-block bg-gray-900 dark:bg-gray-800 rounded-lg p-4 my-4 relative">
                <div class="flex justify-between items-center mb-2">
                    <span class="text-sm text-gray-400">${language}</span>
                    <button class="copy-button btn-ghost text-xs" onclick="copyCodeBlock(this)">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"/>
                        </svg>
                        Copy
                    </button>
                </div>
                <pre><code class="language-${language} text-gray-100 font-mono text-sm">${escapedCode}</code></pre>
            </div>`;
        });
        
        // Inline code
        formatted = formatted.replace(/`([^`]+)`/g, '<code class="bg-gray-100 dark:bg-gray-800 px-1 py-0.5 rounded text-sm font-mono">$1</code>');
        
        // Bold text
        formatted = formatted.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
        
        // Italic text
        formatted = formatted.replace(/\*([^*]+)\*/g, '<em>$1</em>');
        
        // Lists
        formatted = formatted.replace(/^- (.+)$/gm, '<li>$1</li>');
        formatted = formatted.replace(/(<li>.*<\/li>)/s, '<ul class="list-disc list-inside space-y-1">$1</ul>');
        
        // Numbered lists
        formatted = formatted.replace(/^\d+\. (.+)$/gm, '<li>$1</li>');
        formatted = formatted.replace(/(<li>.*<\/li>)/s, '<ol class="list-decimal list-inside space-y-1">$1</ol>');
        
        // Line breaks
        formatted = formatted.replace(/\n\n/g, '</p><p>');
        formatted = formatted.replace(/\n/g, '<br>');
        
        // Wrap in paragraph if not already formatted
        if (!formatted.includes('<p>') && !formatted.includes('<div>') && !formatted.includes('<ul>') && !formatted.includes('<ol>')) {
            formatted = `<p>${formatted}</p>`;
        }
        
        return formatted;
    }

    setupMessageActions(messageElement) {
        // Copy message
        const copyBtn = messageElement.querySelector('.copy-message');
        copyBtn?.addEventListener('click', () => {
            const messageText = messageElement.querySelector('.message-text').textContent;
            navigator.clipboard.writeText(messageText).then(() => {
                window.aiAssistant.showToast('Message copied to clipboard', 'success');
            });
        });

        // Regenerate message
        const regenerateBtn = messageElement.querySelector('.regenerate-message');
        regenerateBtn?.addEventListener('click', () => {
            // Find the previous user message and resend it
            const messages = document.querySelectorAll('.message');
            const currentIndex = Array.from(messages).indexOf(messageElement);
            
            for (let i = currentIndex - 1; i >= 0; i--) {
                if (messages[i].classList.contains('user')) {
                    const userMessage = messages[i].querySelector('.message-text').textContent;
                    this.regenerateResponse(userMessage, messageElement);
                    break;
                }
            }
        });
    }

    regenerateResponse(userMessage, oldResponseElement) {
        // Remove the old response
        oldResponseElement.remove();
        
        // Resend the user message
        if (this.websocket && this.websocket.readyState === WebSocket.OPEN) {
            this.websocket.send(JSON.stringify({
                type: 'chat',
                message: userMessage,
                conversation_id: this.currentConversationId,
                agent_type: document.getElementById('agent-selector').value,
                temperature: this.settings.temperature,
                max_tokens: this.settings.maxTokens
            }));
        }
    }

    showTypingIndicator() {
        if (this.isTyping) return;
        
        this.isTyping = true;
        const indicator = document.getElementById('typing-indicator');
        indicator?.classList.remove('hidden');
        
        if (this.settings.autoScroll) {
            this.scrollToBottom();
        }
    }

    hideTypingIndicator() {
        this.isTyping = false;
        const indicator = document.getElementById('typing-indicator');
        indicator?.classList.add('hidden');
    }

    // UI Updates
    updateInputState() {
        const input = document.getElementById('chat-input');
        const sendBtn = document.getElementById('send-btn');
        
        const hasText = input && input.value.trim().length > 0;
        
        if (sendBtn) {
            sendBtn.disabled = !hasText;
        }
    }

    updateCharCount() {
        const input = document.getElementById('chat-input');
        const charCount = document.getElementById('char-count');
        const tokenEstimate = document.getElementById('token-estimate');
        
        if (input && charCount) {
            const length = input.value.length;
            charCount.textContent = `${length} / 4000`;
            
            if (length > 3800) {
                charCount.className = 'text-red-500';
            } else if (length > 3500) {
                charCount.className = 'text-yellow-500';
            } else {
                charCount.className = 'text-gray-500 dark:text-gray-400';
            }
        }
        
        if (tokenEstimate && input) {
            const estimatedTokens = Math.ceil(input.value.split(' ').length * 1.3);
            tokenEstimate.textContent = `~${estimatedTokens} tokens`;
        }
    }

    updateConversationInfo() {
        const titleElement = document.getElementById('conversation-title');
        const countElement = document.getElementById('message-count');
        
        if (countElement) {
            countElement.textContent = `${this.messageCount} messages`;
        }
        
        if (titleElement && this.messageCount === 1) {
            // Generate title from first user message
            const firstMessage = document.querySelector('.message.user .message-text');
            if (firstMessage) {
                const title = this.generateConversationTitle(firstMessage.textContent);
                titleElement.textContent = title;
            }
        }
    }

    updateGenerationStats(generationTime) {
        const stats = document.getElementById('generation-stats');
        const timeElement = document.getElementById('last-generation-time');
        
        if (stats && timeElement) {
            timeElement.textContent = Math.round(generationTime * 1000);
            stats.classList.remove('hidden');
        }
    }

    generateConversationTitle(firstMessage) {
        // Simple title generation from first message
        const words = firstMessage.split(' ').slice(0, 6);
        let title = words.join(' ');
        
        if (title.length > 30) {
            title = title.substring(0, 30) + '...';
        }
        
        return title || 'New Conversation';
    }

    scrollToBottom() {
        const messagesContainer = document.getElementById('chat-messages');
        if (messagesContainer) {
            messagesContainer.scrollTop = messagesContainer.scrollHeight;
        }
    }

    hideSuggestions() {
        const suggestionsContainer = document.getElementById('suggestions-container');
        if (suggestionsContainer) {
            suggestionsContainer.style.display = 'none';
        }
    }

    fillInputWithSuggestion(suggestion) {
        const input = document.getElementById('chat-input');
        if (input) {
            const prompts = {
                'Explain a concept': 'Can you explain the concept of ',
                'Write some code': 'Help me write code to ',
                'Plan a project': 'Help me plan a project to ',
                'Creative writing': 'Help me write a '
            };
            
            const prompt = prompts[suggestion] || suggestion;
            input.value = prompt;
            input.focus();
            this.updateInputState();
        }
    }

    // Conversation Management
    async loadConversations() {
        try {
            const response = await fetch('/api/chat/conversations/chat-user');
            const data = await response.json();
            
            this.conversations = data.conversations || [];
            this.renderConversationsList();
        } catch (error) {
            console.error('Error loading conversations:', error);
        }
    }

    renderConversationsList() {
        const container = document.getElementById('conversations-list');
        if (!container) return;

        if (this.conversations.length === 0) {
            container.innerHTML = `
                <div class="text-center py-8 text-gray-500 dark:text-gray-400">
                    <svg class="w-8 h-8 mx-auto mb-2 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-3.582 8-8 8a8.955 8.955 0 01-2.172-.268c-.77-.268-1.645-.268-2.208.268L5.172 22H3a2 2 0 01-2-2V12C1 7.582 4.582 4 9 4h12c4.418 0 8 3.582 8 8z"/>
                    </svg>
                    <p class="text-sm">No conversations yet</p>
                    <p class="text-xs mt-1">Start a new conversation to begin</p>
                </div>
            `;
            return;
        }

        container.innerHTML = this.conversations.map(conv => `
            <div class="conversation-item p-3 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 cursor-pointer border border-transparent hover:border-gray-200 dark:hover:border-gray-700" data-id="${conv.id}">
                <div class="flex items-start justify-between">
                    <div class="flex-1 min-w-0">
                        <h4 class="text-sm font-medium text-gray-900 dark:text-gray-100 truncate">${conv.title}</h4>
                        <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                            ${window.aiAssistant.formatTimeAgo(conv.updated_at)} • ${conv.agent_type}
                        </p>
                    </div>
                    <button class="delete-conversation opacity-0 hover:opacity-100 text-red-500 hover:text-red-700 ml-2" data-id="${conv.id}">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                        </svg>
                    </button>
                </div>
            </div>
        `).join('');

        // Add event listeners
        container.querySelectorAll('.conversation-item').forEach(item => {
            item.addEventListener('click', (e) => {
                if (!e.target.closest('.delete-conversation')) {
                    this.loadConversation(item.dataset.id);
                }
            });
        });

        container.querySelectorAll('.delete-conversation').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                this.deleteConversation(btn.dataset.id);
            });
        });
    }

    async loadConversation(conversationId) {
        try {
            window.aiAssistant.showLoading('Loading conversation...');
            
            const response = await fetch(`/api/chat/conversations/${conversationId}/messages`);
            const data = await response.json();
            
            if (data.error) {
                throw new Error(data.error);
            }
            
            // Clear current messages
            const messagesContainer = document.getElementById('chat-messages');
            messagesContainer.innerHTML = '';
            
            // Load messages
            data.messages.forEach(msg => {
                this.addMessage(msg.content, msg.role, {
                    messageId: msg.id,
                    agentType: msg.agent_type
                });
            });
            
            this.currentConversationId = conversationId;
            this.messageCount = data.messages.length;
            this.updateConversationInfo();
            
            // Close sidebar
            this.toggleConversationsSidebar(false);
            
        } catch (error) {
            console.error('Error loading conversation:', error);
            window.aiAssistant.showToast('Failed to load conversation', 'error');
        } finally {
            window.aiAssistant.hideLoading();
        }
    }

    startNewConversation() {
        // Clear current conversation
        const messagesContainer = document.getElementById('chat-messages');
        messagesContainer.innerHTML = `
            <div class="message assistant chat-bubble">
                <div class="flex space-x-4">
                    <div class="message-avatar assistant">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364-.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"/>
                        </svg>
                    </div>
                    <div class="message-content flex-1">
                        <div class="message-text prose dark:prose-invert max-w-none">
                            <h3>Welcome to AI Assistant! 🚀</h3>
                            <p>I'm your personal AI assistant, ready to help you with:</p>
                            <ul>
                                <li><strong>General Questions</strong> - Ask me anything you're curious about</li>
                                <li><strong>Programming Help</strong> - Code writing, debugging, and explanations</li>
                                <li><strong>Problem Solving</strong> - Break down complex tasks step by step</li>
                                <li><strong>Creative Tasks</strong> - Writing, brainstorming, and creative projects</li>
                            </ul>
                            <p><em>Choose an agent above or just start chatting - I'll route your message to the right specialist!</em></p>
                        </div>
                        <div class="message-time">Just now</div>
                    </div>
                </div>
            </div>
        `;
        
        // Reset state
        this.currentConversationId = null;
        this.messageCount = 0;
        
        // Show suggestions
        const suggestionsContainer = document.getElementById('suggestions-container');
        if (suggestionsContainer) {
            suggestionsContainer.style.display = 'grid';
        }
        
        // Update UI
        document.getElementById('conversation-title').textContent = 'New Conversation';
        document.getElementById('message-count').textContent = '0 messages';
        document.getElementById('generation-stats').classList.add('hidden');
        
        // Close sidebar
        this.toggleConversationsSidebar(false);
    }

    toggleConversationsSidebar(show = null) {
        const sidebar = document.getElementById('conversations-sidebar');
        if (!sidebar) return;
        
        if (show === null) {
            sidebar.classList.toggle('hidden');
        } else {
            sidebar.classList.toggle('hidden', !show);
        }
    }

    // Settings Management
    loadSettings() {
        const saved = localStorage.getItem('chat-settings');
        if (saved) {
            this.settings = { ...this.settings, ...JSON.parse(saved) };
        }
        
        this.applySettings();
    }

    saveSettings() {
        localStorage.setItem('chat-settings', JSON.stringify(this.settings));
    }

    applySettings() {
        // Update UI controls
        document.getElementById('temperature-slider').value = this.settings.temperature;
        document.getElementById('temperature-value').textContent = this.settings.temperature.toFixed(1);
        
        document.getElementById('max-tokens-slider').value = this.settings.maxTokens;
        document.getElementById('max-tokens-value').textContent = this.settings.maxTokens;
        
        document.getElementById('auto-scroll').checked = this.settings.autoScroll;
        document.getElementById('show-timestamps').checked = this.settings.showTimestamps;
        document.getElementById('code-syntax-highlight').checked = this.settings.syntaxHighlight;
    }

    showSettings() {
        document.getElementById('chat-settings-modal').classList.remove('hidden');
    }

    // Export Functions
    exportConversation(format) {
        const messages = Array.from(document.querySelectorAll('.message')).map(msg => {
            const role = msg.classList.contains('user') ? 'user' : 'assistant';
            const content = msg.querySelector('.message-text').textContent;
            const time = msg.querySelector('.message-time')?.textContent || '';
            
            return { role, content, time };
        });

        if (format === 'markdown') {
            this.exportAsMarkdown(messages);
        } else if (format === 'json') {
            this.exportAsJSON(messages);
        }
        
        this.closeModal('chat-settings-modal');
    }

    exportAsMarkdown(messages) {
        let markdown = `# Chat Conversation\n\n`;
        markdown += `**Date:** ${new Date().toLocaleDateString()}\n\n`;
        
        messages.forEach(msg => {
            const role = msg.role === 'user' ? '**You**' : '**AI Assistant**';
            markdown += `${role}: ${msg.content}\n\n`;
        });
        
        this.downloadFile('conversation.md', markdown, 'text/markdown');
    }

    exportAsJSON(messages) {
        const data = {
            timestamp: new Date().toISOString(),
            conversation_id: this.currentConversationId,
            message_count: messages.length,
            messages: messages
        };
        
        this.downloadFile('conversation.json', JSON.stringify(data, null, 2), 'application/json');
    }

    downloadFile(filename, content, type) {
        const blob = new Blob([content], { type });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }

    // Utility Functions
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    closeModal(modalId) {
        document.getElementById(modalId)?.classList.add('hidden');
    }
}

 // Global functions
function copyCodeBlock(button) {
    const codeBlock = button.closest('.code-block');
    const code = codeBlock.querySelector('code').textContent;
    
    navigator.clipboard.writeText(code).then(() => {
        const originalText = button.innerHTML;
        button.innerHTML = '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg> Copied!';
        
        setTimeout(() => {
            button.innerHTML = originalText;
        }, 2000);
    });
}

// --- Model Loader ---
async function loadAvailableModels() {
    console.log('loadAvailableModels called');
    const selector = document.getElementById('model-selector');
    console.log('selector found:', selector);
    const status = document.getElementById('model-download-status');
    
    if (status) status.textContent = 'Loading models...';

    try {
        const response = await fetch('/api/models');
        const models = await response.json();
        
        // Clear previous options and add new ones
        selector.innerHTML = '';
        const defaultOption = document.createElement('option');
        defaultOption.value = '';
        defaultOption.disabled = true;
        defaultOption.selected = true;
        defaultOption.textContent = 'Select model...';
        selector.appendChild(defaultOption);
        
        models.forEach(model => {
            const option = document.createElement('option');
            option.value = model.json_path;
            option.textContent = `${model.name} ${model.installed ? '✓' : '○'}`;
            selector.appendChild(option);
        });
        
        if (status) status.textContent = `Found ${models.length} models`;
    } catch (err) {
        console.error('Failed to load models:', err);
        selector.innerHTML = '<option value="" disabled selected>Error loading models</option>';
        if (status) status.textContent = 'Error loading models';
    }
}

// WebSocket message handler to update the model progress and status
function handleWebSocketMessages() {
    if (window.chat.websocket) {
        window.chat.websocket.addEventListener("message", function (event) {
            const message = JSON.parse(event.data);

            if (message.type === "status") {
                const status = document.getElementById('model-download-status');
                const progressBar = document.getElementById('download-progress');
                const progressPercentage = document.getElementById('progress-percentage');

                if (message.message.includes("✓") || message.message.includes("loaded")) {
                    // Success state
                    if (progressBar) {
                        progressBar.classList.remove('bg-gradient-blue');
                        progressBar.classList.add('bg-green-500');
                        progressBar.style.width = '100%';
                    }
                    if (progressPercentage) {
                        progressPercentage.textContent = '100%';
                    }
                    if (status) {
                        status.innerHTML = `
                            <div class="flex items-center space-x-2">
                                <div class="checkmark-animate">
                                    <svg class="w-6 h-6 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                                    </svg>
                                </div>
                                <span class="text-sm text-green-600 dark:text-green-400 font-medium">${message.message}</span>
                            </div>
                        `;
                    }

                    // Update model status indicator
                    if (message.model_name) {
                        window.aiAssistant.updateModelStatus({
                            loaded: true,
                            model_name: message.model_name,
                            device: message.device
                        });
                    }

                    // Close modal after a brief delay
                    setTimeout(() => closeModal('model-loading-modal'), 1500);
                } else {
                    if (status) status.innerHTML = `<span class="text-sm text-gray-600 dark:text-gray-300">${message.message}</span>`;
                }
            }

            if (message.type === "error") {
                const status = document.getElementById('model-download-status');
                const progressBar = document.getElementById('download-progress');

                // Check if it's a "No model loaded" error
                if (message.message.includes("No model loaded")) {
                    // Show toast notification
                    window.aiAssistant.showToast('⚠️ ' + message.message, 'warning');
                } else {
                    // Model loading error
                    if (status) {
                        status.innerHTML = `<span class="text-xs text-red-600 dark:text-red-400 font-medium">❌ ${message.message}</span>`;
                    }
                    if (progressBar) {
                        progressBar.classList.remove('bg-blue-600');
                        progressBar.classList.add('bg-red-500');
                    }
                }
            }

            if (message.type === "model_progress") {
                const progress = message.progress;
                const status = message.status || `Loading... ${progress}%`;
                const progressBar = document.getElementById('download-progress');
                const statusEl = document.getElementById('model-download-status');
                const progressPercentage = document.getElementById('progress-percentage');

                if (progressBar) {
                    progressBar.style.width = `${progress}%`;
                    progressBar.style.transition = 'width 0.3s ease-in-out';
                }

                if (progressPercentage) {
                    progressPercentage.textContent = `${progress}%`;
                }

                if (statusEl) {
                    statusEl.innerHTML = `
                        <div class="flex items-center space-x-2">
                            <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-blue-500"></div>
                            <span class="text-sm text-gray-700 dark:text-gray-200">${status}</span>
                        </div>
                    `;
                }
            }
        });
    }
}

// When a model is selected
document.getElementById('model-selector')?.addEventListener('change', async (e) => {
    const jsonPath = e.target.value;
    const modelName = e.target.options[e.target.selectedIndex].text;

    if (!jsonPath) return;

    // Show the modal
    const modal = document.getElementById('model-loading-modal');
    const modelNameEl = document.getElementById('model-loading-name');
    const progressBar = document.getElementById('download-progress');
    const progressPercentage = document.getElementById('progress-percentage');

    if (modal) {
        modal.classList.remove('hidden');
        if (modelNameEl) modelNameEl.textContent = `Loading ${modelName}...`;
        if (progressBar) {
            progressBar.style.width = '0%';
            progressBar.classList.remove('bg-green-500', 'bg-red-500');
            progressBar.classList.add('bg-gradient-blue');
        }
        if (progressPercentage) progressPercentage.textContent = '0%';
    }

    // Send via WebSocket
    if (window.chat.websocket && window.chat.websocket.readyState === WebSocket.OPEN) {
        window.chat.websocket.send(JSON.stringify({
            type: 'load_model',
            model_json: jsonPath
        }));
    } else {
        window.aiAssistant.showToast('WebSocket not connected. Please refresh the page.', 'error');
        if (modal) modal.classList.add('hidden');
    }
});

// Function to close modal
function closeModal(modalId) {
    if (window.chat) {
        window.chat.closeModal(modalId);
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.chat = new ChatInterface();
    loadAvailableModels();
    handleWebSocketMessages();
});