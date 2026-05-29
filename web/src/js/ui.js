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
let settingsBtn, settingsModal, settingsApiPrefix, settingsApiSuffix, settingsApiIp, settingsCloseBtn;
let personaBtn, contextPill, attachmentMenu;

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
    settingsBtn = document.getElementById('settingsBtn');
    settingsModal = document.getElementById('settingsModal');
    settingsApiPrefix = document.getElementById('settingsApiPrefix');
    settingsApiSuffix = document.getElementById('settingsApiSuffix');
    settingsApiIp = document.getElementById('settingsApiIp');
    settingsCloseBtn = document.getElementById('settingsCloseBtn');
    personaBtn = document.getElementById('attachPersonaBtn');
    contextPill = document.getElementById('contextActivePill');
    attachmentMenu = document.getElementById('attachmentMenu');
}

export function toggleDrawer() {
    const isOpen = drawer.classList.toggle('active');
    drawerOverlay.classList.toggle('active');
    document.body.classList.toggle('drawer-collapsed', isOpen);
    if (menuBtn) menuBtn.setAttribute('aria-expanded', String(isOpen));
}

export function closeDrawer() {
    drawer.classList.remove('active');
    drawerOverlay.classList.remove('active');
    document.body.classList.remove('drawer-collapsed');
    if (menuBtn) menuBtn.setAttribute('aria-expanded', 'false');
}

export function renderUserState() {
    const displayName = state.authToken
        ? state.username
        : (state.isTemporaryChat ? `${DEFAULT_USERNAME} (Temporary)` : DEFAULT_USERNAME);
    if (userStatus) userStatus.textContent = displayName;
    if (authActionBtn) authActionBtn.textContent = state.authToken ? 'Logout' : 'Login / Sign Up';
    
    // Dynamically update the sidebar header username
    const sidebarUserStatus = document.getElementById('sidebarUserStatus');
    if (sidebarUserStatus) sidebarUserStatus.textContent = state.authToken ? state.username : 'Guest';

    // Dynamically update the Gemini-style welcome screen greeting
    const welcomeGreeting = document.getElementById('welcomeGreeting');
    if (welcomeGreeting) {
        welcomeGreeting.innerHTML = state.authToken 
            ? `Hello, <span class="gradient-username">${escapeHtml(state.username)}</span>`
            : `Hello, <span class="gradient-username">Guest</span>`;
    }
}

export function renderTemporaryToggle() {
    if (tempChatToggleBtn) {
        tempChatToggleBtn.textContent = state.isTemporaryChat ? 'Temporary Chat: ON' : 'Temporary Chat: OFF';
        tempChatToggleBtn.classList.toggle('temp-active', state.isTemporaryChat);
    }
}

export function renderConnectionBanner() {
    if (!connectionBanner) return;
    if (state.isConnected) {
        connectionBanner.classList.add('hidden');
    } else {
        connectionBanner.innerHTML = `
            <span>Offline — API not reachable at <code>${window.API_BASE_URL || 'backend'}</code></span>
            <button id="retryConnBtn" class="banner-action-btn">Retry</button>
            <button id="openSettingsFromBanner" class="banner-action-btn">Settings</button>
        `;
        connectionBanner.classList.remove('hidden');
        document.getElementById('retryConnBtn')?.addEventListener('click', () => {
            if (typeof window.tryReconnect === 'function') window.tryReconnect();
            else window.location.reload();
        });
        document.getElementById('openSettingsFromBanner')?.addEventListener('click', () => {
            openSettingsModal();
        });
    }
}

