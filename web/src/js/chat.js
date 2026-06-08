// Chat management module
import { state, CHAT_CACHE_KEY, API_BASE_URL } from './config.js';
import { 
    loadChats as apiLoadChats, 
    createChat as apiCreateChat, 
    deleteChat as apiDeleteChat,
    updateChat as apiUpdateChat,
    searchChats as apiSearchChats
} from './api.js';
import { logError, makeId } from './utils.js';

export function loadChatCache() {
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

export function saveChatCache() {
    localStorage.setItem(CHAT_CACHE_KEY, JSON.stringify({
        chats: state.chats,
        messages: state.messages,
        currentChatId: state.currentChatId,
        isTemporaryChat: state.isTemporaryChat,
    }));
}

export async function loadChatsFromServer(userId) {
    try {
        const response = await apiLoadChats(userId);
        const items = response.items || [];
        state.chats = {};
        state.messages = {};
        
        items.forEach(item => {
            state.chats[item.id] = {
                id: item.id,
                title: item.title,
                updatedAt: item.updated_at,
                isPinned: item.is_pinned || false,
                isShared: item.is_shared || false,
                shareLink: item.share_link || null,
                userId: item.user_id || null,
                collaborators: item.collaborators || [],
            };
            state.messages[item.id] = (item.messages || []).map(msg => ({
                id: msg.id,
                sender: msg.sender,
                content: msg.content,
                createdAt: msg.created_at,
                edited_at: msg.edited_at,
                fileId: msg.file_id || null,
                fileName: msg.filename || null,
                isNew: false,
            }));
        });
        
        if (!state.currentChatId || !state.chats[state.currentChatId]) {
            state.currentChatId = items.length > 0 ? items[0].id : null;
        }
        
        saveChatCache();
    } catch (error) {
        logError('loadChatsFromServer', error);
        throw error;
    }
}

export async function createNewChat(userId) {
    try {
        const response = await apiCreateChat(userId);
        state.chats[response.id] = {
            id: response.id,
            title: response.title,
            updatedAt: response.updated_at,
            isPinned: response.is_pinned || false,
            isShared: response.is_shared || false,
            shareLink: response.share_link || null,
            userId: response.user_id || userId,
            collaborators: response.collaborators || [],
        };
        state.messages[response.id] = [];
        state.currentChatId = response.id;
        saveChatCache();
        return response;
    } catch (error) {
        logError('createNewChat', error);
        throw error;
    }
}

export function createLocalChat() {
    const chatId = makeId('local');
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
}

export function selectChat(chatId) {
    state.currentChatId = chatId;
    saveChatCache();
    connectChatWebSocket(chatId);
}

function isServerBackedChat(chatId) {
    return state.isConnected && !state.isTemporaryChat && !String(chatId).startsWith('local_');
}

export async function renameChat(chatId, newTitle) {
    const trimmed = newTitle.trim();
    if (!state.chats[chatId]) return;

    if (!isServerBackedChat(chatId)) {
        state.chats[chatId].title = trimmed;
        state.chats[chatId].updatedAt = new Date().toISOString();
        saveChatCache();
        return state.chats[chatId];
    }

    try {
        const response = await apiUpdateChat(chatId, { title: trimmed });
        state.chats[chatId].title = response.title;
        state.chats[chatId].updatedAt = response.updated_at;
        saveChatCache();
        return response;
    } catch (error) {
        logError('renameChat', error);
        throw error;
    }
}

export async function togglePinChat(chatId) {
    const chat = state.chats[chatId];
    if (!chat) return;

    const isPinned = !chat.isPinned;
    if (!isServerBackedChat(chatId)) {
        chat.isPinned = isPinned;
        saveChatCache();
        return chat;
    }

    try {
        const response = await apiUpdateChat(chatId, { is_pinned: isPinned });
        state.chats[chatId].isPinned = response.is_pinned;
        saveChatCache();
        return response;
    } catch (error) {
        logError('togglePinChat', error);
        throw error;
    }
}

export async function removeChat(chatId) {
    if (!state.chats[chatId]) return;

    if (isServerBackedChat(chatId)) {
        try {
            await apiDeleteChat(chatId);
        } catch (error) {
            logError('removeChat', error);
            throw error;
        }
    }

    delete state.chats[chatId];
    delete state.messages[chatId];
    if (state.currentChatId === chatId) {
        state.currentChatId = Object.keys(state.chats)[0] || null;
    }
    saveChatCache();
}

export function searchChatsLocal(query) {
    if (!query) {
        return [];
    }
    
    return Object.values(state.chats).filter(chat => {
        const titleMatch = chat.title.toLowerCase().includes(query.toLowerCase());
        const messageMatch = (state.messages[chat.id] || []).some(msg => 
            msg.content.toLowerCase().includes(query.toLowerCase())
        );
        return titleMatch || messageMatch;
    });
}

export async function searchChatsServer(userId, query) {
    try {
        if (!query) return [];
        const response = await apiSearchChats(userId, query);
        return (response.items || []).map(item => ({
            id: item.id,
            title: item.title,
            updatedAt: item.updated_at,
            isPinned: item.is_pinned || false,
        }));
    } catch (error) {
        logError('searchChatsServer', error);
        return [];
    }
}

export function getCurrentChat() {
    return state.currentChatId ? state.chats[state.currentChatId] : null;
}

export function getCurrentMessages() {
    return state.currentChatId ? (state.messages[state.currentChatId] || []) : [];
}

export function disconnectChatWebSocket() {
    if (state.wsConnection) {
        try {
            state.wsConnection.close();
        } catch (_) {}
        state.wsConnection = null;
    }
}

export function connectChatWebSocket(chatId) {
    disconnectChatWebSocket();
    if (!chatId || state.isTemporaryChat || String(chatId).startsWith('local_')) {
        return;
    }

    const base = (window.API_BASE_URL) ? window.API_BASE_URL : API_BASE_URL;
    const wsScheme = base.startsWith('https') ? 'wss' : 'ws';
    const urlWithoutScheme = base.replace(/^https?:\/\//, '');
    const wsUrl = `${wsScheme}://${urlWithoutScheme}/ws/chats/${chatId}`;

    try {
        const ws = new WebSocket(wsUrl);
        state.wsConnection = ws;

        ws.onmessage = (event) => {
            try {
                const data = JSON.parse(event.data);
                if (data.type === 'new_message' && data.chat_id === chatId) {
                    const msg = data.message;
                    if (!msg || !msg.id) return;

                    // Initialize array if undefined
                    if (!state.messages[chatId]) {
                        state.messages[chatId] = [];
                    }

                    // Check if message already exists
                    const exists = state.messages[chatId].some(m => m.id === msg.id);
                    if (!exists) {
                        // Check if there is a matching message with same content and sender to replace/update (handles double-broadcast and local optimistic states)
                        const tempIndex = state.messages[chatId].findIndex(m => {
                            if (m.sender !== msg.sender || m.content !== msg.content) {
                                return false;
                            }
                            if (msg.sender === 'user') {
                                return String(m.id).startsWith('local_');
                            } else {
                                return true;
                            }
                        });

                        if (tempIndex !== -1) {
                            // Update the existing message's ID and properties instead of duplicating it
                            state.messages[chatId][tempIndex].id = msg.id;
                            state.messages[chatId][tempIndex].fileId = msg.file_id || null;
                            state.messages[chatId][tempIndex].fileName = msg.filename || null;
                            state.messages[chatId][tempIndex].createdAt = msg.created_at;
                            state.messages[chatId][tempIndex].edited_at = msg.edited_at;
                        } else {
                            // Add as new message
                            state.messages[chatId].push({
                                id: msg.id,
                                sender: msg.sender,
                                content: msg.content,
                                createdAt: msg.created_at,
                                edited_at: msg.edited_at,
                                fileId: msg.file_id || null,
                                fileName: msg.filename || null,
                                isNew: true,
                            });
                        }
                        
                        // Save cache
                        saveChatCache();

                        // Call renderMessages if this is the active chat
                        if (state.currentChatId === chatId && typeof window.renderMessages === 'function') {
                            window.renderMessages();
                        }
                    }
                }
            } catch (err) {
                console.error('Error parsing WebSocket message:', err);
            }
        };

        ws.onclose = () => {
            if (state.wsConnection === ws) {
                state.wsConnection = null;
            }
        };

        ws.onerror = (err) => {
            console.error('WebSocket error:', err);
        };
    } catch (e) {
        console.error('Failed to connect WebSocket:', e);
    }
}

export function disconnectUserWebSocket() {
    if (state.userWsConnection) {
        try {
            state.userWsConnection.close();
        } catch (_) {}
        state.userWsConnection = null;
    }
}

export function connectUserWebSocket(userId) {
    disconnectUserWebSocket();
    if (!userId || state.isTemporaryChat) {
        return;
    }

    const base = (window.API_BASE_URL) ? window.API_BASE_URL : API_BASE_URL;
    const wsScheme = base.startsWith('https') ? 'wss' : 'ws';
    const urlWithoutScheme = base.replace(/^https?:\/\//, '');
    const wsUrl = `${wsScheme}://${urlWithoutScheme}/ws/users/${userId}`;

    try {
        const ws = new WebSocket(wsUrl);
        state.userWsConnection = ws;

        ws.onmessage = async (event) => {
            try {
                const data = JSON.parse(event.data);
                if (data.type === 'chat_list_updated') {
                    console.log('User WebSocket: chat_list_updated event received, reloading chats...');
                    await loadChatsFromServer(userId);
                    
                    if (typeof window.renderDrawer === 'function') {
                        window.renderDrawer();
                    }
                    
                    // If the currently selected chat is deleted (or no longer available to B), switch chats safely
                    if (state.currentChatId && !state.chats[state.currentChatId]) {
                        console.log('Currently active chat was deleted or revoked. Selecting a new active chat...');
                        const firstChatId = Object.keys(state.chats)[0] || null;
                        state.currentChatId = firstChatId;
                        if (firstChatId) {
                            connectChatWebSocket(firstChatId);
                        } else {
                            disconnectChatWebSocket();
                        }
                        if (typeof window.renderMessages === 'function') {
                            window.renderMessages();
                        }
                    }
                }
            } catch (err) {
                console.error('Error handling User WebSocket message:', err);
            }
        };

        ws.onclose = () => {
            if (state.userWsConnection === ws) {
                state.userWsConnection = null;
                // Reconnect after 3 seconds if user is still logged in
                setTimeout(() => {
                    if (state.userId === userId && !state.userWsConnection && !state.isTemporaryChat) {
                        console.log('Reconnecting User WebSocket...');
                        connectUserWebSocket(userId);
                    }
                }, 3000);
            }
        };

        ws.onerror = (err) => {
            console.error('User WebSocket error:', err);
        };
    } catch (e) {
        console.error('Failed to connect User WebSocket:', e);
    }
}
