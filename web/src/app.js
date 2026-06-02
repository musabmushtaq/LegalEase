// Configuration
const API_BASE_URL = 'http://127.0.0.1:8000';
const DEFAULT_USER_ID = 'user1';
const DEFAULT_USERNAME = 'Guest';
const CHAT_CACHE_KEY = 'legaleaseWebChatCache';
const AUTH_CACHE_KEY = 'legaleaseWebAuth';

const state = {
    chats: {},
    messages: {},
    currentChatId: null,
    authToken: null,
    userId: null,
    username: DEFAULT_USERNAME,
    isConnected: true,
    isTemporaryChat: false,
    searchQuery: '',
    searchResults: null,
    attachment: null,
    authMode: 'login',
};

const menuBtn = document.getElementById('menuBtn');
const newChatBtn = document.getElementById('newChatBtn');
const drawer = document.getElementById('drawer');
const drawerOverlay = document.getElementById('drawerOverlay');
const closeDrawerBtn = document.getElementById('closeDrawerBtn');
const messageInput = document.getElementById('messageInput');
const sendBtn = document.getElementById('sendBtn');
const attachBtn = document.getElementById('attachBtn');
const messagesContainer = document.getElementById('messagesContainer');
const drawerContent = document.getElementById('drawerContent');
const drawerSearch = document.getElementById('drawerSearch');
const connectionBanner = document.getElementById('connectionBanner');
const attachmentInput = document.getElementById('attachmentInput');
const attachmentPreview = document.getElementById('attachmentPreview');
const attachmentName = document.getElementById('attachmentName');
const removeAttachmentBtn = document.getElementById('removeAttachmentBtn');
const tempChatToggleBtn = document.getElementById('tempChatToggleBtn');
const authActionBtn = document.getElementById('authActionBtn');
const userStatus = document.getElementById('userStatus');
const authModal = document.getElementById('authModal');
const authForm = document.getElementById('authForm');
const authTitle = document.getElementById('authTitle');
const authSwitchBtn = document.getElementById('authSwitchBtn');
const authSwitchText = document.getElementById('authSwitchText');
const authCloseBtn = document.getElementById('authCloseBtn');
const authUsername = document.getElementById('authUsername');
const authEmailLabel = document.getElementById('authEmailLabel');
const authEmail = document.getElementById('authEmail');
const authPassword = document.getElementById('authPassword');
const authConfirmLabel = document.getElementById('authConfirmLabel');
const authConfirmPassword = document.getElementById('authConfirmPassword');
const authSubmitBtn = document.getElementById('authSubmitBtn');

let editingMessageId = null;
let searchTimer = null;

window.addEventListener('DOMContentLoaded', () => {
    initializeApp();
    setupEventListeners();
});

function setupEventListeners() {
    menuBtn.addEventListener('click', toggleDrawer);
    newChatBtn.addEventListener('click', createNewChat);
    closeDrawerBtn.addEventListener('click', closeDrawer);
    drawerOverlay.addEventListener('click', closeDrawer);
    sendBtn.addEventListener('click', sendMessage);
    attachBtn.addEventListener('click', () => attachmentInput.click());
    attachmentInput.addEventListener('change', handleAttachmentSelection);
    removeAttachmentBtn.addEventListener('click', () => {
        state.attachment = null;
        attachmentInput.value = '';
        attachmentPreview.classList.add('hidden');
    });
    drawerSearch.addEventListener('input', handleSearchInput);
    tempChatToggleBtn.addEventListener('click', toggleTemporaryChatMode);
    authActionBtn.addEventListener('click', () => {
        if (state.authToken) {
            logout();
        } else {
            openAuthModal('login');
        }
    });
    authForm.addEventListener('submit', handleAuthSubmit);
    authSwitchBtn.addEventListener('click', toggleAuthMode);
    authCloseBtn.addEventListener('click', closeAuthModal);

    messageInput.addEventListener('input', () => {
        messageInput.style.height = 'auto';
        messageInput.style.height = Math.min(messageInput.scrollHeight, 120) + 'px';
    });

    messageInput.addEventListener('keydown', (event) => {
        if (event.key === 'Enter' && !event.shiftKey) {
            event.preventDefault();
            sendMessage();
        }
    });
}

