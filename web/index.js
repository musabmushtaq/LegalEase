// Main application entry point
import { API_BASE_URL, state, CONNECTIVITY_CHECK_INTERVAL, DEFAULT_USER_ID } from './js/config.js';
import { loadAuthState, saveAuthState, clearAuthState, handleLogin, handleRegister, handleLogout, toggleTemporaryMode, ensureUserId } from './js/auth.js';
import { loadChatCache, saveChatCache, loadChatsFromServer, createNewChat, createLocalChat, selectChat, renameChat, togglePinChat, removeChat, searchChatsServer, searchChatsLocal, getCurrentChat, getCurrentMessages } from './js/chat.js';
import { initializeDOM, toggleDrawer, closeDrawer, renderUserState, renderTemporaryToggle, renderConnectionBanner, openAuthModal, closeAuthModal, openShareModal, closeShareModal, renderDrawer, renderMessages, getUIElements, updateAttachmentPreview, openSettingsModal, closeSettingsModal } from './js/ui.js';
import { checkHealth, sendMessage as apiSendMessage, updateMessage as apiUpdateMessage, deleteMessage as apiDeleteMessage, shareChat as apiShareChat, getSharedChat } from './js/api.js';
import { debounce, showMessage, logError } from './js/utils.js';

// Global state for UI interactions
let editingMessageId = null;
let connectivityInterval = null;
let currentChatShareInfo = null;

// UI interaction handlers - exposed globally for HTML onclick handlers
window.selectChatUI = selectChatUI;
window.togglePinChatUI = togglePinChatUI;
window.renameChatUI = renameChatUI;
window.deleteChatUI = deleteChatUI;
window.editMessageUI = editMessageUI;
window.deleteMessageUI = deleteMessageUI;
window.openShareModalUI = openShareModalUI;
window.toggleChatShareUI = toggleChatShareUI;
window.toggleDrawer = toggleDrawer;
window.closeDrawer = closeDrawer;

