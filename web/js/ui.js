// UI rendering module
import { state, DEFAULT_USERNAME } from './config.js';
import { escapeHtml } from './utils.js';

// DOM element references
let menuBtn, newChatBtn, drawer, drawerOverlay, closeDrawerBtn;
let messageInput, sendBtn, attachBtn, messagesContainer, drawerContent;
let drawerSearch, connectionBanner, attachmentInput, attachmentPreview;
let attachmentName, removeAttachmentBtn, tempChatToggleBtn, authActionBtn;
let userStatus, authModal, authForm, authTitle, authSwitchBtn, authSwitchText;
let authCloseBtn, authUsername, authEmailLabel, authEmail, authPassword;
let authConfirmLabel, authConfirmPassword, authSubmitBtn;
let shareChatBtn, shareModal, shareCloseBtn, shareMessage, shareLinkContainer;
let shareLink, copyShareLinkBtn, toggleShareBtn;
let settingsBtn, settingsModal, settingsApiUrl, saveSettingsBtn, settingsCloseBtn;

export function initializeDOM() {
    menuBtn = document.getElementById('menuBtn');
    newChatBtn = document.getElementById('newChatBtn');
    drawer = document.getElementById('drawer');
    drawerOverlay = document.getElementById('drawerOverlay');
    closeDrawerBtn = document.getElementById('closeDrawerBtn');
    messageInput = document.getElementById('messageInput');
    sendBtn = document.getElementById('sendBtn');
    attachBtn = document.getElementById('attachBtn');
    messagesContainer = document.getElementById('messagesContainer');
    drawerContent = document.getElementById('drawerContent');
    drawerSearch = document.getElementById('drawerSearch');
    connectionBanner = document.getElementById('connectionBanner');
    attachmentInput = document.getElementById('attachmentInput');
    attachmentPreview = document.getElementById('attachmentPreview');
    attachmentName = document.getElementById('attachmentName');
    removeAttachmentBtn = document.getElementById('removeAttachmentBtn');
    tempChatToggleBtn = document.getElementById('tempChatToggleBtn');
    authActionBtn = document.getElementById('authActionBtn');
    userStatus = document.getElementById('userStatus');
    authModal = document.getElementById('authModal');
    authForm = document.getElementById('authForm');
    authTitle = document.getElementById('authTitle');
    authSwitchBtn = document.getElementById('authSwitchBtn');
    authSwitchText = document.getElementById('authSwitchText');
    authCloseBtn = document.getElementById('authCloseBtn');
    authUsername = document.getElementById('authUsername');
    authEmailLabel = document.getElementById('authEmailLabel');
    authEmail = document.getElementById('authEmail');
    authPassword = document.getElementById('authPassword');
    authConfirmLabel = document.getElementById('authConfirmLabel');
    authConfirmPassword = document.getElementById('authConfirmPassword');
    authSubmitBtn = document.getElementById('authSubmitBtn');
    shareChatBtn = document.getElementById('shareChatBtn');
    shareModal = document.getElementById('shareModal');
    shareCloseBtn = document.getElementById('shareCloseBtn');
    shareMessage = document.getElementById('shareMessage');
    shareLinkContainer = document.getElementById('shareLinkContainer');
    shareLink = document.getElementById('shareLink');
    copyShareLinkBtn = document.getElementById('copyShareLinkBtn');
    toggleShareBtn = document.getElementById('toggleShareBtn');
    settingsBtn = document.getElementById('settingsBtn');
    settingsModal = document.getElementById('settingsModal');
    settingsApiUrl = document.getElementById('settingsApiUrl');
    saveSettingsBtn = document.getElementById('saveSettingsBtn');
    settingsCloseBtn = document.getElementById('settingsCloseBtn');
}

export function toggleDrawer() {
    const isOpen = drawer.classList.toggle('active');
    drawerOverlay.classList.toggle('active');
    document.body.classList.toggle('drawer-collapsed', isOpen);
    if (menuBtn) {
        menuBtn.setAttribute('aria-expanded', String(isOpen));
    }
}

export function closeDrawer() {
    drawer.classList.remove('active');
    drawerOverlay.classList.remove('active');
    document.body.classList.remove('drawer-collapsed');
    if (menuBtn) {
        menuBtn.setAttribute('aria-expanded', 'false');
    }
}