function getAuthorizedHeaders(isJson = true) {
    const headers = {};
    if (isJson) {
        headers['Content-Type'] = 'application/json';
    }
    if (state.authToken) {
        headers['Authorization'] = `Bearer ${state.authToken}`;
    }
    return headers;
}

function loadAuthState() {
    try {
        const saved = JSON.parse(localStorage.getItem(AUTH_CACHE_KEY) || 'null');
        if (saved && saved.userId && saved.authToken) {
            state.userId = saved.userId;
            state.authToken = saved.authToken;
            state.username = saved.username || DEFAULT_USERNAME;
        }
    } catch (_) {
        state.userId = null;
        state.authToken = null;
        state.username = DEFAULT_USERNAME;
    }
}

function saveAuthState() {
    if (state.authToken && state.userId) {
        localStorage.setItem(AUTH_CACHE_KEY, JSON.stringify({
            userId: state.userId,
            authToken: state.authToken,
            username: state.username,
        }));
    }
}

function clearAuthState() {
    localStorage.removeItem(AUTH_CACHE_KEY);
    state.authToken = null;
    state.userId = null;
    state.username = DEFAULT_USERNAME;
}

function loadChatCache() {
    try {
        const raw = localStorage.getItem(CHAT_CACHE_KEY);
        if (!raw) return;
        const cached = JSON.parse(raw);
        state.chats = cached.chats || {};
        state.messages = cached.messages || {};
        state.currentChatId = cached.currentChatId || Object.keys(state.chats)[0] || null;
        state.isTemporaryChat = cached.isTemporaryChat || false;
    } catch (_) {
        state.chats = {};
        state.messages = {};
        state.currentChatId = null;
    }
}

function saveChatCache() {
    localStorage.setItem(CHAT_CACHE_KEY, JSON.stringify({
        chats: state.chats,
        messages: state.messages,
        currentChatId: state.currentChatId,
        isTemporaryChat: state.isTemporaryChat,
    }));
}

async function checkConnectivity() {
    try {
        const response = await fetch(`${API_BASE_URL}/health`, { cache: 'no-store' });
        state.isConnected = response.ok;
    } catch (_) {
        state.isConnected = false;
    }
    renderConnectionBanner();
    if (state.isConnected && !state.isTemporaryChat) {
        try {
            await loadChats();
        } catch (_) {
            // keep local cache
        }
    }
    setTimeout(checkConnectivity, 20000);
}

function renderConnectionBanner() {
    if (state.isConnected) {
        connectionBanner.classList.add('hidden');
    } else {
        connectionBanner.textContent = 'Offline mode active. Some features may not be available.';
        connectionBanner.classList.remove('hidden');
    }
}

async function initializeApp() {
    loadAuthState();
    loadChatCache();
    renderUserState();
    renderTemporaryToggle();
    renderConnectionBanner();
    await checkConnectivity();

    if (state.isConnected && !state.isTemporaryChat) {
        try {
            await loadChats();
        } catch (_) {
            // continue with cache
        }
    }

    if (!state.currentChatId) {
        const firstChatId = Object.keys(state.chats)[0];
        if (firstChatId) {
            state.currentChatId = firstChatId;
        }
    }

    if (!state.currentChatId) {
        createLocalChat();
    }

    renderDrawer();
    renderMessages();
    if (!state.isConnected) {
        showMessage('Offline mode is active. Some features are limited.');
    }
}

function renderUserState() {
    userStatus.textContent = state.authToken ? state.username : (state.isTemporaryChat ? `${DEFAULT_USERNAME} (Temporary)` : DEFAULT_USERNAME);
    authActionBtn.textContent = state.authToken ? 'Logout' : 'Login / Sign Up';
}

function openAuthModal(mode) {
    state.authMode = mode;
    authModal.classList.remove('hidden');
    if (mode === 'login') {
        authTitle.textContent = 'Login to LegalEase';
        authSubmitBtn.textContent = 'Login';
        authSwitchText.textContent = "Don't have an account?";
        authSwitchBtn.textContent = 'Sign up';
        authEmailLabel.classList.add('hidden');
        authConfirmLabel.classList.add('hidden');
    } else {
        authTitle.textContent = 'Sign up for LegalEase';
        authSubmitBtn.textContent = 'Sign Up';
        authSwitchText.textContent = 'Already have an account?';
        authSwitchBtn.textContent = 'Login';
        authEmailLabel.classList.remove('hidden');
        authConfirmLabel.classList.remove('hidden');
    }
}