async function initializeApp() {
    try {
        initializeDOM();
        loadAuthState();
        loadChatCache();
        renderUserState();
        renderTemporaryToggle();
        renderConnectionBanner();
        
        window.toggleDrawer = toggleDrawer;
        window.closeDrawer = closeDrawer;

        await checkConnectivity();
        setupEventListeners();

        const shareToken = new URLSearchParams(window.location.search).get('share');
        if (shareToken) {
            state.sharedView = true;
            await loadSharedChat(shareToken);
            renderUserState();
            renderDrawer();
            renderMessages();
            updateInputState(true);
            return;
        }

        if (state.isConnected && !state.isTemporaryChat) {
            try {
                const userId = ensureUserId();
                await loadChatsFromServer(userId);
            } catch (error) {
                logError('initializeApp - loadChatsFromServer', error);
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
        renderUserState();
        updateInputState(false);

        if (!state.isConnected) {
            showMessage('Offline mode is active. Some features are limited.');
        }
    } catch (error) {
        logError('initializeApp', error);
        showMessage('Error initializing app. Please refresh the page.');
    }
}

async function checkConnectivity() {
    try {
        const isHealthy = await checkHealth();
        state.isConnected = isHealthy;
    } catch {
        state.isConnected = false;
    }
    renderConnectionBanner();

    if (connectivityInterval) {
        clearTimeout(connectivityInterval);
    }
    
    if (state.isConnected && !state.isTemporaryChat) {
        try {
            const userId = ensureUserId();
            await loadChatsFromServer(userId);
            renderUserState();
        } catch (error) {
            logError('checkConnectivity - loadChatsFromServer', error);
        }
    }

    connectivityInterval = setTimeout(checkConnectivity, CONNECTIVITY_CHECK_INTERVAL);
}

async function ensureConnectivity() {
    if (state.isConnected) return true;
    try {
        const isHealthy = await checkHealth();
        state.isConnected = isHealthy;
        renderConnectionBanner();
    } catch {
        state.isConnected = false;
    }
    return state.isConnected;
}

export async function saveSettings() {
    const ui = getUIElements();
    const newUrl = (ui.settingsApiUrl && ui.settingsApiUrl.value) ? ui.settingsApiUrl.value.trim() : '';
    if (!newUrl) {
        showMessage('API URL cannot be empty');
        return;
    }
    try {
        localStorage.setItem('legalease_api_base', newUrl);
    } catch (e) {
        logError('saveSettings', e);
        showMessage('Could not save settings');
        return;
    }
    window.API_BASE_URL = newUrl;
    closeSettingsModal();
    showMessage('Settings saved. Rechecking connectivity...');
    await ensureConnectivity();
}

// Expose a simple reconnect helper for the UI
window.tryReconnect = ensureConnectivity;

function setupEventListeners() {
    const ui = getUIElements();
    
    document.getElementById('menuBtn').addEventListener('click', toggleDrawer);
    document.getElementById('newChatBtn').addEventListener('click', createNewChatUI);
    document.getElementById('closeDrawerBtn').addEventListener('click', closeDrawer);
    document.getElementById('drawerOverlay').addEventListener('click', closeDrawer);
    document.getElementById('sendBtn').addEventListener('click', sendMessageUI);
    document.getElementById('attachBtn').addEventListener('click', () => ui.attachmentInput.click());
    ui.attachmentInput.addEventListener('change', handleAttachmentSelection);
    document.getElementById('removeAttachmentBtn').addEventListener('click', () => {
        state.attachment = null;
        ui.attachmentInput.value = '';
        updateAttachmentPreview(null);
    });
    ui.drawerSearch.addEventListener('input', debounce(handleSearchInput, 300));
    document.getElementById('tempChatToggleBtn').addEventListener('click', toggleTemporaryChatMode);
    document.getElementById('authActionBtn').addEventListener('click', handleAuthAction);
    ui.authForm.addEventListener('submit', handleAuthSubmit);
    document.getElementById('authSwitchBtn').addEventListener('click', () => {
        const newMode = state.authMode === 'login' ? 'signup' : 'login';
        openAuthModal(newMode);
    });
    ui.authCloseBtn.addEventListener('click', closeAuthModal);
    document.getElementById('shareChatBtn').addEventListener('click', openShareModalUI);
    document.getElementById('shareCloseBtn').addEventListener('click', closeShareModal);
    document.getElementById('copyShareLinkBtn').addEventListener('click', copyShareLink);
    document.getElementById('toggleShareBtn').addEventListener('click', toggleChatShareUI);

    // Settings UI handlers
    const settingsBtn = document.getElementById('settingsBtn');
    if (settingsBtn) settingsBtn.addEventListener('click', () => {
        const uiEls = getUIElements();
        if (uiEls.settingsApiUrl) uiEls.settingsApiUrl.value = window.API_BASE_URL || '';
        openSettingsModal();
    });

    const saveSettingsBtn = document.getElementById('saveSettingsBtn');
    if (saveSettingsBtn) saveSettingsBtn.addEventListener('click', saveSettings);

    const settingsCloseBtn = document.getElementById('settingsCloseBtn');
    if (settingsCloseBtn) settingsCloseBtn.addEventListener('click', closeSettingsModal);

    ui.messageInput.addEventListener('input', () => {
        ui.messageInput.style.height = 'auto';
        ui.messageInput.style.height = Math.min(ui.messageInput.scrollHeight, 120) + 'px';
    });

    ui.messageInput.addEventListener('keydown', (event) => {
        if (event.key === 'Enter' && !event.shiftKey) {
            event.preventDefault();
            sendMessageUI();
        }
    });
}

async function createNewChatUI() {
    try {
        if (!state.isConnected || state.isTemporaryChat) {
            createLocalChat();
            renderDrawer();
            renderMessages();
            return;
        }
        
        const userId = ensureUserId();
        await createNewChat(userId);
        renderDrawer();
        renderMessages();
        renderUserState();
        document.getElementById('messageInput').focus();
    } catch (error) {
        logError('createNewChatUI', error);
        showMessage('Could not create chat. Please try again.');
        createLocalChat();
        renderDrawer();
        renderMessages();
    }
}

function selectChatUI(chatId) {
    selectChat(chatId);
    renderMessages();
    renderDrawer();
    closeDrawer();
    document.getElementById('messageInput').focus();
    renderUserState();
}

async function togglePinChatUI(chatId) {
    try {
        await togglePinChat(chatId);
        renderDrawer();
    } catch (error) {
        logError('togglePinChatUI', error);
        showMessage('Could not update chat.');
    }
}

async function renameChatUI(chatId) {
    const currentChat = state.chats[chatId];
    if (!currentChat) return;
    
    const newTitle = prompt('Enter new chat name:', currentChat.title);
    if (newTitle === null) return;
    if (!newTitle.trim()) {
        showMessage('Chat name cannot be empty.');
        return;
    }
    
    try {
        await renameChat(chatId, newTitle);
        renderDrawer();
    } catch (error) {
        logError('renameChatUI', error);
        showMessage('Could not rename chat.');
    }
}

async function deleteChatUI(chatId) {
    if (!confirm('Are you sure you want to delete this chat?')) return;
    
    try {
        await removeChat(chatId);
        renderDrawer();
        renderMessages();
    } catch (error) {
        logError('deleteChatUI', error);
        showMessage('Could not delete chat.');
    }
}

async function sendMessageUI() {
    if (state.sharedView) return;
    const ui = getUIElements();
    const content = ui.messageInput.value.trim();
    const file = state.attachment;
    
    if (!content && !file) return;
    if (!state.currentChatId) {
        await createNewChatUI();
    }
    if (!state.currentChatId) return;
    
    if (!state.isConnected && !state.isTemporaryChat) {
        await ensureConnectivity();
    }

    const chatId = state.currentChatId;
    const userMessage = {
        id: `local_${Date.now()}`,
        sender: 'user',
        content: content,
        createdAt: new Date().toISOString(),
        isNew: true,
    };

    // Add to local state immediately
    if (!state.messages[chatId]) {
        state.messages[chatId] = [];
    }
    state.messages[chatId].push(userMessage);
    
    ui.messageInput.value = '';
    ui.messageInput.style.height = 'auto';
    renderMessages();
    saveChatCache();

    if (state.isConnected && !state.isTemporaryChat) {
        try {
            const response = await apiSendMessage(chatId, content, file);
            // Remove local message and add server responses
            const msgIdx = state.messages[chatId].findIndex(m => m.id === userMessage.id);
            if (msgIdx !== -1) {
                state.messages[chatId][msgIdx] = {
                    ...response.user_message,
                    createdAt: response.user_message.created_at,
                    isNew: false,
                };
            }
            
            const aiMessage = {
                ...response.assistant_message,
                createdAt: response.assistant_message.created_at,
                isNew: true,
            };
            state.messages[chatId].push(aiMessage);
            
            // Update chat timestamp
            if (state.chats[chatId]) {
                state.chats[chatId].updatedAt = new Date().toISOString();
            }
            
            state.attachment = null;
            ui.attachmentInput.value = '';
            updateAttachmentPreview(null);
            saveChatCache();
            renderMessages();
        } catch (error) {
            logError('sendMessageUI', error);
            showMessage(`Error sending message: ${error.message}`);
        }
    } else {
        const offlineReply = {
            id: `local_ai_${Date.now()}`,
            sender: 'ai',
            content: state.isTemporaryChat
                ? 'Temporary chat mode is on. Messages stay in this browser only.'
                : `Backend unavailable. Check that the API is running at ${API_BASE_URL}.`,
            createdAt: new Date().toISOString(),
            isNew: false,
        };
        state.messages[chatId].push(offlineReply);
        state.attachment = null;
        ui.attachmentInput.value = '';
        updateAttachmentPreview(null);
        saveChatCache();
        renderMessages();
    }
}

function editMessageUI(messageId) {
    editingMessageId = messageId;
    const msg = state.messages[state.currentChatId]?.find(m => m.id === messageId);
    if (!msg) return;
    
    const newContent = prompt('Edit message:', msg.content);
    if (newContent === null) return;
    if (!newContent.trim()) {
        showMessage('Message cannot be empty.');
        return;
    }
    
    updateMessageUI(messageId, newContent);
}

async function updateMessageUI(messageId, newContent) {
    if (!state.currentChatId) return;
    const chatId = state.currentChatId;
    const isLocalMessage = String(messageId).startsWith('local_');
    
    try {
        if (state.isConnected && !state.isTemporaryChat && !isLocalMessage && !String(chatId).startsWith('local_')) {
            await apiUpdateMessage(chatId, messageId, newContent);
        }
        
        const msg = state.messages[state.currentChatId]?.find(m => m.id === messageId);
        if (msg) {
            msg.content = newContent;
            msg.edited_at = new Date().toISOString();
        }
        
        editingMessageId = null;
        saveChatCache();
        renderMessages();
    } catch (error) {
        logError('updateMessageUI', error);
        showMessage('Could not update message.');
    }
}

async function deleteMessageUI(messageId) {
    if (!confirm('Delete this message?')) return;
    const chatId = state.currentChatId;
    const isLocalMessage = String(messageId).startsWith('local_');
    
    try {
        if (state.isConnected && !state.isTemporaryChat && !isLocalMessage && !String(chatId).startsWith('local_')) {
            await apiDeleteMessage(chatId, messageId);
        }
        
        if (state.messages[state.currentChatId]) {
            const idx = state.messages[state.currentChatId].findIndex(m => m.id === messageId);
            if (idx !== -1) {
                state.messages[state.currentChatId].splice(idx, 1);
            }
        }
        
        saveChatCache();
        renderMessages();
    } catch (error) {
        logError('deleteMessageUI', error);
        showMessage('Could not delete message.');
    }
}

async function handleAuthAction() {
    if (state.authToken) {
        handleLogout();
        renderUserState();
        renderTemporaryToggle();
        saveChatCache();
    } else {
        openAuthModal('login');
    }
}

function handleAttachmentSelection(event) {
    const file = event.target.files?.[0];
    if (file) {
        const maxSize = 10 * 1024 * 1024; // 10MB
        if (file.size > maxSize) {
            showMessage('File size exceeds 10MB limit.');
            event.target.value = '';
            return;
        }
        state.attachment = file;
        updateAttachmentPreview(file);
    }
}

async function handleSearchInput(event) {
    state.searchQuery = event.target.value.trim();
    
    if (!state.searchQuery) {
        state.searchResults = null;
        renderDrawer();
        return;
    }
    
    if (state.isConnected && state.userId) {
        try {
            const results = await searchChatsServer(state.userId, state.searchQuery);
            state.searchResults = results;
        } catch (error) {
            logError('handleSearchInput - server search', error);
            state.searchResults = await searchChatsLocal(state.searchQuery);
        }
    } else {
        state.searchResults = searchChatsLocal(state.searchQuery);
    }
    
    renderDrawer();
}

function toggleTemporaryChatMode() {
    toggleTemporaryMode();
    renderUserState();
    renderTemporaryToggle();
    saveChatCache();
}

async function handleAuthSubmit(event) {
    event.preventDefault();
    if (state.sharedView) return;
    const ui = getUIElements();
    
    const username = ui.authUsername.value.trim();
    const password = ui.authPassword.value.trim();
    const email = ui.authEmail.value.trim();
    const confirmPassword = ui.authConfirmPassword.value.trim();

    if (!username || !password) {
        showMessage('Please fill in username and password.');
        return;
    }

    try {
        if (state.authMode === 'signup') {
            if (!email) {
                showMessage('Please enter your email address.');
                return;
            }
            if (password !== confirmPassword) {
                showMessage('Passwords do not match.');
                return;
            }
            await handleRegister(username, email, password);
        } else {
            await handleLogin(username, password);
        }
        
        closeAuthModal();
        renderUserState();
        const userId = ensureUserId();
        await loadChatsFromServer(userId);
        renderDrawer();
        renderMessages();
    } catch (error) {
        logError('handleAuthSubmit', error);
        showMessage(error.message || 'Authentication failed.');
    }
}

// Initialize app when DOM is ready
window.addEventListener('DOMContentLoaded', initializeApp);

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
    if (connectivityInterval) clearTimeout(connectivityInterval);
});