export function renderUserState() {
    const displayName = state.authToken
        ? state.username
        : (state.isTemporaryChat ? `${DEFAULT_USERNAME} (Temporary)` : DEFAULT_USERNAME);
    userStatus.textContent = displayName;
    authActionBtn.textContent = state.authToken ? 'Logout' : 'Login / Sign Up';

    if (shareChatBtn) {
        if (state.isConnected && !state.isTemporaryChat && state.currentChatId) {
            shareChatBtn.removeAttribute('hidden');
        } else {
            shareChatBtn.setAttribute('hidden', '');
        }
    }
}

export function renderTemporaryToggle() {
    tempChatToggleBtn.textContent = state.isTemporaryChat ? 'Temporary Chat: ON' : 'Temporary Chat: OFF';
}

export function renderConnectionBanner() {
    if (state.isConnected) {
        connectionBanner.classList.add('hidden');
    } else {
        const apiUrl = (window.API_BASE_URL) ? window.API_BASE_URL : 'backend';
        connectionBanner.innerHTML = `Offline mode active. Some features may not be available. <span class="hidden-sm">(API: ${apiUrl})</span> <button id="retryConnBtn" class="retry-conn-btn">Retry</button> <button id="openSettingsFromBanner" class="retry-conn-btn">Settings</button>`;
        connectionBanner.classList.remove('hidden');
        // Attach retry handler
        const retryBtn = document.getElementById('retryConnBtn');
        if (retryBtn) {
            retryBtn.addEventListener('click', () => {
                if (typeof window.tryReconnect === 'function') {
                    window.tryReconnect();
                } else {
                    window.location.reload();
                }
            });
        }
        const openSettingsBtn = document.getElementById('openSettingsFromBanner');
        if (openSettingsBtn) {
            openSettingsBtn.addEventListener('click', () => {
                if (settingsApiUrl) settingsApiUrl.value = window.API_BASE_URL || '';
                openSettingsModal();
            });
        }
    }
}

export function openAuthModal(mode) {
    state.authMode = mode;
    authModal.classList.remove('hidden');
    if (mode === 'login') {
        authTitle.innerHTML = 'Welcome to<br>LegalEase';
        authSubmitBtn.textContent = 'Sign In';
        authSwitchText.textContent = "Don't have an account? ";
        authSwitchBtn.textContent = 'Create one';
        authEmailLabel.classList.add('hidden');
        authConfirmLabel.classList.add('hidden');
    } else {
        authTitle.innerHTML = 'Sign up for<br>LegalEase';
        authSubmitBtn.textContent = 'Sign Up';
        authSwitchText.textContent = 'Already have an account? ';
        authSwitchBtn.textContent = 'Sign in';
        authEmailLabel.classList.remove('hidden');
        authConfirmLabel.classList.remove('hidden');
    }
}

export function closeAuthModal() {
    authModal.classList.add('hidden');
    authForm.reset();
}

export function openShareModal(isShared = false, shareLinkValue = null) {
    shareModal.classList.remove('hidden');
    if (isShared && shareLinkValue) {
        shareMessage.textContent = 'This chat is shared. Share the link below:';
        shareLink.value = shareLinkValue;
        shareLinkContainer.classList.remove('hidden');
        toggleShareBtn.textContent = 'Disable Sharing';
    } else {
        shareMessage.textContent = 'Enable sharing to generate a link';
        shareLinkContainer.classList.add('hidden');
        toggleShareBtn.textContent = 'Enable Sharing';
    }
}

export function openSettingsModal() {
    if (!settingsModal) return;
    settingsModal.classList.remove('hidden');
}

export function closeSettingsModal() {
    if (!settingsModal) return;
    settingsModal.classList.add('hidden');
}

export function closeShareModal() {
    shareModal.classList.add('hidden');
}

