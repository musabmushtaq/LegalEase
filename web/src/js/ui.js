// UI rendering module
import { state, DEFAULT_USERNAME, DEFAULT_USER_ID } from './config.js';
import { escapeHtml } from './utils.js';
import { getUserProfile } from './api.js';

// DOM element references
let menuBtn, newChatBtn, drawer, drawerOverlay, closeDrawerBtn;
let messageInput, sendBtn, attachBtn, messagesContainer, drawerContent;
let drawerSearch, connectionBanner, attachmentInput, attachmentPreview;
let attachmentName, removeAttachmentBtn, tempChatToggleBtn, authActionBtn;
let userStatus, authModal, authForm, authTitle, authSwitchBtn, authSwitchText;
let authCloseBtn, authUsername, authEmailLabel, authEmail, authPassword;
let authConfirmLabel, authConfirmPassword, authSubmitBtn;
let settingsBtn, settingsModal, settingsApiPrefix, settingsApiSuffix, settingsApiIp, settingsCloseBtn;
let personaBtn, contextPill, attachmentMenu, newMessagesPill;
let shareBtn, manageAccessModal, manageAccessCloseBtn, chatPrivacyStateText, revokeAccessBtn;
let inviteSection, inviteForm, inviteUsername, inviteSubmitBtn, collaboratorsListCard;

// Scroll and unread message states
let isAtBottom = true;
let hasNewUnreadMessages = false;
let lastChatId = null;
let lastMessageCount = 0;

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
    shareBtn = document.getElementById('shareBtn');
    manageAccessModal = document.getElementById('manageAccessModal');
    manageAccessCloseBtn = document.getElementById('manageAccessCloseBtn');
    chatPrivacyStateText = document.getElementById('chatPrivacyStateText');
    revokeAccessBtn = document.getElementById('revokeAccessBtn');
    inviteSection = document.getElementById('inviteSection');
    inviteForm = document.getElementById('inviteForm');
    inviteUsername = document.getElementById('inviteUsername');
    inviteSubmitBtn = document.getElementById('inviteSubmitBtn');
    collaboratorsListCard = document.getElementById('collaboratorsListCard');
    newMessagesPill = document.getElementById('newMessagesPill');

    if (newMessagesPill) {
        newMessagesPill.addEventListener('click', () => {
            acceleratedScrollToBottom();
        });
    }

    if (messagesContainer) {
        messagesContainer.addEventListener('scroll', () => {
            const threshold = 40; // px
            const atBottom = (messagesContainer.scrollHeight - messagesContainer.scrollTop - messagesContainer.clientHeight) <= threshold;
            if (atBottom !== isAtBottom) {
                isAtBottom = atBottom;
                if (isAtBottom) {
                    hasNewUnreadMessages = false;
                }
                updatePillTextAndVisibility();
            }
        });
    }
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
    const sharedIndicator = chat.isShared 
        ? `<span class="sidebar-shared-icon" title="Shared chat">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
           </span>`
        : '';

    // Only allow context menu / actions if user is the owner (admin) of the chat
    const isOwner = !state.authToken || !chat.userId || chat.userId === state.userId;
    const contextMenuAttr = isOwner 
        ? `oncontextmenu="event.preventDefault(); event.stopPropagation(); window.showChatMenuUI(event, '${chat.id}')"`
        : `oncontextmenu="event.preventDefault();"`;

    const menuTrigger = isOwner
        ? `<button class="chat-menu-trigger"
                   onclick="event.stopPropagation(); window.showChatMenuUI(event, '${chat.id}')"
                   title="Chat actions" aria-label="Chat actions">
               <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="5" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="12" cy="19" r="1.5"/></svg>
           </button>`
        : '';

    return `
        <div class="chat-item ${isActive ? 'active' : ''}"
             data-chat-id="${chat.id}"
             onclick="window.selectChatUI('${chat.id}')"
             ${contextMenuAttr}
             role="button" tabindex="0"
             aria-label="Chat: ${escapeHtml(chat.title)}">
            <div class="chat-title">${escapeHtml(chat.title)}</div>
            <div class="chat-item-right-row">
                ${pinIndicator}
                ${sharedIndicator}
                ${menuTrigger}
            </div>
        </div>
    `;
}

const usernamesCache = {};

