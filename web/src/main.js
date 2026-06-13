// Main application entry point
import { API_BASE_URL, state, CONNECTIVITY_CHECK_INTERVAL, DEFAULT_USER_ID } from './js/config.js';
import { loadAuthState, saveAuthState, clearAuthState, handleLogin, handleRegister, handleLogout, toggleTemporaryMode, ensureUserId } from './js/auth.js';
import { loadChatCache, saveChatCache, loadChatsFromServer, createNewChat, createLocalChat, selectChat, renameChat, togglePinChat, removeChat, searchChatsServer, searchChatsLocal, disconnectChatWebSocket, connectChatWebSocket, connectUserWebSocket, disconnectUserWebSocket } from './js/chat.js';
import { initializeDOM, toggleDrawer, closeDrawer, renderUserState, renderTemporaryToggle, renderConnectionBanner, openAuthModal, closeAuthModal, renderDrawer, renderMessages, getUIElements, updateAttachmentPreview, openSettingsModal, closeSettingsModal, renderThinkingIndicator, removeThinkingIndicator, renderContextPill, updatePersonaBtn, showPrivacySections, openManageAccessModal, closeManageAccessModal } from './js/ui.js';
import { checkHealth, saveUserMessage, generateAiReply, saveAiMessage, summarizeText, updateMessage as apiUpdateMessage, deleteMessage as apiDeleteMessage, downloadFile as apiDownloadFile, clearPersonalContext, clearAllHistory, deleteUserAccount, getUserProfile, inviteCollaborator, removeCollaborator, updateChat } from './js/api.js';
import { debounce, showMessage, logError, showCustomConfirm, showCustomPrompt } from './js/utils.js';

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
window.showChatMenuUI = showChatMenuUI;
window.hideChatMenuUI = hideChatMenuUI;
window.clearAttachmentUI = clearAttachment;
window.renderMessages = renderMessages;
window.renderDrawer = renderDrawer;
window.removeCollaboratorUI = removeCollaboratorUI;
window.openManageAccessModalUI = openManageAccessModal;
window.closeManageAccessModalUI = closeManageAccessModal;
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
                connectUserWebSocket(state.userId);
            } catch (error) {
                logError('initializeApp - loadChatsFromServer', error);
            }
        }

        if (!state.currentChatId && (!state.authToken || state.isTemporaryChat)) {
            createLocalChat();
        }

        if (state.currentChatId) {
            connectChatWebSocket(state.currentChatId);
        }

        renderDrawer();
        renderMessages(true);
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
            if (!state.userWsConnection) {
                connectUserWebSocket(state.userId);
            }
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
    document.getElementById('attachBtn').addEventListener('click', () => {
        if (state.attachment || state.useContext) {
            clearAttachment();
        } else {
            toggleAttachmentMenu();
        }
    });
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
    document.getElementById('settingsCloseBtn')?.addEventListener('click', saveSettings);
    document.getElementById('deleteContextBtn')?.addEventListener('click', handleDeleteContext);
    document.getElementById('clearHistoryBtn')?.addEventListener('click', handleClearHistory);
    document.getElementById('deleteAccountBtn')?.addEventListener('click', handleDeleteAccount);
    document.getElementById('logoutSettingsBtn')?.addEventListener('click', () => {
        closeSettingsModal();
        handleAuthAction();
    });

    // Collaboration
    document.getElementById('shareBtn')?.addEventListener('click', () => {
        openManageAccessModal();
    });
    document.getElementById('manageAccessCloseBtn')?.addEventListener('click', () => {
        closeManageAccessModal();
    });
    document.getElementById('inviteForm')?.addEventListener('submit', handleInviteSubmit);
    document.getElementById('revokeAccessBtn')?.addEventListener('click', handleRevokeAccess);

    // Sidebar custom actions
    const sidebarNewChatBtn = document.getElementById('sidebarNewChatBtn');
    if (sidebarNewChatBtn) sidebarNewChatBtn.addEventListener('click', createNewChatUI);
    const sidebarSettingsBtn = document.getElementById('sidebarSettingsBtn');
    if (sidebarSettingsBtn) sidebarSettingsBtn.addEventListener('click', openSettingsAction);

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
        toggleSendBtnVisibility();
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
        // Enforce mutual exclusion: clear file attachments when persona is attached
        state.attachment = null;
        const input = document.getElementById('attachmentInput');
        if (input) input.value = '';
    }
    
    updateAttachmentPreview(state.attachment);
}

// ─── New Chat ──────────────────────────────────────────────────────────────────
async function createNewChatUI() {
    if (!state.authToken) {
        openAuthModal('login');
        return;
    }
    state.currentChatId = null;
    saveChatCache();
    
    clearAttachment();
    renderDrawer();
    renderMessages(true);
    renderUserState();
    document.getElementById('messageInput')?.focus();
}

