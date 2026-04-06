// Configuration
const API_BASE_URL = 'http://127.0.0.1:8000';
const USER_ID = 'user1';

// State
let state = {
    chats: {},
    currentChatId: null,
    messages: {},
    isLoading: false,
};

// DOM Elements
const menuBtn = document.getElementById('menuBtn');
const newChatBtn = document.getElementById('newChatBtn');
const newChatDrawerBtn = document.getElementById('newChatDrawerBtn');
const drawer = document.getElementById('drawer');
const drawerOverlay = document.getElementById('drawerOverlay');
const closeDrawerBtn = document.getElementById('closeDrawerBtn');
const messageInput = document.getElementById('messageInput');
const sendBtn = document.getElementById('sendBtn');
const attachBtn = document.getElementById('attachBtn');
const messagesContainer = document.getElementById('messagesContainer');
const drawerContent = document.getElementById('drawerContent');

// Initialize
window.addEventListener('DOMContentLoaded', () => {
    initializeApp();
    setupEventListeners();
});

function setupEventListeners() {
    menuBtn.addEventListener('click', toggleDrawer);
    newChatBtn.addEventListener('click', createNewChat);
    newChatDrawerBtn.addEventListener('click', () => {
        createNewChat();
        closeDrawer();
    });
    closeDrawerBtn.addEventListener('click', closeDrawer);
    drawerOverlay.addEventListener('click', closeDrawer);
    sendBtn.addEventListener('click', sendMessage);
    attachBtn.addEventListener('click', () => {
        alert('File upload coming soon! Currently you can send text messages.');
    });

    // Auto-resize textarea
    messageInput.addEventListener('input', () => {
        messageInput.style.height = 'auto';
        messageInput.style.height = Math.min(messageInput.scrollHeight, 120) + 'px';
    });

    // Send on Enter (without Shift)
    messageInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            sendMessage();
        }
    });
}

async function initializeApp() {
    try {
        // Load chats from API
        await loadChats();
        
        // If no chats, create one
        if (Object.keys(state.chats).length === 0) {
            await createNewChat();
        } else {
            // Select first chat
            const firstChatId = Object.keys(state.chats)[0];
            selectChat(firstChatId);
        }
    } catch (error) {
        console.error('Failed to initialize app:', error);
        showMessage('Failed to connect to API. Make sure the backend is running.');
    }
}

async function loadChats() {
    try {
        const response = await fetch(`${API_BASE_URL}/users/${USER_ID}/chats`);
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        const data = await response.json();
        const items = data.items || [];

        state.chats = {};
        state.messages = {};

        items.forEach(item => {
            state.chats[item.id] = {
                id: item.id,
                title: item.title,
                updatedAt: item.updated_at,
            };
            state.messages[item.id] = (item.messages || []).map(msg => ({
                id: msg.id,
                sender: msg.sender,
                content: msg.content,
                createdAt: msg.created_at,
            }));
        });

        renderDrawer();
    } catch (error) {
        console.error('Error loading chats:', error);
        throw error;
    }
}

async function createNewChat() {
    try {
        const response = await fetch(`${API_BASE_URL}/users/${USER_ID}/chats`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ title: 'New Chat' }),
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        const chat = await response.json();
        state.chats[chat.id] = {
            id: chat.id,
            title: chat.title,
            updatedAt: chat.updated_at,
        };
        state.messages[chat.id] = [];

        selectChat(chat.id);
        renderDrawer();
    } catch (error) {
        console.error('Error creating chat:', error);
        alert('Failed to create chat. Check console for details.');
    }
}

function selectChat(chatId) {
    state.currentChatId = chatId;
    renderMessages();
    renderDrawer();
    messageInput.focus();
}

function renderDrawer() {
    const chats = Object.values(state.chats).sort((a, b) => 
        new Date(b.updatedAt) - new Date(a.updatedAt)
    );

    drawerContent.innerHTML = chats.map(chat => `
        <div class="chat-item ${chat.id === state.currentChatId ? 'active' : ''}" 
             data-chat-id="${chat.id}"
             onclick="selectChat('${chat.id}'); closeDrawer();">
            <div class="chat-title" onclick="event.stopPropagation(); startRenameChat('${chat.id}', event)">
                ${escapeHtml(chat.title)}
            </div>
            <div class="chat-actions">
                <button class="chat-action-btn" onclick="event.stopPropagation(); renameChat('${chat.id}')" title="Rename">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                    </svg>
                </button>
                <button class="chat-action-btn delete" onclick="event.stopPropagation(); deleteChat('${chat.id}')" title="Delete">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M3 6h18"></path>
                        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                        <line x1="10" y1="11" x2="10" y2="17"></line>
                        <line x1="14" y1="11" x2="14" y2="17"></line>
                    </svg>
                </button>
            </div>
        </div>
    `).join('');

    if (chats.length === 0) {
        drawerContent.innerHTML = '<div class="loading-text">No chats yet</div>';
    }
}