async function openShareModalUI() {
    const chatId = state.currentChatId || Object.keys(state.chats)[0];
    if (!chatId) {
        showMessage('Select a chat before sharing.');
        return;
    }
    
    const chat = state.chats[chatId];
    if (!chat) {
        showMessage('Select a chat before sharing.');
        return;
    }

    if (!state.authToken) {
        showMessage('Login to share chats.');
        openAuthModal('login');
        return;
    }
    
    openShareModal(chat.isShared || false, chat.shareLink || null);
}

async function toggleChatShareUI() {
    if (!state.currentChatId) return;
    
    const chatId = state.currentChatId;
    const chat = state.chats[chatId];
    const isCurrentlyShared = chat?.isShared || false;
    
    try {
        const response = await apiShareChat(chatId, !isCurrentlyShared);
        const browserShareLink = response.share_token
            ? `${window.location.origin}${window.location.pathname}?share=${encodeURIComponent(response.share_token)}`
            : response.share_link;

        if (state.chats[chatId]) {
            state.chats[chatId].isShared = response.is_shared;
            state.chats[chatId].shareLink = browserShareLink;
        }
        
        saveChatCache();
        openShareModal(response.is_shared, browserShareLink);
        showMessage(response.is_shared ? 'Chat shared successfully' : 'Chat sharing disabled');
    } catch (error) {
        logError('toggleChatShareUI', error);
        showMessage('Could not update share settings.');
    }
}