export function openAuthModal(mode) {
    state.authMode = mode;
    authModal.classList.remove('hidden');
    document.documentElement.classList.remove('is-authenticated');
    document.documentElement.classList.add('is-unauthenticated');
    if (mode === 'login') {
        authTitle.innerHTML = 'Welcome to<br>LegalEase';
        authSubmitBtn.textContent = 'Sign In';
        authSwitchText.textContent = "Don't have an account? ";
        authSwitchBtn.textContent = 'Create one';
        authEmailLabel?.classList.add('hidden');
        authConfirmLabel?.classList.add('hidden');
    } else {
        authTitle.innerHTML = 'Sign up for<br>LegalEase';
        authSubmitBtn.textContent = 'Sign Up';
        authSwitchText.textContent = 'Already have an account? ';
        authSwitchBtn.textContent = 'Sign in';
        authEmailLabel?.classList.remove('hidden');
        authConfirmLabel?.classList.remove('hidden');
    }
}

export function closeAuthModal() {
    authModal.classList.add('hidden');
    authForm.reset();
    document.documentElement.classList.remove('is-unauthenticated');
    document.documentElement.classList.add('is-authenticated');
}

export function openSettingsModal() {
    console.log("openSettingsModal called, settingsModal:", settingsModal);
    settingsModal?.classList.remove('hidden');
}

export function closeSettingsModal() {
    console.log("closeSettingsModal called, settingsModal:", settingsModal);
    settingsModal?.classList.add('hidden');
}

export function showPrivacySections(show) {
    document.querySelectorAll('.auth-required-settings').forEach(el => {
        el.classList.toggle('hidden', !show);
    });
}

export function updatePersonaBtn(active) {
    const btn = document.getElementById('attachPersonaBtn');
    if (!btn) return;
    btn.classList.toggle('persona-active', active);
    btn.title = active ? 'Persona mode active — click to disable' : 'Toggle persona/context mode';
    btn.setAttribute('aria-pressed', String(active));
}

export function renderContextPill(show) {
    const pill = document.getElementById('contextActivePill');
    if (!pill) return;
    pill.classList.toggle('visible', show);
}

// ─── Drawer ────────────────────────────────────────────────────────────────────
export function renderDrawer() {
    if (!drawerContent) return;

    const searchMode = state.searchQuery.trim().length > 0;

    if (searchMode) {
        const displayChats = state.searchResults || [];
        drawerContent.innerHTML = displayChats.length > 0
            ? displayChats.map(chat => chatItemHtml(chat)).join('')
            : '<div class="loading-text">No matching chats found</div>';
        renderUserState();
        return;
    }

    const allChats = Object.values(state.chats)
        .sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt));
    const pinnedChats = allChats.filter(c => c.isPinned);
    const recentChats = allChats.filter(c => !c.isPinned);

    const html = [];
    if (pinnedChats.length > 0) {
        html.push(pinnedChats.map(c => chatItemHtml(c)).join(''));
    }
    if (recentChats.length > 0) {
        html.push(recentChats.map(c => chatItemHtml(c)).join(''));
    }

    drawerContent.innerHTML = html.length > 0
        ? html.join('')
        : '<div class="loading-text">No chats yet</div>';
    renderUserState();
}

function chatItemHtml(chat) {
    const isActive = chat.id === state.currentChatId;
    const pinIndicator = chat.isPinned 
        ? `<span class="chat-pinned-indicator" title="Pinned chat">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor"><path d="M16 12V4h1V2H7v2h1v8l-2 2v2h5.2v6h1.6v-6H18v-2l-2-2z"/></svg>
           </span>`
        : '';
    return `
        <div class="chat-item ${isActive ? 'active' : ''}"
             data-chat-id="${chat.id}"
             onclick="window.selectChatUI('${chat.id}')"
             oncontextmenu="event.preventDefault(); event.stopPropagation(); window.showChatMenuUI(event, '${chat.id}')"
             role="button" tabindex="0"
             aria-label="Chat: ${escapeHtml(chat.title)}">
            <div class="chat-title">${escapeHtml(chat.title)}</div>
            <div class="chat-item-right-row">
                ${pinIndicator}
                <button class="chat-menu-trigger"
                        onclick="event.stopPropagation(); window.showChatMenuUI(event, '${chat.id}')"
                        title="Chat actions" aria-label="Chat actions">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="5" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="12" cy="19" r="1.5"/></svg>
                </button>
            </div>
        </div>
    `;
}