function getUsername(userId) {
    if (!userId) return '...';
    if (userId === state.userId && state.username) {
        return state.username;
    }
    if (userId === DEFAULT_USER_ID || userId === 'default_user') {
        return DEFAULT_USERNAME;
    }
    if (usernamesCache[userId]) {
        return usernamesCache[userId];
    }
    usernamesCache[userId] = 'loading';
    getUserProfile(userId).then(profile => {
        usernamesCache[userId] = profile.username || 'Unknown';
        renderMessages();
    }).catch(() => {
        usernamesCache[userId] = 'Unknown';
        renderMessages();
    });
    return '...';
}

function updatePillTextAndVisibility() {
    if (!newMessagesPill) return;
    const textSpan = document.getElementById('newMessagesPillText');
    if (isAtBottom) {
        newMessagesPill.classList.add('hidden');
        hasNewUnreadMessages = false;
    } else {
        if (textSpan) {
            textSpan.textContent = hasNewUnreadMessages ? 'New messages' : 'Scroll to bottom';
        }
        newMessagesPill.classList.remove('hidden');
    }
}

function showNewMessagesPill() {
    isAtBottom = false;
    updatePillTextAndVisibility();
}

function hideNewMessagesPill() {
    isAtBottom = true;
    hasNewUnreadMessages = false;
    updatePillTextAndVisibility();
}

function acceleratedScrollToBottom() {
    if (!messagesContainer) return;
    
    isAtBottom = true;
    hasNewUnreadMessages = false;
    updatePillTextAndVisibility();

    const maxScroll = messagesContainer.scrollHeight - messagesContainer.clientHeight;
    const currentScroll = messagesContainer.scrollTop;
    const distance = maxScroll - currentScroll;
    
    const maxAnimateDistance = 1500;
    if (distance > maxAnimateDistance) {
        messagesContainer.scrollTop = maxScroll - maxAnimateDistance;
    }
    
    messagesContainer.scrollTo({
        top: maxScroll,
        behavior: 'smooth'
    });
}