function renderMessages() {
    const messages = state.messages[state.currentChatId] || [];
    
    if (messages.length === 0) {
        messagesContainer.innerHTML = `
            <div class="welcome-message">
                <h1>LegalEase</h1>
                <p>Your AI-powered legal assistant</p>
                <p class="welcome-subtitle">Start typing to begin a conversation</p>
            </div>
        `;
        return;
    }

    messagesContainer.innerHTML = messages.map((msg, index) => {
        const isUser = msg.sender === 'user';
        const isNew = msg.isNew === true;
        const isEdited = msg.edited_at !== undefined;
        
        return `
            <div class="message-bubble ${msg.sender}" data-message-id="${msg.id}">
                <div class="bubble-content ${msg.sender}">
                    <div class="message-text" contenteditable="false" data-message-id="${msg.id}">
                        ${msg.sender === 'ai' && isNew ? `<span class="typewriter">${escapeHtml(msg.content)}</span>` : escapeHtml(msg.content)}
                    </div>
                    ${isEdited ? '<div class="edited-indicator">(edited)</div>' : ''}
                </div>
                ${isUser ? `
                    <div class="message-actions">
                        <button class="message-action-btn" onclick="editMessage('${msg.id}')" title="Edit">
                            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                            </svg>
                        </button>
                        <button class="message-action-btn delete" onclick="deleteMessage('${msg.id}')" title="Delete">
                            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M3 6h18"></path>
                                <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                                <line x1="10" y1="11" x2="10" y2="17"></line>
                                <line x1="14" y1="11" x2="14" y2="17"></line>
                            </svg>
                        </button>
                    </div>
                ` : ''}
            </div>
        `;
    }).join('');

    // Scroll to bottom
    setTimeout(() => {
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }, 100);
}

async function sendMessage() {
    const content = messageInput.value.trim();
    
    if (!content || !state.currentChatId) {
        return;
    }

    // Add user message to UI immediately
    const userMessage = {
        id: Date.now().toString(),
        sender: 'user',
        content: content,
        createdAt: new Date().toISOString(),
    };

    if (!state.messages[state.currentChatId]) {
        state.messages[state.currentChatId] = [];
    }

    state.messages[state.currentChatId].push(userMessage);
    renderMessages();
    messageInput.value = '';
    messageInput.style.height = 'auto';
    sendBtn.disabled = true;

    try {
        // Send to API - this will create both user and AI messages
        const response = await fetch(`${API_BASE_URL}/chats/${state.currentChatId}/messages`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                user_id: USER_ID,
                sender: 'user',
                content: content,
            }),
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        const result = await response.json();
        
        // Update user message with correct ID from API
        userMessage.id = result.user_message.id;
        
        // Add AI message from API response
        const aiMessage = {
            id: result.assistant_message.id,
            sender: 'ai',
            content: result.assistant_message.content,
            createdAt: result.assistant_message.created_at,
            isNew: true,
        };
        
        state.messages[state.currentChatId].push(aiMessage);

        // Refresh chat list to update timestamps
        await loadChats();
        state.currentChatId = state.currentChatId; // Maintain current chat
        renderMessages();
        renderDrawer();

    } catch (error) {
        console.error('Error sending message:', error);
        alert('Failed to send message. Make sure the API is running.');
        // Remove user message if sending failed
        state.messages[state.currentChatId] = state.messages[state.currentChatId].filter(m => m.id !== userMessage.id);
        renderMessages();
    } finally {
        sendBtn.disabled = false;
        messageInput.focus();
    }
}

async function generateAiResponse(userQuery) {
    // AI responses are now handled by the API backend
    // This function is kept for reference but not used
    return "This response is handled by the API backend.";
}

function toggleDrawer() {
    drawer.classList.toggle('active');
    drawerOverlay.classList.toggle('active');
}

function closeDrawer() {
    drawer.classList.remove('active');
    drawerOverlay.classList.remove('active');
}

function showMessage(text) {
    const placeholder = document.createElement('div');
    placeholder.style.cssText = `
        position: fixed;
        top: 20px;
        left: 50%;
        transform: translateX(-50%);
        background: #FCE566;
        color: #131313;
        padding: 16px 24px;
        border-radius: 8px;
        font-weight: 600;
        z-index: 2000;
        max-width: 80%;
        text-align: center;
    `;
    placeholder.textContent = text;
    document.body.appendChild(placeholder);
    
    setTimeout(() => placeholder.remove(), 4000);
}