// ─── Messages ──────────────────────────────────────────────────────────────────
export function renderMessages() {
    if (!messagesContainer) return;

    const chatContainer = document.querySelector('.chat-container');
    const msgList = state.currentChatId
        ? (state.messages[state.currentChatId] || [])
        : [];

    const isEmpty = msgList.length === 0;
    chatContainer?.classList.toggle('no-messages', isEmpty);

    if (isEmpty) {
        messagesContainer.innerHTML = '';
        return;
    }

    // Find the latest AI message ID to keep its actions always visible
    let lastAiMsgId = null;
    for (let i = msgList.length - 1; i >= 0; i--) {
        if (msgList[i].sender === 'ai') {
            lastAiMsgId = msgList[i].id;
            break;
        }
    }

    messagesContainer.innerHTML = msgList.map(msg => messageBubbleHtml(msg, lastAiMsgId)).join('');
    scrollToBottom();

}

function messageBubbleHtml(msg, lastAiMsgId) {
    const isUser = msg.sender === 'user';
    const isEdited = !!msg.edited_at;
    const canEdit = isUser && !state.sharedView;

    if (isUser) {
        return userBubbleHtml(msg, isEdited, canEdit);
    } else {
        const isLatest = msg.id === lastAiMsgId;
        return aiBubbleHtml(msg, isLatest);
    }
}