async function loadSharedChat(shareToken) {
    try {
        const response = await getSharedChat(shareToken);
        const sharedId = `shared_${shareToken}`;
        state.chats = {
            [sharedId]: {
                id: sharedId,
                title: response.title || 'Shared Chat',
                updatedAt: new Date().toISOString(),
                isPinned: false,
                isShared: true,
            }
        };
        state.messages = {
            [sharedId]: (response.messages || []).map(msg => ({
                id: msg.id || `shared_msg_${Math.random().toString(36).substr(2, 9)}`,
                sender: msg.sender,
                content: msg.content,
                createdAt: msg.created_at || new Date().toISOString(),
                edited_at: msg.edited_at,
                isNew: false,
            }))
        };
        state.currentChatId = sharedId;
        state.searchQuery = '';
        state.searchResults = null;
        document.title = `Shared Chat · LegalEase`;
    } catch (error) {
        logError('loadSharedChat', error);
        showMessage('Unable to load shared chat.');
        state.sharedView = false;
    }
}

function updateInputState(disabled) {
    const ui = getUIElements();
    if (!ui) return;
    ui.messageInput.disabled = disabled;
    ui.attachBtn.disabled = disabled;
    ui.sendBtn.disabled = disabled;
    if (disabled) {
        ui.messageInput.placeholder = 'Shared chats are read-only.';
    } else {
        ui.messageInput.placeholder = 'Ask LegalEase...';
    }
}

function copyShareLink() {
    const shareLinkInput = document.getElementById('shareLink');
    if (!shareLinkInput || !shareLinkInput.value) return;

    navigator.clipboard.writeText(shareLinkInput.value).then(() => {
        showMessage('Link copied to clipboard!');
    }).catch(() => {
        try {
            shareLinkInput.select();
            document.execCommand('copy');
            showMessage('Link copied to clipboard!');
        } catch (err) {
            logError('copyShareLink', err);
            showMessage('Failed to copy link. Please copy it manually.');
        }
    });
}

export { initializeApp, checkConnectivity };