function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;',
    };
    return text.replace(/[&<>"']/g, m => map[m]);
}

function startRenameChat(chatId, event) {
    if (event && event.stopPropagation) {
        event.stopPropagation();
    }
    renameChat(chatId);
}

async function renameChat(chatId) {
    const chat = state.chats[chatId];
    if (!chat) return;

    const newTitle = prompt('Enter new chat title:', chat.title);
    if (!newTitle || newTitle.trim() === chat.title) return;

    try {
        const response = await fetch(`${API_BASE_URL}/chats/${chatId}`, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ title: newTitle.trim() }),
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        const updatedChat = await response.json();
        state.chats[chatId].title = updatedChat.title;
        renderDrawer();
        showMessage('Chat renamed successfully');
    } catch (error) {
        console.error('Error renaming chat:', error);
        alert('Failed to rename chat. Check console for details.');
    }
}

async function deleteChat(chatId) {
    if (!confirm('Are you sure you want to delete this chat? This action cannot be undone.')) {
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/chats/${chatId}`, {
            method: 'DELETE',
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        delete state.chats[chatId];
        delete state.messages[chatId];

        // If we deleted the current chat, select another one
        if (state.currentChatId === chatId) {
            const remainingChats = Object.keys(state.chats);
            state.currentChatId = remainingChats.length > 0 ? remainingChats[0] : null;
        }

        renderDrawer();
        if (state.currentChatId) {
            renderMessages();
        } else {
            // No chats left, show welcome message
            renderMessages();
        }
        showMessage('Chat deleted successfully');
    } catch (error) {
        console.error('Error deleting chat:', error);
        alert('Failed to delete chat. Check console for details.');
    }
}

// Message management functions
let editingMessageId = null;

async function editMessage(messageId) {
    if (editingMessageId) {
        // Cancel previous edit
        cancelEdit();
    }

    const messageElement = document.querySelector(`[data-message-id="${messageId}"] .message-text`);
    if (!messageElement) return;

    const originalContent = messageElement.textContent;
    messageElement.contentEditable = true;
    messageElement.focus();

    // Select all text
    const range = document.createRange();
    range.selectNodeContents(messageElement);
    const selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);

    editingMessageId = messageId;

    // Add save/cancel buttons
    const bubble = messageElement.closest('.message-bubble');
    const actionsDiv = bubble.querySelector('.message-actions');
    
    // Temporarily replace action buttons
    const originalActions = actionsDiv.innerHTML;
    actionsDiv.innerHTML = `
        <button class="message-action-btn save" onclick="saveEdit('${messageId}')" title="Save">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="20,6 9,17 4,12"></polyline>
            </svg>
        </button>
        <button class="message-action-btn cancel" onclick="cancelEdit()" title="Cancel">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="18" y1="6" x2="6" y2="18"></line>
                <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
        </button>
    `;

    // Store original content for cancel
    messageElement.dataset.originalContent = originalContent;
}

async function saveEdit(messageId) {
    const messageElement = document.querySelector(`[data-message-id="${messageId}"] .message-text`);
    if (!messageElement) return;

    const newContent = messageElement.textContent.trim();
    if (!newContent) {
        alert('Message cannot be empty');
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/chats/${state.currentChatId}/messages/${messageId}`, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ content: newContent }),
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        const result = await response.json();
        
        // Update local state
        const messages = state.messages[state.currentChatId];
        const messageIndex = messages.findIndex(m => m.id === messageId);
        if (messageIndex !== -1) {
            messages[messageIndex].content = newContent;
            messages[messageIndex].edited_at = result.edited_at;
        }

        renderMessages();
        editingMessageId = null;
        showMessage('Message edited successfully');
    } catch (error) {
        console.error('Error editing message:', error);
        alert('Failed to edit message. Check console for details.');
    }
}

function cancelEdit() {
    if (!editingMessageId) return;

    const messageElement = document.querySelector(`[data-message-id="${editingMessageId}"] .message-text`);
    if (messageElement) {
        messageElement.contentEditable = false;
        messageElement.textContent = messageElement.dataset.originalContent;
        
        // Restore original action buttons
        const bubble = messageElement.closest('.message-bubble');
        const actionsDiv = bubble.querySelector('.message-actions');
        actionsDiv.innerHTML = `
            <button class="message-action-btn" onclick="editMessage('${editingMessageId}')" title="Edit">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                </svg>
            </button>
            <button class="message-action-btn delete" onclick="deleteMessage('${editingMessageId}')" title="Delete">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M3 6h18"></path>
                    <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                    <line x1="10" y1="11" x2="10" y2="17"></line>
                    <line x1="14" y1="11" x2="14" y2="17"></line>
                </svg>
            </button>
        `;
    }

    editingMessageId = null;
}

async function deleteMessage(messageId) {
    if (!confirm('Are you sure you want to delete this message? This will also delete all subsequent messages in the conversation.')) {
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/chats/${state.currentChatId}/messages/${messageId}`, {
            method: 'DELETE',
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        // Refresh chat data to get updated messages
        await loadChats();
        state.currentChatId = state.currentChatId; // Maintain current chat
        renderMessages();
        renderDrawer();
        showMessage('Message deleted successfully');
    } catch (error) {
        console.error('Error deleting message:', error);
        alert('Failed to delete message. Check console for details.');
    }
}
