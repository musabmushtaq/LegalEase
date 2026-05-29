// Main application entry point
import { API_BASE_URL, state, CONNECTIVITY_CHECK_INTERVAL, DEFAULT_USER_ID } from './js/config.js';
import { loadAuthState, saveAuthState, clearAuthState, handleLogin, handleRegister, handleLogout, toggleTemporaryMode, ensureUserId } from './js/auth.js';
import { loadChatCache, saveChatCache, loadChatsFromServer, createNewChat, createLocalChat, selectChat, renameChat, togglePinChat, removeChat, searchChatsServer, searchChatsLocal } from './js/chat.js';
import { initializeDOM, toggleDrawer, closeDrawer, renderUserState, renderTemporaryToggle, renderConnectionBanner, openAuthModal, closeAuthModal, renderDrawer, renderMessages, getUIElements, updateAttachmentPreview, openSettingsModal, closeSettingsModal, renderThinkingIndicator, removeThinkingIndicator, renderContextPill, updatePersonaBtn, showPrivacySections } from './js/ui.js';
import { checkHealth, saveUserMessage, generateAiReply, saveAiMessage, summarizeText, updateMessage as apiUpdateMessage, deleteMessage as apiDeleteMessage, downloadFile as apiDownloadFile, clearPersonalContext, clearAllHistory, deleteUserAccount, getUserProfile } from './js/api.js';
import { debounce, showMessage, logError } from './js/utils.js';

let connectivityInterval = null;

// Expose globals for HTML onclick handlers
window.selectChatUI = selectChatUI;
window.togglePinChatUI = togglePinChatUI;
window.renameChatUI = renameChatUI;
window.deleteChatUI = deleteChatUI;
window.editMessageUI = editMessageUI;
window.deleteMessageUI = deleteMessageUI;
window.toggleDrawer = toggleDrawer;
window.closeDrawer = closeDrawer;
window.downloadFileUI = downloadFileUI;
window.copyMessageUI = copyMessageUI;
window.thumbsUpUI = thumbsUpUI;
window.thumbsDownUI = thumbsDownUI;
window.tryReconnect = ensureConnectivity;
window.openSettingsModalUI = () => {
    console.log("Global openSettingsModalUI called");
    const uiEls = getUIElements();
    updateNetworkFields(uiEls);
    openSettingsModal();
};

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

        // Validate saved session against server if we are connected and have credentials
        if (state.isConnected && state.authToken && state.userId) {
            try {
                await getUserProfile(state.userId);
            } catch (error) {
                const isAuthError = error.message && (
                    error.message.includes('404') || 
                    error.message.includes('401') || 
                    error.message.toLowerCase().includes('not found') || 
                    error.message.toLowerCase().includes('unauthorized') || 
                    error.message.toLowerCase().includes('invalid')
                );
                if (isAuthError) {
                    console.warn('Session is invalid. Logging out...', error);
                    handleLogout();
                    state.chats = {};
                    state.messages = {};
                    state.currentChatId = null;
                    createLocalChat();
                    saveChatCache();
                }
            }
        }

        if (state.isConnected && !state.isTemporaryChat && state.userId) {
            try {
                await loadChatsFromServer(state.userId);
            } catch (error) {
                logError('initializeApp - loadChatsFromServer', error);
            }
        }

        if (!state.currentChatId) {
            const firstChatId = Object.keys(state.chats)[0];
            if (firstChatId) state.currentChatId = firstChatId;
        }
        if (!state.currentChatId) createLocalChat();

        renderDrawer();
        renderMessages();
        renderUserState();
        showPrivacySections(!!state.authToken);

        // If not logged in, prompt login immediately, otherwise close auth modal
        if (state.authToken) {
            closeAuthModal();
        } else {
            openAuthModal('login');
        }
    } catch (error) {
        logError('initializeApp', error);
        showMessage('Error initializing app. Please refresh the page.');
    }
}