function userBubbleHtml(msg, isEdited, canEdit) {
    const hasAttachment = msg.fileName && (msg.fileId || msg.localFileUrl);
    const cleanContent = msg.content.trim();

    let attachmentCard = '';
    if (hasAttachment) {
        const isPersona = msg.fileName === "Persona Attached" || msg.fileName === "Persona Attached.txt";
        const displayName = isPersona ? "Persona Attached" : msg.fileName;
        
        let icon;
        if (isPersona) {
            icon = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>`;
        } else {
            const isImage = /\.(png|jpe?g|gif|webp|bmp)$/i.test(msg.fileName);
            icon = isImage
                ? `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>`
                : `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>`;
        }

        const clickAction = (!isPersona && msg.fileId)
            ? `window.downloadFileUI('${msg.fileId}', '${escapeHtml(msg.fileName)}')`
            : '';
        attachmentCard = `
            <div class="user-attachment-card ${isPersona ? 'persona-card' : ''}" ${clickAction ? `onclick="${clickAction}" role="button" tabindex="0" title="${isPersona ? 'Persona Attached' : `Download ${escapeHtml(displayName)}`}"` : ''}>
                <div class="attachment-icon-box">${icon}</div>
                <span class="attachment-file-name">${escapeHtml(displayName)}</span>
            </div>
        `;
    }

    return `
        <div class="message-bubble user" data-message-id="${msg.id}" role="article">
            <div class="user-bubble-glass">
                ${cleanContent ? `<div class="user-bubble-text">${escapeHtml(cleanContent)}</div>` : ''}
                ${attachmentCard}
                ${isEdited ? '<div class="edited-indicator">(edited)</div>' : ''}
            </div>
        </div>
    `;
}

function aiBubbleHtml(msg, isLatest = false) {
    // Render markdown using marked.js if available, else plain text
    let renderedContent;
    if (typeof window.marked !== 'undefined') {
        renderedContent = window.marked.parse(msg.content);
    } else {
        renderedContent = `<p>${escapeHtml(msg.content).replace(/\n/g, '<br>')}</p>`;
    }

    return `
        <div class="message-bubble ai${isLatest ? ' is-latest' : ''}" data-message-id="${msg.id}" role="article">
            <div class="ai-bubble-content">
                <div class="ai-message-text">${renderedContent}</div>
                <div class="ai-action-bar">
                    <button class="ai-action-btn thumb-btn" data-thumb-up="${msg.id}"
                            onclick="window.thumbsUpUI('${msg.id}')"
                            title="Helpful" aria-label="Mark as helpful" aria-pressed="false">
                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.28a2 2 0 0 0 2-1.7l1.38-9a2 2 0 0 0-2-2.3H14z"/><path d="M7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3"/></svg>
                    </button>
                    <button class="ai-action-btn thumb-btn" data-thumb-down="${msg.id}"
                            onclick="window.thumbsDownUI('${msg.id}')"
                            title="Not helpful" aria-label="Mark as not helpful" aria-pressed="false">
                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M10 15v4a3 3 0 0 0 3 3l4-9V2H5.72a2 2 0 0 0-2 1.7l-1.38 9a2 2 0 0 0 2 2.3H10z"/><path d="M17 2h2.67A2.31 2.31 0 0 1 22 4v7a2.31 2.31 0 0 1-2.33 2H17"/></svg>
                    </button>
                    <button class="ai-action-btn copy-btn"
                            onclick="window.copyMessageUI('${msg.id}')"
                            title="Copy response" aria-label="Copy to clipboard">
                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
                    </button>
                </div>
            </div>
        </div>
    `;
}

// ─── Thinking Indicator ────────────────────────────────────────────────────────
export function renderThinkingIndicator() {
    if (!messagesContainer) return;
    const existing = document.getElementById('thinkingIndicator');
    if (existing) return;
    const el = document.createElement('div');
    el.id = 'thinkingIndicator';
    el.className = 'thinking-indicator';
    el.setAttribute('role', 'status');
    el.setAttribute('aria-label', 'LegalEase is thinking');
    el.innerHTML = `
        <div class="thinking-dots">
            <span></span><span></span><span></span>
        </div>
    `;
    messagesContainer.appendChild(el);
    scrollToBottom();
}

export function removeThinkingIndicator() {
    document.getElementById('thinkingIndicator')?.remove();
}

function scrollToBottom() {
    const performScroll = () => {
        if (!messagesContainer) return;
        
        // Scroll the container scrollTop
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
        
        // Also scroll the last element into view as a backup for mobile devices
        if (messagesContainer.lastElementChild) {
            messagesContainer.lastElementChild.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
        }
    };

    requestAnimationFrame(performScroll);
    // Double timeout backups to handle mobile keyboard state, browser rendering lag, and dynamic layout reflows
    setTimeout(performScroll, 80);
    setTimeout(performScroll, 220);
}

export function getUIElements() {
    return {
        messageInput, sendBtn, attachBtn, attachmentInput, attachmentPreview,
        attachmentName, removeAttachmentBtn, drawerSearch, authForm, authUsername,
        authEmail, authPassword, authConfirmPassword, authSwitchBtn, authCloseBtn,
        settingsBtn, settingsModal, settingsApiPrefix, settingsApiSuffix, settingsApiIp, settingsCloseBtn,
    };
}

export function updateAttachmentPreview(file) {
    if (attachmentPreview) {
        attachmentPreview.classList.add('hidden');
    }
    const attachBtn = document.getElementById('attachBtn');
    if (!attachBtn) return;
    
    attachBtn.classList.remove('has-attachment', 'has-persona');
    
    if (file) {
        attachBtn.classList.add('has-attachment');
        attachBtn.title = "Clear attachment";
        attachBtn.innerHTML = `
            <div class="attach-icon-slot">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <path d="M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48"/>
                </svg>
            </div>
        `;
    } else if (state.useContext) {
        attachBtn.classList.add('has-persona');
        attachBtn.title = "Clear persona";
        attachBtn.innerHTML = `
            <div class="attach-icon-slot">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                    <circle cx="12" cy="7" r="4"/>
                </svg>
            </div>
        `;
    } else {
        attachBtn.title = "Attach";
        attachBtn.innerHTML = `
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="12" y1="5" x2="12" y2="19"/>
                <line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
        `;
    }
}

// Legacy exports kept for compatibility
export function openShareModal() {}
export function closeShareModal() {}
