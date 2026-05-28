// API communication module
import { API_BASE_URL, state, DEFAULT_USER_ID } from './config.js';
import { logError } from './utils.js';

function buildAuthHeaders(extra = {}) {
    const headers = { ...extra };
    if (state.authToken) {
        headers.Authorization = `Bearer ${state.authToken}`;
    }
    return headers;
}

export function getAuthorizedHeaders(isJson = true) {
    const headers = {};
    if (isJson) {
        headers['Content-Type'] = 'application/json';
    }
    if (state.authToken) {
        headers['Authorization'] = `Bearer ${state.authToken}`;
    }
    return headers;
}

export async function apiCall(endpoint, options = {}) {
    try {
        const base = (window.API_BASE_URL) ? window.API_BASE_URL : API_BASE_URL;
        const url = `${base}${endpoint}`;

        // Simple retry for transient network/server errors
        const maxRetries = options._retries ?? 1;
        let attempt = 0;
        while (true) {
            attempt += 1;
            const controller = new AbortController();
            const timeout = options._timeout ?? 8000;
            const timer = setTimeout(() => controller.abort(), timeout);

            try {
                const response = await fetch(url, {
                    ...options,
                    headers: {
                        ...getAuthorizedHeaders(),
                        ...(options.headers || {}),
                    },
                    signal: controller.signal,
                });
                clearTimeout(timer);

                if (!response.ok) {
                    const errorData = await response.json().catch(() => ({}));
                    const msg = errorData.detail || errorData.message || `HTTP ${response.status}`;
                    // Retry on 5xx
                    if (response.status >= 500 && attempt <= maxRetries) {
                        await new Promise(r => setTimeout(r, 300 * attempt));
                        continue;
                    }
                    throw new Error(msg);
                }

                return await response.json();
            } catch (err) {
                clearTimeout(timer);
                // AbortError or network errors
                if ((err.name === 'AbortError' || err instanceof TypeError) && attempt <= maxRetries) {
                    await new Promise(r => setTimeout(r, 300 * attempt));
                    continue;
                }
                throw err;
            }
        }
    } catch (error) {
        logError('apiCall', error);
        throw error;
    }
}

export async function checkHealth() {
    try {
        const res = await apiCall('/api/ping', { method: 'GET', _retries: 1, _timeout: 3000 });
        return !!res && (res.status === 'ok' || res.status === undefined);
    } catch {
        return false;
    }
}

export async function loginUser(username, password) {
    return apiCall('/auth/login', {
        method: 'POST',
        body: JSON.stringify({ username, password }),
    });
}

export async function registerUser(username, email, password) {
    return apiCall('/auth/register', {
        method: 'POST',
        body: JSON.stringify({ username, email, password }),
    });
}

export async function loadChats(userId) {
    return apiCall(`/users/${userId}/chats`, {
        method: 'GET',
    });
}

export async function createChat(userId, title = 'New Chat') {
    return apiCall(`/users/${userId}/chats`, {
        method: 'POST',
        body: JSON.stringify({ title }),
    });
}

export async function getChat(chatId) {
    return apiCall(`/chats/${chatId}`);
}

export async function updateChat(chatId, updates) {
    return apiCall(`/chats/${chatId}`, {
        method: 'PATCH',
        body: JSON.stringify(updates),
    });
}

export async function deleteChat(chatId) {
    return apiCall(`/chats/${chatId}`, {
        method: 'DELETE',
    });
}

/**
 * Save a user message (with optional file) to a persistent chat.
 * Returns the saved message document from the server.
 */