// ─── Select / Pin / Rename / Delete chat ──────────────────────────────────────
function selectChatUI(chatId) {
    selectChat(chatId);
    renderMessages(true);
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
    const newTitle = await showCustomPrompt('Enter new chat name:', chat.title);
    if (newTitle === null || !newTitle.trim()) return;
    try {
        await renameChat(chatId, newTitle);
        renderDrawer();
    } catch (error) {
        logError('renameChatUI', error);
        showMessage('Could not rename chat.');
    }
}

async function deleteChatUI(chatId) {
    const confirmed = await showCustomConfirm('Are you sure you want to delete this chat?');
    if (!confirmed) return;
    try {
        await removeChat(chatId);
        renderDrawer();
        renderMessages(true);
    } catch (error) {
        logError('deleteChatUI', error);
        showMessage('Could not delete chat.');
    }
}

// ─── Send Message (Full AI Pipeline) ──────────────────────────────────────────
function toggleSendBtnVisibility() {
    const messageInput = document.getElementById('messageInput');
    const sendBtn = document.getElementById('sendBtn');
    if (messageInput && sendBtn) {
        const text = messageInput.value.trim();
        if (text) {
            sendBtn.classList.remove('hidden-send');
        } else {
            sendBtn.classList.add('hidden-send');
        }
    }
}

async function sendMessageUI() {
    if (state.sharedView || state.isAiThinking) return;

    // Require authentication — no anonymous chats saved to DB
    if (!state.authToken) {
        openAuthModal('login');
        return;
    }

    const ui = getUIElements();
    const content = ui.messageInput.value.trim();
    
    // Capture active useContext flag before clearAttachment resets it
    const activeUseContext = state.useContext;

    // Enforce mutual exclusion and use virtual files for database persistence of persona messages
    const file = state.attachment || (state.useContext ? new File(["Active Context"], "Persona Attached.txt", { type: "text/plain" }) : null);

    if (!content && !file) return;

    // Dynamically create a chat on first message rather than creating empty chats
    if (!state.currentChatId) {
        try {
            if (!state.isConnected || !state.userId) {
                createLocalChat();
            } else {
                const response = await createNewChat(state.userId);
                state.currentChatId = response.id;
            }
            renderDrawer();
        } catch (error) {
            logError('sendMessageUI - createNewChat', error);
            createLocalChat();
            renderDrawer();
        }
    }
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
        userId: state.userId || DEFAULT_USER_ID,
    };
    state.messages[chatId].push(userMsg);

    ui.messageInput.value = '';
    ui.messageInput.style.height = 'auto';
    toggleSendBtnVisibility();
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
                        userId: saved.message.user_id || state.userId || DEFAULT_USER_ID,
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
            activeUseContext
        );

        const aiContent = aiResp?.assistant_message?.content || "I'm sorry, I encountered an error. Please try again.";

        // 5. Add AI message locally (only if it doesn't already exist from WebSocket broadcast)
        const exists = state.messages[chatId].some(m => m.sender === 'ai' && m.content === aiContent);
        if (!exists) {
            const aiMsgId = `local_ai_${Date.now()}`;
            const aiMsg = {
                id: aiMsgId,
                sender: 'ai',
                content: aiContent,
                createdAt: new Date().toISOString(),
                isNew: true,
            };
            state.messages[chatId].push(aiMsg);
        }

        // Update chat timestamp
        if (state.chats[chatId]) state.chats[chatId].updatedAt = new Date().toISOString();

        // 6. Save AI message to DB (persistent chats only, skip on API errors)
        if (isPersistent && !aiContent.startsWith('Error:')) {
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

// Robust copy-to-clipboard helper that falls back to document.execCommand if needed
function copyTextToClipboard(text) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
        return navigator.clipboard.writeText(text);
    }
    return new Promise((resolve, reject) => {
        try {
            const textArea = document.createElement("textarea");
            textArea.value = text;
            textArea.style.top = "0";
            textArea.style.left = "0";
            textArea.style.position = "fixed";
            document.body.appendChild(textArea);
            textArea.focus();
            textArea.select();
            const successful = document.execCommand('copy');
            document.body.removeChild(textArea);
            if (successful) {
                resolve();
            } else {
                reject(new Error('execCommand copy failed'));
            }
        } catch (err) {
            reject(err);
        }
    });
}

