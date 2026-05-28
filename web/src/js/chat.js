// Chat management module
import { state, CHAT_CACHE_KEY } from './config.js';
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