export async function saveUserMessage(chatId, content, file = null) {
    const messageContent = (content || '').trim() || (file ? 'Sent an attachment' : '');
    if (!messageContent) {
        throw new Error('Message cannot be empty');
    }

    if (file) {
        const formData = new FormData();
        formData.append('content', messageContent);
        formData.append('file', file);

        const base = (window.API_BASE_URL) ? window.API_BASE_URL : API_BASE_URL;
        const response = await fetch(`${base}/chats/${chatId}/messages_with_file`, {
            method: 'POST',
            headers: buildAuthHeaders(),
            body: formData,
        });
        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            throw new Error(errorData.detail || `HTTP ${response.status}`);
        }
        return response.json();
    }

    return apiCall(`/chats/${chatId}/messages`, {
        method: 'POST',
        body: JSON.stringify({
            sender: 'user',
            content: messageContent,
            user_id: state.userId || DEFAULT_USER_ID,
        }),
    });
}

/**
 * Legacy alias kept for compatibility.
 */
export async function sendMessage(chatId, content, file = null) {
    return saveUserMessage(chatId, content, file);
}

/**
 * Call /api/generate_ai to get an AI response.
 * For persistent chats passes chat_id so the server reads history from DB.
 * For temporary chats passes the full messages array inline.
 */
export async function generateAiReply(chatId, messages = null, useContext = false) {
    const body = { use_context: useContext };

    const isLocal = String(chatId).startsWith('local_');
    if (!isLocal && chatId) {
        body.chat_id = chatId;
    } else if (messages) {
        body.messages = messages.map(m => ({ sender: m.sender, content: m.content }));
        body.update_context = false;
    }

    return apiCall('/api/generate_ai', {
        method: 'POST',
        body: JSON.stringify(body),
        _timeout: 60000, // AI can take a while
        _retries: 0,
    });
}

/**
 * Save an AI message to the persistent chat.
 */
export async function saveAiMessage(chatId, content) {
    return apiCall(`/chats/${chatId}/messages`, {
        method: 'POST',
        body: JSON.stringify({
            sender: 'ai',
            content,
            user_id: state.userId || DEFAULT_USER_ID,
        }),
    });
}

/**
 * Summarize text to generate a short chat title (max ~5 words).
 */
export async function summarizeText(text) {
    try {
        const res = await apiCall('/api/summarize', {
            method: 'POST',
            body: JSON.stringify({ text }),
            _timeout: 15000,
            _retries: 0,
        });
        return res.summary || null;
    } catch {
        return null;
    }
}

export async function updateMessage(chatId, messageId, content) {
    return apiCall(`/chats/${chatId}/messages/${messageId}`, {
        method: 'PATCH',
        body: JSON.stringify({ content }),
    });
}

export async function deleteMessage(chatId, messageId) {
    return apiCall(`/chats/${chatId}/messages/${messageId}`, {
        method: 'DELETE',
    });
}

export async function shareChat(chatId, enabled = true) {
    return apiCall(`/chats/${chatId}/share`, {
        method: 'POST',
        body: JSON.stringify({ enabled }),
    });
}

export async function searchChats(userId, query) {
    return apiCall(`/users/${userId}/search?query=${encodeURIComponent(query)}`);
}

export async function getSharedChat(shareToken) {
    return apiCall(`/share/${shareToken}`);
}

/**
 * Download a file by fileId from the server.
 * Returns a Blob on success, null on failure.
 */
export async function downloadFile(fileId) {
    try {
        const base = (window.API_BASE_URL) ? window.API_BASE_URL : API_BASE_URL;
        const url = `${base}/api/files/${fileId}`;
        const response = await fetch(url, {
            method: 'GET',
            headers: buildAuthHeaders(),
        });
        if (!response.ok) return null;
        return await response.blob();
    } catch {
        return null;
    }
}

/**
 * Delete a user's personal context.
 */
export async function clearPersonalContext(userId) {
    return apiCall(`/users/${userId}/context`, {
        method: 'PATCH',
        body: JSON.stringify({ context: '' }),
    });
}

/**
 * Clear all chat history for a user.
 */
export async function clearAllHistory(userId) {
    return apiCall(`/users/${userId}/chats`, {
        method: 'DELETE',
    });
}

/**
 * Permanently delete a user account.
 */
export async function deleteUserAccount(userId) {
    return apiCall(`/users/${userId}`, {
        method: 'DELETE',
    });
}