function copyMessageUI(messageId) {
    const msg = state.messages[state.currentChatId]?.find(m => m.id === messageId);
    if (!msg) return;
    copyTextToClipboard(msg.content).then(() => {
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

async function editMessageUI(messageId) {
    const msg = state.messages[state.currentChatId]?.find(m => m.id === messageId);
    if (!msg) return;
    const newContent = await showCustomPrompt('Edit message:', msg.content);
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
    const confirmed = await showCustomConfirm('Delete this message?');
    if (!confirmed) return;
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
    
    // Enforce mutual exclusion: clear persona mode when a file is selected
    state.useContext = false;
    updatePersonaBtn(false);
    
    updateAttachmentPreview(file);
}

function clearAttachment() {
    state.attachment = null;
    state.useContext = false; // Disable persona mode when clearing
    updatePersonaBtn(false);
    
    const input = document.getElementById('attachmentInput');
    if (input) input.value = '';
    updateAttachmentPreview(null);
}

// ─── Auth ──────────────────────────────────────────────────────────────────────
async function handleAuthAction() {
    if (state.authToken) {
        disconnectChatWebSocket();
        disconnectUserWebSocket();
        handleLogout();
        state.chats = {};
        state.messages = {};
        state.currentChatId = null;
        createLocalChat();
        renderUserState();
        renderTemporaryToggle();
        renderDrawer();
        renderMessages(true);
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
            connectUserWebSocket(state.userId);
        }
        if (state.currentChatId) {
            connectChatWebSocket(state.currentChatId);
        }
        renderDrawer();
        renderMessages(true);
    } catch (error) {
        logError('handleAuthSubmit', error);
        showMessage(error.message || 'Authentication failed.');
    }
}

function toggleTemporaryChatMode() {
    disconnectChatWebSocket();
    toggleTemporaryMode();
    renderUserState();
    renderTemporaryToggle();
    saveChatCache();
}

// ─── Collaboration ─────────────────────────────────────────────────────────────
async function handleInviteSubmit(event) {
    event.preventDefault();
    const input = document.getElementById('inviteUsername');
    if (!input) return;
    const value = input.value.trim();
    if (!value) return;

    const chatId = state.currentChatId;
    if (!chatId) return;

    try {
        const inviteBtn = document.getElementById('inviteSubmitBtn');
        if (inviteBtn) inviteBtn.disabled = true;
        
        const res = await inviteCollaborator(chatId, value);
        if (res && res.success) {
            showMessage(`Successfully invited ${value}.`);
            input.value = '';
            
            // Reload chat details and update UI
            await loadChatsFromServer(state.userId);
            // Refresh modal
            await openManageAccessModal();
            renderDrawer();
        } else {
            showMessage(res?.message || 'Could not invite collaborator.');
        }
    } catch (err) {
        logError('handleInviteSubmit', err);
        showMessage(err.message || 'Error inviting collaborator.');
    } finally {
        const inviteBtn = document.getElementById('inviteSubmitBtn');
        if (inviteBtn) inviteBtn.disabled = false;
    }
}

async function handleRevokeAccess() {
    const chatId = state.currentChatId;
    if (!chatId) return;

    const confirmed = await showCustomConfirm('Are you sure you want to revoke access? All collaborators will lose access, and this chat will become private.');
    if (!confirmed) return;

    try {
        // PATCH updateChat with is_shared: false
        await updateChat(chatId, { is_shared: false });
        showMessage('Chat access revoked.');
        
        closeManageAccessModal();
        await loadChatsFromServer(state.userId);
        renderDrawer();
        renderMessages();
    } catch (err) {
        logError('handleRevokeAccess', err);
        showMessage('Error revoking access.');
    }
}

async function removeCollaboratorUI(username) {
    const chatId = state.currentChatId;
    if (!chatId) return;

    const confirmed = await showCustomConfirm(`Remove collaborator ${username} from this chat?`);
    if (!confirmed) return;

    try {
        const res = await removeCollaborator(chatId, username);
        if (res && res.success) {
            showMessage(`Removed ${username}.`);
            await loadChatsFromServer(state.userId);
            await openManageAccessModal();
            renderDrawer();
        } else {
            showMessage(res?.message || 'Could not remove collaborator.');
        }
    } catch (err) {
        logError('removeCollaboratorUI', err);
        showMessage(err.message || 'Error removing collaborator.');
    }
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
    const confirmed = await showCustomConfirm('This will permanently delete your personal AI context. Continue?');
    if (!confirmed) return;
    try {
        await clearPersonalContext(state.userId);
        showMessage('Personal context deleted.');
    } catch {
        showMessage('Failed to delete context. Check connection.');
    }
}

async function handleClearHistory() {
    if (!state.userId) return;
    const confirmed = await showCustomConfirm('This will permanently delete ALL your chat history. This cannot be undone. Continue?');
    if (!confirmed) return;
    try {
        await clearAllHistory(state.userId);
        state.chats = {};
        state.messages = {};
        state.currentChatId = null;
        createLocalChat();
        saveChatCache();
        renderDrawer();
        renderMessages(true);
        showMessage('All chat history cleared.');
    } catch {
        showMessage('Failed to clear history. Check connection.');
    }
}

async function handleDeleteAccount() {
    if (!state.userId) return;
    const confirmed = await showCustomConfirm('WARNING: This will permanently delete your account and all data. This cannot be undone. Continue?');
    if (!confirmed) return;
    try {
        await deleteUserAccount(state.userId);
        handleLogout();
        state.chats = {};
        state.messages = {};
        state.currentChatId = null;
        createLocalChat();
        renderUserState();
        renderDrawer();
        renderMessages(true);
        closeSettingsModal();
        showMessage('Account deleted.');
        openAuthModal('login');
    } catch {
        showMessage('Failed to delete account. Check connection.');
    }
}

// ─── Chat Context Menu Handlers ────────────────────────────────────────────────
function showChatMenuUI(event, chatId) {
    event.stopPropagation();
    
    let menu = document.getElementById('chatContextMenu');
    if (!menu) {
        menu = document.createElement('div');
        menu.id = 'chatContextMenu';
        menu.className = 'chat-context-menu';
        document.body.appendChild(menu);
    }
    
    const chat = state.chats[chatId];
    if (!chat) return;
    
    const pinText = chat.isPinned ? 'Unpin' : 'Pin';
    const pinIcon = chat.isPinned 
        ? `<svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor" style="transform: rotate(45deg);"><path d="M16 12V4h1V2H7v2h1v8l-2 2v2h5.2v6h1.6v-6H18v-2l-2-2z"/></svg>`
        : `<svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M16 12V4h1V2H7v2h1v8l-2 2v2h5.2v6h1.6v-6H18v-2l-2-2z"/></svg>`;
        
    const isOwner = chat.userId === state.userId;
    const isServerChat = !String(chatId).startsWith('local_');
    const showShare = state.authToken && isOwner && isServerChat && !state.isTemporaryChat;

    let shareItem = '';
    if (showShare) {
        const shareText = chat.isShared ? 'Manage Shared Access' : 'Share';
        const shareIcon = chat.isShared
            ? `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>`
            : `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.59" y1="13.51" x2="15.42" y2="17.49"/><line x1="15.41" y1="6.51" x2="8.59" y2="10.49"/></svg>`;
            
        shareItem = `
            <button class="chat-context-menu-item" onclick="window.selectChatUI('${chatId}'); window.openManageAccessModalUI(); hideChatMenuUI();">
                ${shareIcon}
                <span>${shareText}</span>
            </button>
        `;
    }

    menu.innerHTML = `
        <button class="chat-context-menu-item" onclick="window.togglePinChatUI('${chatId}'); hideChatMenuUI();">
            ${pinIcon}
            <span>${pinText}</span>
        </button>
        ${shareItem}
        <button class="chat-context-menu-item" onclick="window.renameChatUI('${chatId}'); hideChatMenuUI();">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
            <span>Rename</span>
        </button>
        <button class="chat-context-menu-item destructive" onclick="window.deleteChatUI('${chatId}'); hideChatMenuUI();">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg>
            <span>Delete</span>
        </button>
    `;
    
    const trigger = event.currentTarget;
    document.querySelectorAll('.chat-menu-trigger').forEach(el => el.classList.remove('active'));
    trigger.classList.add('active');
    
    const rect = trigger.getBoundingClientRect();
    const menuWidth = 170;
    
    menu.style.top = `${rect.bottom + window.scrollY + 4}px`;
    menu.style.left = `${rect.right - menuWidth + window.scrollX}px`;
    
    menu.classList.add('open');
    
    const closeMenu = (e) => {
        if (!menu.contains(e.target) && !trigger.contains(e.target)) {
            hideChatMenuUI();
            document.removeEventListener('click', closeMenu);
        }
    };
    setTimeout(() => {
        document.addEventListener('click', closeMenu);
    }, 10);
}

function hideChatMenuUI() {
    const menu = document.getElementById('chatContextMenu');
    if (menu) {
        menu.classList.remove('open');
    }
    document.querySelectorAll('.chat-menu-trigger').forEach(el => el.classList.remove('active'));
}

// ─── Bootstrap ────────────────────────────────────────────────────────────────
window.addEventListener('DOMContentLoaded', initializeApp);
window.addEventListener('beforeunload', () => {
    if (connectivityInterval) clearTimeout(connectivityInterval);
});
