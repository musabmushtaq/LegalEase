// Configuration and constants
const DEFAULT_API_BASE_URL = 'http://127.0.0.1:8002';
const queryParams = new URLSearchParams(window.location.search);
// Precedence: localStorage override -> query param -> default
const storedApiBase = (() => {
    try {
        return localStorage.getItem('legalease_api_base');
    } catch {
        return null;
    }
})();
const API_BASE_URL = storedApiBase || queryParams.get('api_base_url') || queryParams.get('apiBaseUrl') || DEFAULT_API_BASE_URL;
const DEFAULT_USER_ID = 'user1';
const DEFAULT_USERNAME = 'Guest';
const CHAT_CACHE_KEY = 'legaleaseWebChatCache';
const AUTH_CACHE_KEY = 'legaleaseWebAuth';
const CONNECTIVITY_CHECK_INTERVAL = 20000; // 20 seconds
const MAX_MESSAGE_HISTORY = 1000; // Pagination limit

// Expose the resolved API base URL for debugging and page scripts
// Expose the resolved API base URL for runtime usage and debugging
window.API_BASE_URL = API_BASE_URL;

// Shared application state
const state = {
    chats: {},
    messages: {},
    currentChatId: null,
    authToken: null,
    userId: null,
    username: DEFAULT_USERNAME,
    isConnected: true,
    isTemporaryChat: false,
    searchQuery: '',
    searchResults: null,
    attachment: null,
    authMode: 'login',
    sharedView: false,
    useContext: false,       // persona/context mode toggle
    isAiThinking: false,     // true while waiting for AI response
};

export {
    API_BASE_URL,
    DEFAULT_USER_ID,
    DEFAULT_USERNAME,
    CHAT_CACHE_KEY,
    AUTH_CACHE_KEY,
    CONNECTIVITY_CHECK_INTERVAL,
    state,
};