// ─── Messages ──────────────────────────────────────────────────────────────────
export function renderMessages(forceScroll = false) {
    if (!messagesContainer) return;

    // Check if we were at the bottom before updating HTML
    const threshold = 40; // px
    const wasAtBottom = (messagesContainer.scrollHeight - messagesContainer.scrollTop - messagesContainer.clientHeight) <= threshold;
    const prevScrollTop = messagesContainer.scrollTop;

    // Update shareBtn visibility
    const shareBtn = document.getElementById('shareBtn');
    if (shareBtn) {
        const activeChat = state.currentChatId ? state.chats[state.currentChatId] : null;
        const isOwner = activeChat && activeChat.userId === state.userId;
        const isServerChat = activeChat && !String(activeChat.id).startsWith('local_');
        
        if (state.authToken && activeChat && isOwner && isServerChat && !state.isTemporaryChat) {
            shareBtn.classList.remove('hidden');
        } else {
            shareBtn.classList.add('hidden');
        }
    }

    const chatContainer = document.querySelector('.chat-container');
    const msgList = state.currentChatId
        ? (state.messages[state.currentChatId] || [])
        : [];

    const isEmpty = msgList.length === 0;
    chatContainer?.classList.toggle('no-messages', isEmpty);

    const messageCount = msgList.length;

    if (isEmpty) {
        messagesContainer.innerHTML = '';
        isAtBottom = true;
        hasNewUnreadMessages = false;
        updatePillTextAndVisibility();
        lastChatId = state.currentChatId;
        lastMessageCount = 0;
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

    const isChatSwitch = state.currentChatId !== lastChatId;
    if (isChatSwitch) {
        messagesContainer.innerHTML = '';
    }

    const existingBubbles = Array.from(messagesContainer.querySelectorAll('.message-bubble'));
    const existingIds = existingBubbles.map(el => el.getAttribute('data-message-id'));
    const newIds = msgList.map(msg => String(msg.id));

    // 1. Remove elements that are no longer in the list (or if chat changed)
    existingBubbles.forEach(el => {
        const id = el.getAttribute('data-message-id');
        if (!newIds.includes(id)) {
            el.remove();
        }
    });

    // 2. Insert or update elements
    msgList.forEach((msg) => {
        const msgIdStr = String(msg.id);
        let el = messagesContainer.querySelector(`.message-bubble[data-message-id="${msgIdStr}"]`);
        const html = messageBubbleHtml(msg, lastAiMsgId);
        
        if (el) {
            // Update in-place to avoid re-triggering animations on existing elements
            const tempDiv = document.createElement('div');
            tempDiv.innerHTML = html;
            const newInner = tempDiv.firstElementChild.innerHTML;
            
            if (el.innerHTML !== newInner) {
                el.innerHTML = newInner;
            }
            
            // Sync class names except for 'newly-added'
            const currentClasses = Array.from(el.classList);
            const targetClasses = Array.from(tempDiv.firstElementChild.classList);
            targetClasses.forEach(c => {
                if (!el.classList.contains(c)) el.classList.add(c);
            });
            currentClasses.forEach(c => {
                if (c !== 'newly-added' && !targetClasses.includes(c)) el.classList.remove(c);
            });
        } else {
            // Create and append the new element
            const tempDiv = document.createElement('div');
            tempDiv.innerHTML = html;
            const newEl = tempDiv.firstElementChild;
            
            // Run entry slide-up animation only if it's NOT a full chat switch/load
            if (!isChatSwitch) {
                newEl.classList.add('newly-added');
            }
            
            messagesContainer.appendChild(newEl);
        }
    });

    if (isChatSwitch) {
        lastChatId = state.currentChatId;
        lastMessageCount = messageCount;
        isAtBottom = true;
        hasNewUnreadMessages = false;
        scrollToBottom(false); // Instant snap on chat switch
        updatePillTextAndVisibility();
    } else {
        if (lastMessageCount !== 0 && messageCount > lastMessageCount) {
            const lastMsg = msgList[msgList.length - 1];
            const isOwnMsg = lastMsg.sender === 'user' && (lastMsg.userId === state.userId || String(lastMsg.id).startsWith('local_'));
            const isAiMsg = lastMsg.sender === 'ai';

            let isResponseToOwnMsg = false;
            if (isAiMsg) {
                for (let i = msgList.length - 2; i >= 0; i--) {
                    if (msgList[i].sender === 'user') {
                        const isOwnUserMsg = msgList[i].userId === state.userId || String(msgList[i].id).startsWith('local_');
                        if (isOwnUserMsg) {
                            isResponseToOwnMsg = true;
                        }
                        break;
                    }
                }
            }

            if (isOwnMsg) {
                scrollToBottom(true); // Smooth scroll when you send a message
                isAtBottom = true;
                hasNewUnreadMessages = false;
                updatePillTextAndVisibility();
            } else if (isAiMsg && isResponseToOwnMsg) {
                if (wasAtBottom) {
                    scrollToBottom(true); // Smooth scroll when AI responds to your message
                    isAtBottom = true;
                    hasNewUnreadMessages = false;
                    updatePillTextAndVisibility();
                } else {
                    messagesContainer.scrollTop = prevScrollTop;
                    isAtBottom = false;
                    hasNewUnreadMessages = true;
                    updatePillTextAndVisibility();
                }
            } else {
                // Message from another user, OR AI responding to another user's message
                // Never auto scroll, keep scroll position and show the new messages pill
                messagesContainer.scrollTop = prevScrollTop;
                isAtBottom = false;
                hasNewUnreadMessages = true;
                updatePillTextAndVisibility();
            }
        } else {
            if (forceScroll) {
                scrollToBottom(true);
                isAtBottom = true;
                hasNewUnreadMessages = false;
                updatePillTextAndVisibility();
            } else {
                messagesContainer.scrollTop = prevScrollTop;
                const currentAtBottom = (messagesContainer.scrollHeight - messagesContainer.scrollTop - messagesContainer.clientHeight) <= threshold;
                isAtBottom = currentAtBottom;
                updatePillTextAndVisibility();
            }
        }
        lastMessageCount = messageCount;
    }

    const thinkingEl = document.getElementById('thinkingIndicator');
    if (thinkingEl) {
        messagesContainer.appendChild(thinkingEl);
    }
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

    const activeChat = state.currentChatId ? state.chats[state.currentChatId] : null;
    const isShared = activeChat ? activeChat.isShared : false;
    const isOwnMessage = !isShared || !msg.userId || msg.userId === state.userId;

    let usernameLabel = '';
    if (isShared && msg.userId) {
        const username = getUsername(msg.userId);
        usernameLabel = `<div class="message-username">${escapeHtml(username)}</div>`;
    }

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
        <div class="message-bubble user ${isOwnMessage ? '' : 'other'}" data-message-id="${msg.id}" role="article">
            <div class="user-bubble-glass">
                ${cleanContent ? `<div class="user-bubble-text">${escapeHtml(cleanContent)}</div>` : ''}
                ${attachmentCard}
                ${isEdited ? '<div class="edited-indicator">(edited)</div>' : ''}
            </div>
            ${usernameLabel}
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

function scrollToBottom(smooth = false) {
    isAtBottom = true;
    hasNewUnreadMessages = false;
    updatePillTextAndVisibility();

    const performScroll = () => {
        if (!messagesContainer) return;
        
        const maxScroll = messagesContainer.scrollHeight - messagesContainer.clientHeight;
        messagesContainer.scrollTo({
            top: maxScroll,
            behavior: smooth ? 'smooth' : 'auto'
        });
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

export async function openManageAccessModal() {
    if (!state.currentChatId) return;
    const chat = state.chats[state.currentChatId];
    if (!chat) return;

    const modal = document.getElementById('manageAccessModal');
    if (!modal) return;

    // Reset inputs
    const usernameInput = document.getElementById('inviteUsername');
    if (usernameInput) usernameInput.value = '';

    // Render privacy status
    const privacyText = document.getElementById('chatPrivacyStateText');
    const revokeBtn = document.getElementById('revokeAccessBtn');
    
    if (chat.isShared) {
        if (privacyText) {
            privacyText.textContent = 'Shared Chat';
            privacyText.nextElementSibling.textContent = 'This conversation is shared with collaborators.';
        }
        if (revokeBtn) revokeBtn.classList.remove('hidden');
    } else {
        if (privacyText) {
            privacyText.textContent = 'Private Chat';
            privacyText.nextElementSibling.textContent = 'Only you have access to this conversation.';
        }
        if (revokeBtn) revokeBtn.classList.add('hidden');
    }

    // Render list
    await renderCollaboratorsList(chat);

    modal.classList.remove('hidden');
}

export function closeManageAccessModal() {
    const modal = document.getElementById('manageAccessModal');
    if (modal) {
        modal.classList.add('hidden');
    }
}

async function renderCollaboratorsList(chat) {
    const card = document.getElementById('collaboratorsListCard');
    if (!card) return;

    card.innerHTML = '<div class="loading-text" style="padding: 16px; text-align: center;">Loading collaborators...</div>';

    try {
        const listHtml = [];
        
        // 1. Render Owner row
        let ownerName = 'Owner';
        let ownerEmail = '';
        try {
            const ownerProfile = await getUserProfile(chat.userId);
            if (ownerProfile) {
                ownerName = ownerProfile.username || 'Owner';
                ownerEmail = ownerProfile.email || '';
            }
        } catch (_) {}

        listHtml.push(`
            <div class="collaborator-row">
                <div class="collaborator-info">
                    <span class="collaborator-username">${escapeHtml(ownerName)}</span>
                    ${ownerEmail ? `<span class="collaborator-email">${escapeHtml(ownerEmail)}</span>` : ''}
                </div>
                <span class="collaborator-badge owner">Owner</span>
            </div>
        `);

        // 2. Render Collaborator rows
        const collaborators = chat.collaborators || [];
        if (collaborators.length > 0) {
            for (const collabId of collaborators) {
                let collabName = 'User';
                let collabEmail = '';
                try {
                    const collabProfile = await getUserProfile(collabId);
                    if (collabProfile) {
                        collabName = collabProfile.username || 'User';
                        collabEmail = collabProfile.email || '';
                    }
                } catch (_) {}

                listHtml.push(`
                    <div class="collaborator-row">
                        <div class="collaborator-info">
                            <span class="collaborator-username">${escapeHtml(collabName)}</span>
                            ${collabEmail ? `<span class="collaborator-email">${escapeHtml(collabEmail)}</span>` : ''}
                        </div>
                        <button type="button" class="collaborator-remove-btn" onclick="window.removeCollaboratorUI('${escapeHtml(collabName)}')">Remove</button>
                    </div>
                `);
            }
        } else {
            listHtml.push(`
                <div class="collaborators-list-container" style="align-items: center; justify-content: center; opacity: 0.5; padding: 20px 0;">
                    <span style="font-size: 13px;">No collaborators yet. Invite others to join!</span>
                </div>
            `);
        }

        card.innerHTML = listHtml.join('');
    } catch (err) {
        console.error('Error rendering collaborators:', err);
        card.innerHTML = '<div class="loading-text" style="padding: 16px; text-align: center; color: var(--danger);">Error loading collaborators</div>';
    }
}

export function showNotificationPill(message) {
    const pill = document.getElementById('notificationPill');
    if (!pill) return;
    const textSpan = pill.querySelector('span');
    if (textSpan) textSpan.textContent = message;
    
    pill.classList.remove('hidden');
    
    // Auto-hide after 3 seconds
    if (window.notificationPillTimeout) {
        clearTimeout(window.notificationPillTimeout);
    }
    window.notificationPillTimeout = setTimeout(() => {
        pill.classList.add('hidden');
    }, 3000);
}