export function renderDrawer(chats = null) {
    const searchMode = state.searchQuery.trim().length > 0;
    const displayChats = searchMode ? (state.searchResults || []) : (chats || []);

    if (!searchMode) {
        const allChats = Object.values(state.chats).sort((a, b) => 
            new Date(b.updatedAt) - new Date(a.updatedAt));
        const pinnedChats = allChats.filter(c => c.isPinned);
        const recentChats = allChats.filter(c => !c.isPinned);
        
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
        drawerContent.innerHTML = html.length > 0 ? html.join('') : 
            '<div class="loading-text">No chats yet</div>';
        renderUserState();
        return;
    }

    drawerContent.innerHTML = displayChats.length > 0 ? 
        displayChats.map(chat => chatItemHtml(chat)).join('') : 
        '<div class="loading-text">No matching chats found</div>';
    renderUserState();
}

function chatItemHtml(chat) {
    return `
        <div class="chat-item ${chat.id === state.currentChatId ? 'active' : ''}" 
             data-chat-id="${chat.id}" 
             onclick="window.selectChatUI('${chat.id}')" 
             role="button" 
             tabindex="0" 
             aria-label="Chat: ${escapeHtml(chat.title)}">
            <div class="chat-title">${escapeHtml(chat.title)}</div>
            <div class="chat-actions">
                <button class="chat-action-btn" 
                        onclick="event.stopPropagation(); window.togglePinChatUI('${chat.id}')" 
                        title="Pin / unpin chat"
                        aria-label="Toggle pin for ${escapeHtml(chat.title)}">
                    ${chat.isPinned ? '★' : '☆'}
                </button>
                <button class="chat-action-btn" 
                        onclick="event.stopPropagation(); window.renameChatUI('${chat.id}')" 
                        title="Rename chat"
                        aria-label="Rename ${escapeHtml(chat.title)}">
                    ✎
                </button>
                <button class="chat-action-btn delete" 
                        onclick="event.stopPropagation(); window.deleteChatUI('${chat.id}')" 
                        title="Delete chat"
                        aria-label="Delete ${escapeHtml(chat.title)}">
                    🗑
                </button>
            </div>
        </div>
    `;
}

export function renderMessages(messages = null) {
    const msgList = messages ?? (state.currentChatId ? (state.messages[state.currentChatId] || []) : []);
    
    if (msgList.length === 0) {
        messagesContainer.innerHTML = `
            <div class="welcome-message">
                <h1>LegalEase</h1>
                <p>Your AI-powered legal assistant</p>
                <p class="welcome-subtitle">Start typing to begin a conversation</p>
            </div>
        `;
        return;
    }

    messagesContainer.innerHTML = msgList.map(msg => {
        const isUser = msg.sender === 'user';
        const isEdited = msg.edited_at !== undefined;
        const canEdit = isUser && !state.sharedView;
        return `
            <div class="message-bubble ${msg.sender}" data-message-id="${msg.id}" role="article">
                <div class="bubble-content ${msg.sender}">
                    <div class="message-text" data-message-id="${msg.id}">${escapeHtml(msg.content)}</div>
                    ${isEdited ? '<div class="edited-indicator" title="This message was edited">(edited)</div>' : ''}
                </div>
                ${canEdit ? `
                    <div class="message-actions">
                        <button class="message-action-btn" 
                                onclick="event.stopPropagation(); window.editMessageUI('${msg.id}')" 
                                title="Edit"
                                aria-label="Edit message">
                            ✎
                        </button>
                        <button class="message-action-btn delete" 
                                onclick="event.stopPropagation(); window.deleteMessageUI('${msg.id}')" 
                                title="Delete"
                                aria-label="Delete message">
                            🗑
                        </button>
                    </div>
                ` : ''}
            </div>
        `;
    }).join('');

    setTimeout(() => {
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }, 100);
}

export function getUIElements() {
    return {
        messageInput, sendBtn, attachBtn, attachmentInput, attachmentPreview,
        attachmentName, removeAttachmentBtn, drawerSearch, authForm, authUsername,
        authEmail, authPassword, authConfirmPassword, authSwitchBtn, authCloseBtn,
        settingsBtn, settingsModal, settingsApiUrl, saveSettingsBtn, settingsCloseBtn
    };
}

export function updateAttachmentPreview(file) {
    if (file) {
        attachmentName.textContent = `📎 ${file.name}`;
        attachmentPreview.classList.remove('hidden');
    } else {
        attachmentPreview.classList.add('hidden');
    }
}