async function checkConnectivity() {
    try {
        state.isConnected = await checkHealth();
    } catch {
        state.isConnected = false;
    }
    renderConnectionBanner();

    if (connectivityInterval) clearTimeout(connectivityInterval);

    if (state.isConnected && !state.isTemporaryChat && state.userId) {
        try {
            await loadChatsFromServer(state.userId);
            renderDrawer();
            renderUserState();
        } catch (error) {
            logError('checkConnectivity - loadChatsFromServer', error);
        }
    }
    connectivityInterval = setTimeout(checkConnectivity, CONNECTIVITY_CHECK_INTERVAL);
}

async function ensureConnectivity() {
    try {
        state.isConnected = await checkHealth();
    } catch {
        state.isConnected = false;
    }
    renderConnectionBanner();
    return state.isConnected;
}

function setupEventListeners() {
    const ui = getUIElements();

    document.getElementById('menuBtn').addEventListener('click', toggleDrawer);
    document.getElementById('newChatBtn').addEventListener('click', createNewChatUI);
    document.getElementById('closeDrawerBtn').addEventListener('click', closeDrawer);
    document.getElementById('drawerOverlay').addEventListener('click', closeDrawer);
    document.getElementById('sendBtn').addEventListener('click', sendMessageUI);
    document.getElementById('attachBtn').addEventListener('click', () => toggleAttachmentMenu());
    ui.attachmentInput.addEventListener('change', handleAttachmentSelection);
    document.getElementById('removeAttachmentBtn').addEventListener('click', clearAttachment);
    ui.drawerSearch.addEventListener('input', debounce(handleSearchInput, 300));
    document.getElementById('tempChatToggleBtn')?.addEventListener('click', toggleTemporaryChatMode);
    document.getElementById('authActionBtn').addEventListener('click', handleAuthAction);
    ui.authForm.addEventListener('submit', handleAuthSubmit);
    document.getElementById('authSwitchBtn').addEventListener('click', () => {
        openAuthModal(state.authMode === 'login' ? 'signup' : 'login');
    });
    ui.authCloseBtn?.addEventListener('click', closeAuthModal);

    // Settings
    const openSettingsAction = (event) => {
        console.log("openSettingsAction triggered by:", event?.currentTarget?.id || "unknown");
        const uiEls = getUIElements();
        updateNetworkFields(uiEls);
        openSettingsModal();
    };

    const settingsBtn = document.getElementById('settingsBtn');
    if (settingsBtn) settingsBtn.addEventListener('click', openSettingsAction);

    const authSettingsBtn = document.getElementById('authSettingsBtn');
    if (authSettingsBtn) {
        console.log("Found authSettingsBtn, attaching click listener");
        authSettingsBtn.addEventListener('click', openSettingsAction);
    } else {
        console.warn("authSettingsBtn NOT found in the DOM!");
    }
    document.getElementById('saveSettingsBtn')?.addEventListener('click', saveSettings);
    document.getElementById('settingsCloseBtn')?.addEventListener('click', closeSettingsModal);
    document.getElementById('deleteContextBtn')?.addEventListener('click', handleDeleteContext);
    document.getElementById('clearHistoryBtn')?.addEventListener('click', handleClearHistory);
    document.getElementById('deleteAccountBtn')?.addEventListener('click', handleDeleteAccount);
    document.getElementById('logoutSettingsBtn')?.addEventListener('click', () => {
        closeSettingsModal();
        handleAuthAction();
    });

    // Attachment menu buttons
    document.getElementById('attachFileBtn')?.addEventListener('click', () => {
        closeAttachmentMenu();
        ui.attachmentInput.click();
    });
    document.getElementById('attachPersonaBtn')?.addEventListener('click', () => {
        closeAttachmentMenu();
        togglePersonaMode();
    });
    document.getElementById('attachMenuOverlay')?.addEventListener('click', closeAttachmentMenu);

    // Input
    ui.messageInput.addEventListener('input', () => {
        ui.messageInput.style.height = 'auto';
        ui.messageInput.style.height = Math.min(ui.messageInput.scrollHeight, 160) + 'px';
    });
    ui.messageInput.addEventListener('keydown', (event) => {
        if (event.key === 'Enter' && !event.shiftKey) {
            event.preventDefault();
            sendMessageUI();
        }
    });
}

