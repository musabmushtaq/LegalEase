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
                        ...(options.headers || {})
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
        const res = await apiCall('/health', { method: 'GET', _retries: 1, _timeout: 3000 });
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
        method: 'GET'
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

export async function sendMessage(chatId, content, file = null) {
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
