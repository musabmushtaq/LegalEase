// Authentication module
import { state, AUTH_CACHE_KEY, DEFAULT_USERNAME, DEFAULT_USER_ID } from './config.js';
import { loginUser, registerUser } from './api.js';
import { showMessage, logError } from './utils.js';

export function loadAuthState() {
    try {
        const saved = JSON.parse(localStorage.getItem(AUTH_CACHE_KEY) || 'null');
        if (saved && saved.userId && saved.authToken) {
            state.userId = saved.userId;
            state.authToken = saved.authToken;
            state.username = saved.username || DEFAULT_USERNAME;
        }
    } catch (_) {
        state.userId = null;
        state.authToken = null;
        state.username = DEFAULT_USERNAME;
    }
}

export function saveAuthState() {
    if (state.authToken && state.userId) {
        localStorage.setItem(AUTH_CACHE_KEY, JSON.stringify({
            userId: state.userId,
            authToken: state.authToken,
            username: state.username,
        }));
    }
}

export function clearAuthState() {
    localStorage.removeItem(AUTH_CACHE_KEY);
    state.authToken = null;
    state.userId = null;
    state.username = DEFAULT_USERNAME;
}

export async function handleLogin(username, password) {
    try {
        const response = await loginUser(username, password);
        state.authToken = response.access_token;
        state.userId = response.user_id;
        state.username = username;
        saveAuthState();
        showMessage('Logged in successfully');
        return true;
    } catch (error) {
        logError('handleLogin', error);
        throw new Error('Login failed. Please check your credentials.');
    }
}

export async function handleRegister(username, email, password) {
    try {
        await registerUser(username, email, password);
        await handleLogin(username, password);
        showMessage('Account created successfully');
        return true;
    } catch (error) {
        logError('handleRegister', error);
        throw error;
    }
}

export function handleLogout() {
    clearAuthState();
    state.isTemporaryChat = true;
    showMessage('Logged out. Temporary chat mode enabled.');
}

export function toggleTemporaryMode() {
    state.isTemporaryChat = !state.isTemporaryChat;
    if (state.isTemporaryChat) {
        clearAuthState();
    }
    showMessage(state.isTemporaryChat ? 'Temporary chat mode enabled.' : 'Temporary chat mode disabled.');
}

export function isAuthenticated() {
    return !!state.authToken && !!state.userId;
}

export function ensureUserId() {
    if (!state.userId) {
        state.userId = DEFAULT_USER_ID;
    }
    return state.userId;
}