// ─── Attachment Menu ───────────────────────────────────────────────────────────
function toggleAttachmentMenu() {
    const menu = document.getElementById('attachmentMenu');
    const overlay = document.getElementById('attachMenuOverlay');
    if (!menu) return;
    const isOpen = menu.classList.toggle('open');
    if (overlay) overlay.classList.toggle('active', isOpen);
}

function closeAttachmentMenu() {
    const menu = document.getElementById('attachmentMenu');
    const overlay = document.getElementById('attachMenuOverlay');
    menu?.classList.remove('open');
    overlay?.classList.remove('active');
}

// ─── Persona / Context Mode ────────────────────────────────────────────────────
function togglePersonaMode() {
    state.useContext = !state.useContext;
    updatePersonaBtn(state.useContext);
    if (state.useContext) {
        renderContextPill(true);
        setTimeout(() => renderContextPill(false), 3000);
    } else {
        renderContextPill(false);
    }
}

// ─── New Chat ──────────────────────────────────────────────────────────────────
async function createNewChatUI() {
    if (!state.authToken) {
        openAuthModal('login');
        return;
    }
    try {
        if (!state.isConnected || !state.userId) {
            createLocalChat();
        } else {
            await createNewChat(state.userId);
        }
        renderDrawer();
        renderMessages();
        renderUserState();
        document.getElementById('messageInput')?.focus();
    } catch (error) {
        logError('createNewChatUI', error);
        createLocalChat();
        renderDrawer();
        renderMessages();
    }
}