function closeAuthModal() {
    authModal.classList.add('hidden');
    authForm.reset();
}

function toggleAuthMode() {
    openAuthModal(state.authMode === 'login' ? 'signup' : 'login');
}

async function handleAuthSubmit(event) {
    event.preventDefault();
    const username = authUsername.value.trim();
    const password = authPassword.value.trim();
    const email = authEmail.value.trim();
    const confirmPassword = authConfirmPassword.value.trim();

    if (!username || !password) {
        alert('Please fill in username and password.');
        return;
    }

    if (state.authMode === 'signup') {
        if (!email) {
            alert('Please enter your email address.');
            return;
        }
        if (password !== confirmPassword) {
            alert('Passwords do not match.');
            return;
        }
        await registerUser(username, email, password);
    } else {
        await loginUser(username, password);
    }
}

async function loginUser(username, password) {
    try {
        const response = await fetch(`${API_BASE_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password }),
        });
        if (!response.ok) {
            throw new Error('Invalid login');
        }
        const data = await response.json();
        state.authToken = data.access_token;
        state.userId = data.user_id;
        state.username = username;
        saveAuthState();
        renderUserState();
        closeAuthModal();
        await loadChats();
        renderDrawer();
        renderMessages();
        showMessage('Logged in successfully');
    } catch (error) {
        console.error('Login failed:', error);
        alert('Login failed. Please check your credentials.');
    }
}

async function registerUser(username, email, password) {
    try {
        const response = await fetch(`${API_BASE_URL}/auth/register`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, email, password }),
        });
        if (!response.ok) {
            throw new Error('Registration failed');
        }
        await loginUser(username, password);
    } catch (error) {
        console.error('Signup failed:', error);
        alert('Signup failed. Username or email may already be taken.');
    }
}

function logout() {
    clearAuthState();
    state.isTemporaryChat = true;
    renderUserState();
    renderTemporaryToggle();
    saveChatCache();
    showMessage('Logged out. Temporary chat mode enabled.');
}

function renderTemporaryToggle() {
    tempChatToggleBtn.textContent = state.isTemporaryChat ? 'Temporary Chat: ON' : 'Temporary Chat: OFF';
}

function toggleTemporaryChatMode() {
    state.isTemporaryChat = !state.isTemporaryChat;
    if (state.isTemporaryChat) {
        clearAuthState();
    }
    renderUserState();
    renderTemporaryToggle();
    saveChatCache();
    showMessage(state.isTemporaryChat ? 'Temporary chat mode enabled.' : 'Temporary chat mode disabled.');
}

async function loadChats() {
    if (!state.userId) {
        state.userId = DEFAULT_USER_ID;
    }
    const response = await fetch(`${API_BASE_URL}/users/${state.userId}/chats`, {
        headers: getAuthorizedHeaders(),
    });
    if (!response.ok) {
        throw new Error(`Failed to load chats: ${response.status}`);
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
            isPinned: item.is_pinned || false,
        };
        state.messages[item.id] = (item.messages || []).map(msg => ({
            id: msg.id,
            sender: msg.sender,
            content: msg.content,
            createdAt: msg.created_at,
            edited_at: msg.edited_at,
            isNew: false,
        }));
    });
    if (!state.currentChatId && items.length > 0) {
        state.currentChatId = items[0].id;
    }
    saveChatCache();
}

async function createNewChat() {
    if (!state.isConnected || state.isTemporaryChat) {
        createLocalChat();
        return;
    }
    const userId = state.userId || DEFAULT_USER_ID;
    try {
        const response = await fetch(`${API_BASE_URL}/users/${userId}/chats`, {
            method: 'POST',
            headers: getAuthorizedHeaders(),
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
            isPinned: chat.is_pinned || false,
        };
        state.messages[chat.id] = [];
        state.currentChatId = chat.id;
        saveChatCache();
        renderDrawer();
        renderMessages();
    } catch (error) {
        console.warn('Could not create server chat, creating local chat instead.', error);
        createLocalChat();
    }
}

function createLocalChat() {
    const chatId = `local_${Date.now()}`;
    const now = new Date().toISOString();
    state.chats[chatId] = {
        id: chatId,
        title: 'New Chat',
        updatedAt: now,
        isPinned: false,
    };
    state.messages[chatId] = [];
    state.currentChatId = chatId;
    saveChatCache();
    renderDrawer();
    renderMessages();
}

function selectChat(chatId) {
    state.currentChatId = chatId;
    saveChatCache();
    renderMessages();
    renderDrawer();
    messageInput.focus();
}

function renderDrawer() {
    const searchMode = state.searchQuery.trim().length > 0;
    const chats = searchMode
        ? (state.searchResults || [])
        : Object.values(state.chats).sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt));

    if (!searchMode) {
        const pinnedChats = chats.filter(c => c.isPinned);
        const recentChats = chats.filter(c => !c.isPinned);
        const html = [];
        if (pinnedChats.length > 0) {
            html.push(pinnedChats.map(chat => chatItemHtml(chat)).join(''));
        }
        if (recentChats.length > 0) {
            if (pinnedChats.length > 0) {
                html.push('<div class="drawer-section-separator"></div>');
            }
            html.push(recentChats.map(chat => chatItemHtml(chat)).join(''));
        }
        drawerContent.innerHTML = html.length > 0 ? html.join('') : '<div class="loading-text">No chats yet</div>';
        return;
    }
    drawerContent.innerHTML = chats.length > 0 ? chats.map(chat => chatItemHtml(chat)).join('') : '<div class="loading-text">No matching chats found</div>';
}

function chatItemHtml(chat) {
    return `
        <div class="chat-item ${chat.id === state.currentChatId ? 'active' : ''}" data-chat-id="${chat.id}" onclick="selectChat('${chat.id}'); closeDrawer();">
            <div class="chat-title">${escapeHtml(chat.title)}</div>
            <div class="chat-actions">
                <button class="chat-action-btn" onclick="event.stopPropagation(); togglePinChat('${chat.id}')" title="Pin / unpin chat">${chat.isPinned ? '★' : '☆'}</button>
                <button class="chat-action-btn" onclick="event.stopPropagation(); promptRenameChat('${chat.id}')" title="Rename chat">✎</button>
                <button class="chat-action-btn delete" onclick="event.stopPropagation(); deleteChat('${chat.id}')" title="Delete chat">🗑</button>
            </div>
        </div>
    `;
}

async function handleSearchInput(event) {
    state.searchQuery = event.target.value.trim();
    if (searchTimer) {
        clearTimeout(searchTimer);
    }
    searchTimer = setTimeout(performSearch, 300);
}

async function performSearch() {
    const query = state.searchQuery;
    if (!query) {
        state.searchResults = null;
        renderDrawer();
        return;
    }
    if (state.isConnected && state.userId) {
        try {
            const response = await fetch(`${API_BASE_URL}/users/${state.userId}/search?query=${encodeURIComponent(query)}`, {
                headers: getAuthorizedHeaders(false),
            });
            if (response.ok) {
                const data = await response.json();
                state.searchResults = (data.items || []).map(item => ({
                    id: item.id,
                    title: item.title,
                    updatedAt: item.updated_at,
                    isPinned: item.is_pinned || false,
                }));
                renderDrawer();
                return;
            }
        } catch (_) {
            // fallback to local search
        }
    }
    state.searchResults = Object.values(state.chats).filter(chat => {
        const titleMatch = chat.title.toLowerCase().includes(query.toLowerCase());
        const messageMatch = (state.messages[chat.id] || []).some(msg => msg.content.toLowerCase().includes(query.toLowerCase()));
        return titleMatch || messageMatch;
    });
    renderDrawer();
}

function renderMessages() {
    const messages = state.currentChatId ? (state.messages[state.currentChatId] || []) : [];
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
    messagesContainer.innerHTML = messages.map(msg => {
        const isUser = msg.sender === 'user';
        const isNew = msg.isNew === true;
        const isEdited = msg.edited_at !== undefined;
        return `
            <div class="message-bubble ${msg.sender}" data-message-id="${msg.id}">
                <div class="bubble-content ${msg.sender}">
                    <div class="message-text" contenteditable="false" data-message-id="${msg.id}">${msg.sender === 'ai' && isNew ? `<span class="typewriter">${escapeHtml(msg.content)}</span>` : escapeHtml(msg.content)}</div>
                    ${isEdited ? '<div class="edited-indicator">(edited)</div>' : ''}
                </div>

            </div>
        `;
    }).join('');
    setTimeout(() => {
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }, 100);
}

async function ensureConnectivity() {
    if (state.isConnected) {
        return true;
    }
    try {
        const response = await fetch(`${API_BASE_URL}/health`, { cache: 'no-store' });
        state.isConnected = response.ok;
    } catch (_) {
        state.isConnected = false;
    }
    renderConnectionBanner();
    return state.isConnected;
}

async function sendMessage() {
    const content = messageInput.value.trim();
    const file = state.attachment;
    if (!content && !file) {
        return;
    }
    if (!state.currentChatId) {
        await createNewChat();
    }
    if (!state.currentChatId) return;
    if (!state.isConnected && !state.isTemporaryChat) {
        await ensureConnectivity();
    }
    const currentChatId = state.currentChatId;
    const userMessage = {
        id: `local_${Date.now()}`,
        sender: 'user',
        content: content || 'Sent an attachment',
        createdAt: new Date().toISOString(),
    };
    state.messages[currentChatId] = state.messages[currentChatId] || [];
    state.messages[currentChatId].push(userMessage);
    renderMessages();
    messageInput.value = '';
    messageInput.style.height = 'auto';
    sendBtn.disabled = true;
    state.attachment = null;
    attachmentInput.value = '';
    attachmentPreview.classList.add('hidden');
    if (!state.isConnected || state.isTemporaryChat) {
        state.messages[currentChatId].push({
            id: `local_ai_${Date.now()}`,
            sender: 'ai',
            content: 'Backend unavailable or network error. Please ensure API is reachable.',
            createdAt: new Date().toISOString(),
            isNew: false,
        });
        saveChatCache();
        renderMessages();
        sendBtn.disabled = false;
        return;
    }
    try {
        let response;
        if (file) {
            const formData = new FormData();
            formData.append('content', content || 'Sent an attachment');
            formData.append('file', file);
            response = await fetch(`${API_BASE_URL}/chats/${currentChatId}/messages_with_file`, {
                method: 'POST',
                body: formData,
                headers: state.authToken ? { Authorization: `Bearer ${state.authToken}` } : {},
            });
        } else {
            response = await fetch(`${API_BASE_URL}/chats/${currentChatId}/messages`, {
                method: 'POST',
                headers: getAuthorizedHeaders(),
                body: JSON.stringify({
                    user_id: state.userId || DEFAULT_USER_ID,
                    sender: 'user',
                    content: content,
                }),
            });
        }
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        const result = await response.json();
        const aiMessage = {
            id: result.assistant_message.id,
            sender: 'ai',
            content: result.assistant_message.content,
            createdAt: result.assistant_message.created_at,
            isNew: true,
        };
        state.messages[currentChatId].push(aiMessage);
        await loadChats();
        selectChat(currentChatId);
    } catch (error) {
        console.error('Error sending message:', error);
        alert('Failed to send message. Check console for details.');
        state.messages[currentChatId] = state.messages[currentChatId].filter(m => m.id !== userMessage.id);
        renderMessages();
    } finally {
        sendBtn.disabled = false;
    }
}

async function togglePinChat(chatId) {
    const chat = state.chats[chatId];
    if (!chat) return;
    const nextPinned = !chat.isPinned;
    if (state.isConnected && !state.isTemporaryChat) {
        try {
            await fetch(`${API_BASE_URL}/chats/${chatId}`, {
                method: 'PATCH',
                headers: getAuthorizedHeaders(),
                body: JSON.stringify({ is_pinned: nextPinned }),
            });
        } catch (_) {
            // ignore network failure
        }
    }
    chat.isPinned = nextPinned;
    saveChatCache();
    renderDrawer();
}

function promptRenameChat(chatId) {
    const chat = state.chats[chatId];
    if (!chat) return;
    const newTitle = prompt('Enter new chat title:', chat.title);
    if (!newTitle || newTitle.trim() === '' || newTitle.trim() === chat.title) return;
    updateChatTitle(chatId, newTitle.trim());
}

async function updateChatTitle(chatId, newTitle) {
    const chat = state.chats[chatId];
    if (!chat) return;
    if (state.isConnected && !state.isTemporaryChat) {
        try {
            const response = await fetch(`${API_BASE_URL}/chats/${chatId}`, {
                method: 'PATCH',
                headers: getAuthorizedHeaders(),
                body: JSON.stringify({ title: newTitle }),
            });
            if (response.ok) {
                const updated = await response.json();
                chat.title = updated.title;
                chat.updatedAt = updated.updated_at;
            } else {
                chat.title = newTitle;
            }
        } catch (_) {
            chat.title = newTitle;
        }
    } else {
        chat.title = newTitle;
    }
    saveChatCache();
    renderDrawer();
}

function handleAttachmentSelection() {
    const file = attachmentInput.files[0];
    if (!file) {
        state.attachment = null;
        attachmentPreview.classList.add('hidden');
        return;
    }
    state.attachment = file;
    attachmentName.textContent = file.name;
    attachmentPreview.classList.remove('hidden');
}

async function editMessage(messageId) {
    if (editingMessageId) {
        cancelEdit();
    }
    const messageElement = document.querySelector(`[data-message-id="${messageId}"] .message-text`);
    if (!messageElement) return;
    const originalContent = messageElement.textContent;
    messageElement.contentEditable = true;
    messageElement.focus();
    const range = document.createRange();
    range.selectNodeContents(messageElement);
    const selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
    editingMessageId = messageId;
    const bubble = messageElement.closest('.message-bubble');
    const actionsDiv = bubble.querySelector('.message-actions');
    const originalActions = actionsDiv.innerHTML;
    actionsDiv.innerHTML = `
        <button class="message-action-btn save" onclick="saveEdit('${messageId}')" title="Save">✔</button>
        <button class="message-action-btn cancel" onclick="cancelEdit()" title="Cancel">✕</button>
    `;
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
            headers: getAuthorizedHeaders(),
            body: JSON.stringify({ content: newContent }),
        });
        if (!response.ok) {
            throw new Error('Failed to edit message');
        }
        const result = await response.json();
        const messages = state.messages[state.currentChatId] || [];
        const index = messages.findIndex(m => m.id === messageId);
        if (index !== -1) {
            messages[index].content = newContent;
            messages[index].edited_at = result.edited_at;
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
    if (!messageElement) return;
    messageElement.contentEditable = false;
    messageElement.textContent = messageElement.dataset.originalContent;
    const bubble = messageElement.closest('.message-bubble');
    const actionsDiv = bubble.querySelector('.message-actions');
    actionsDiv.innerHTML = `
        <button class="message-action-btn" onclick="editMessage('${editingMessageId}')" title="Edit">✎</button>
        <button class="message-action-btn delete" onclick="deleteMessage('${editingMessageId}')" title="Delete">🗑</button>
    `;
    editingMessageId = null;
}

async function deleteMessage(messageId) {
    if (!confirm('Are you sure you want to delete this message? This will also delete all subsequent messages in the conversation.')) {
        return;
    }
    try {
        const response = await fetch(`${API_BASE_URL}/chats/${state.currentChatId}/messages/${messageId}`, {
            method: 'DELETE',
            headers: getAuthorizedHeaders(),
        });
        if (!response.ok) {
            throw new Error('Failed to delete message');
        }
        await loadChats();
        renderMessages();
        renderDrawer();
        showMessage('Message deleted successfully');
    } catch (error) {
        console.error('Error deleting message:', error);
        alert('Failed to delete message. Check console for details.');
    }
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
    const toast = document.createElement('div');
    toast.className = 'toast-message';
    toast.textContent = text;
    document.body.appendChild(toast);
    setTimeout(() => toast.remove(), 4000);
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