// ─── Select / Pin / Rename / Delete chat ──────────────────────────────────────
function selectChatUI(chatId) {
    selectChat(chatId);
    renderMessages();
    renderDrawer();
    closeDrawer();
    document.getElementById('messageInput')?.focus();
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
    const chat = state.chats[chatId];
    if (!chat) return;
    const newTitle = prompt('Enter new chat name:', chat.title);
    if (!newTitle?.trim()) return;
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

// ─── Send Message (Full AI Pipeline) ──────────────────────────────────────────
async function sendMessageUI() {
    if (state.sharedView || state.isAiThinking) return;

    // Require authentication — no anonymous chats saved to DB
    if (!state.authToken) {
        openAuthModal('login');
        return;
    }

    const ui = getUIElements();
    const content = ui.messageInput.value.trim();
    const file = state.attachment;

    if (!content && !file) return;
    if (!state.currentChatId) await createNewChatUI();
    if (!state.currentChatId) return;

    if (!state.isConnected) await ensureConnectivity();

    const chatId = state.currentChatId;
    const isLocal = String(chatId).startsWith('local_');
    const isPersistent = state.isConnected && !state.isTemporaryChat && !isLocal && !!state.userId;

    // 1. Optimistically add user message to local state
    const userMsgId = `local_${Date.now()}`;
    if (!state.messages[chatId]) state.messages[chatId] = [];
    const userMsg = {
        id: userMsgId,
        sender: 'user',
        content: content || (file ? file.name : ''),
        createdAt: new Date().toISOString(),
        isNew: true,
        fileName: file?.name || null,
        localFileUrl: file ? URL.createObjectURL(file) : null,
    };
    state.messages[chatId].push(userMsg);

    ui.messageInput.value = '';
    ui.messageInput.style.height = 'auto';
    clearAttachment();
    renderMessages();
    saveChatCache();

    // 2. Show thinking indicator
    state.isAiThinking = true;
    renderThinkingIndicator();

    try {
        // 3. Save user message to DB (persistent chats only)
        if (isPersistent) {
            try {
                const saved = await saveUserMessage(chatId, content, file);
                // Update local message with server ID / file info
                const idx = state.messages[chatId].findIndex(m => m.id === userMsgId);
                if (idx !== -1 && saved?.message) {
                    state.messages[chatId][idx] = {
                        ...state.messages[chatId][idx],
                        id: saved.message.id || userMsgId,
                        fileId: saved.message.file_id || null,
                        fileName: saved.message.filename || file?.name || null,
                        isNew: false,
                    };
                }
            } catch (e) {
                logError('saveUserMessage', e);
                // Non-fatal — still try to get AI response
            }
        }

        // 4. Generate AI response
        if (!state.isConnected) {
            throw new Error('Offline');
        }

        const messagesForContext = state.isTemporaryChat
            ? state.messages[chatId]
            : null;

        const aiResp = await generateAiReply(
            isPersistent ? chatId : null,
            messagesForContext,
            state.useContext
        );

        const aiContent = aiResp?.assistant_message?.content || "I'm sorry, I encountered an error. Please try again.";

        // 5. Add AI message locally
        const aiMsgId = `local_ai_${Date.now()}`;
        const aiMsg = {
            id: aiMsgId,
            sender: 'ai',
            content: aiContent,
            createdAt: new Date().toISOString(),
            isNew: true,
        };
        state.messages[chatId].push(aiMsg);

        // Update chat timestamp
        if (state.chats[chatId]) state.chats[chatId].updatedAt = new Date().toISOString();

        // 6. Save AI message to DB (persistent chats only)
        if (isPersistent) {
            try {
                await saveAiMessage(chatId, aiContent);
            } catch (e) {
                logError('saveAiMessage', e);
            }
        }

        // 7. Auto-rename "New Chat" from first message
        const isFirstMessage = state.chats[chatId]?.title === 'New Chat';
        if (isFirstMessage && isPersistent && content) {
            autoRenameChat(chatId, content);
        }

    } catch (error) {
        logError('sendMessageUI - AI generation', error);
        const errContent = state.isConnected
            ? 'Error generating response. Please try again.'
            : `Backend unavailable. Check that the API is running at ${window.API_BASE_URL}.`;
        state.messages[chatId].push({
            id: `local_err_${Date.now()}`,
            sender: 'ai',
            content: errContent,
            createdAt: new Date().toISOString(),
            isNew: false,
        });
    } finally {
        state.isAiThinking = false;
        removeThinkingIndicator();
        saveChatCache();
        renderMessages();
    }
}

async function autoRenameChat(chatId, firstMessage) {
    try {
        const summary = await summarizeText(firstMessage);
        if (summary && summary.trim() && state.chats[chatId]) {
            await renameChat(chatId, summary.trim());
            renderDrawer();
        }
    } catch (e) {
        logError('autoRenameChat', e);
    }
}

// ─── Message Actions ───────────────────────────────────────────────────────────
function copyMessageUI(messageId) {
    const msg = state.messages[state.currentChatId]?.find(m => m.id === messageId);
    if (!msg) return;
    navigator.clipboard.writeText(msg.content).then(() => {
        showMessage('Copied to clipboard');
    }).catch(() => showMessage('Could not copy'));
}

function thumbsUpUI(messageId) {
    const btn = document.querySelector(`[data-thumb-up="${messageId}"]`);
    const downBtn = document.querySelector(`[data-thumb-down="${messageId}"]`);
    if (!btn) return;
    const isActive = btn.classList.toggle('active');
    downBtn?.classList.remove('active');
    btn.setAttribute('aria-pressed', String(isActive));
}

function thumbsDownUI(messageId) {
    const btn = document.querySelector(`[data-thumb-down="${messageId}"]`);
    const upBtn = document.querySelector(`[data-thumb-up="${messageId}"]`);
    if (!btn) return;
    const isActive = btn.classList.toggle('active');
    upBtn?.classList.remove('active');
    btn.setAttribute('aria-pressed', String(isActive));
}

async function downloadFileUI(fileId, fileName) {
    showMessage(`Downloading ${fileName}...`);
    try {
        const blob = await apiDownloadFile(fileId);
        if (!blob) { showMessage('Download failed.'); return; }
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = fileName;
        a.click();
        URL.revokeObjectURL(url);
        showMessage('Download complete.');
    } catch {
        showMessage('Download failed.');
    }
}

function editMessageUI(messageId) {
    const msg = state.messages[state.currentChatId]?.find(m => m.id === messageId);
    if (!msg) return;
    const newContent = prompt('Edit message:', msg.content);
    if (newContent === null || !newContent.trim()) return;
    updateMessageUI(messageId, newContent);
}

async function updateMessageUI(messageId, newContent) {
    if (!state.currentChatId) return;
    const chatId = state.currentChatId;
    const isLocal = String(messageId).startsWith('local_') || String(chatId).startsWith('local_');
    try {
        if (state.isConnected && !state.isTemporaryChat && !isLocal) {
            await apiUpdateMessage(chatId, messageId, newContent);
        }
        const msg = state.messages[chatId]?.find(m => m.id === messageId);
        if (msg) { msg.content = newContent; msg.edited_at = new Date().toISOString(); }
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
    const isLocal = String(messageId).startsWith('local_') || String(chatId).startsWith('local_');
    try {
        if (state.isConnected && !state.isTemporaryChat && !isLocal) {
            await apiDeleteMessage(chatId, messageId);
        }
        const idx = state.messages[chatId]?.findIndex(m => m.id === messageId);
        if (idx !== -1) state.messages[chatId].splice(idx, 1);
        saveChatCache();
        renderMessages();
    } catch (error) {
        logError('deleteMessageUI', error);
        showMessage('Could not delete message.');
    }
}

// ─── Attachment helpers ────────────────────────────────────────────────────────
function handleAttachmentSelection(event) {
    const file = event.target.files?.[0];
    if (!file) return;
    if (file.size > 10 * 1024 * 1024) {
        showMessage('File size exceeds 10MB limit.');
        event.target.value = '';
        return;
    }
    state.attachment = file;
    updateAttachmentPreview(file);
}

function clearAttachment() {
    state.attachment = null;
    const input = document.getElementById('attachmentInput');
    if (input) input.value = '';
    updateAttachmentPreview(null);
}

// ─── Auth ──────────────────────────────────────────────────────────────────────
async function handleAuthAction() {
    if (state.authToken) {
        handleLogout();
        state.chats = {};
        state.messages = {};
        state.currentChatId = null;
        createLocalChat();
        renderUserState();
        renderTemporaryToggle();
        renderDrawer();
        renderMessages();
        showPrivacySections(false);
        saveChatCache();
        openAuthModal('login');
    } else {
        openAuthModal('login');
    }
}

async function handleAuthSubmit(event) {
    event.preventDefault();
    if (state.sharedView) return;
    const ui = getUIElements();
    const username = ui.authUsername.value.trim();
    const password = ui.authPassword.value.trim();
    const email = ui.authEmail?.value.trim();
    const confirmPassword = ui.authConfirmPassword?.value.trim();

    if (!username || !password) { showMessage('Please fill in username and password.'); return; }

    try {
        if (state.authMode === 'signup') {
            if (!email) { showMessage('Please enter your email address.'); return; }
            if (password !== confirmPassword) { showMessage('Passwords do not match.'); return; }
            await handleRegister(username, email, password);
        } else {
            await handleLogin(username, password);
        }
        closeAuthModal();
        renderUserState();
        showPrivacySections(true);
        if (state.userId) {
            await loadChatsFromServer(state.userId);
        }
        renderDrawer();
        renderMessages();
    } catch (error) {
        logError('handleAuthSubmit', error);
        showMessage(error.message || 'Authentication failed.');
    }
}

function toggleTemporaryChatMode() {
    toggleTemporaryMode();
    renderUserState();
    renderTemporaryToggle();
    saveChatCache();
}

// ─── Search ────────────────────────────────────────────────────────────────────
async function handleSearchInput(event) {
    state.searchQuery = event.target.value.trim();
    if (!state.searchQuery) {
        state.searchResults = null;
        renderDrawer();
        return;
    }
    if (state.isConnected && state.userId) {
        try {
            state.searchResults = await searchChatsServer(state.userId, state.searchQuery);
        } catch {
            state.searchResults = searchChatsLocal(state.searchQuery);
        }
    } else {
        state.searchResults = searchChatsLocal(state.searchQuery);
    }
    renderDrawer();
}

// ─── Settings ─────────────────────────────────────────────────────────────────
function updateNetworkFields(uiEls) {
    if (!uiEls) return;
    const apiUrl = window.API_BASE_URL || 'http://127.0.0.1:8000';
    let protocol = 'http://';
    let port = ':8000';
    let ip = '127.0.0.1';

    try {
        const u = new URL(apiUrl);
        protocol = `${u.protocol}//`;
        ip = u.hostname;
        port = u.port ? `:${u.port}` : ':8000';
    } catch (_) {
        const match = apiUrl.match(/^(https?:\/\/)?([^:/]+)(:\d+)?/);
        if (match) {
            protocol = match[1] || 'http://';
            ip = match[2] || '127.0.0.1';
            port = match[3] || ':8000';
        }
    }

    if (uiEls.settingsApiPrefix) uiEls.settingsApiPrefix.textContent = protocol;
    if (uiEls.settingsApiSuffix) uiEls.settingsApiSuffix.textContent = port;
    if (uiEls.settingsApiIp) uiEls.settingsApiIp.value = ip;
}

async function saveSettings() {
    const ui = getUIElements();
    const ip = ui.settingsApiIp?.value.trim();
    if (!ip) { showMessage('IP address / Host cannot be empty'); return; }
    
    const protocol = ui.settingsApiPrefix?.textContent || 'http://';
    const port = ui.settingsApiSuffix?.textContent || ':8000';
    const newUrl = `${protocol}${ip}${port}`;
    
    try { localStorage.setItem('legalease_api_base', newUrl); } catch {}
    window.API_BASE_URL = newUrl;
    closeSettingsModal();
    showMessage('Settings saved. Rechecking connectivity...');
    await ensureConnectivity();
}

async function handleDeleteContext() {
    if (!state.userId) return;
    if (!confirm('This will permanently delete your personal AI context. Continue?')) return;
    try {
        await clearPersonalContext(state.userId);
        showMessage('Personal context deleted.');
    } catch {
        showMessage('Failed to delete context. Check connection.');
    }
}

async function handleClearHistory() {
    if (!state.userId) return;
    if (!confirm('This will permanently delete ALL your chat history. This cannot be undone. Continue?')) return;
    try {
        await clearAllHistory(state.userId);
        state.chats = {};
        state.messages = {};
        state.currentChatId = null;
        createLocalChat();
        saveChatCache();
        renderDrawer();
        renderMessages();
        showMessage('All chat history cleared.');
    } catch {
        showMessage('Failed to clear history. Check connection.');
    }
}

async function handleDeleteAccount() {
    if (!state.userId) return;
    if (!confirm('WARNING: This will permanently delete your account and all data. This cannot be undone. Continue?')) return;
    try {
        await deleteUserAccount(state.userId);
        handleLogout();
        state.chats = {};
        state.messages = {};
        state.currentChatId = null;
        createLocalChat();
        renderUserState();
        renderDrawer();
        renderMessages();
        closeSettingsModal();
        showMessage('Account deleted.');
        openAuthModal('login');
    } catch {
        showMessage('Failed to delete account. Check connection.');
    }
}

// ─── Bootstrap ────────────────────────────────────────────────────────────────
window.addEventListener('DOMContentLoaded', initializeApp);
window.addEventListener('beforeunload', () => {
    if (connectivityInterval) clearTimeout(connectivityInterval);
});
