// Utility functions
export function escapeHtml(text) {
    if (text == null) return '';
    const value = String(text);
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;',
    };
    return value.replace(/[&<>"']/g, m => map[m]);
}

export function formatDate(dateString) {
    const date = new Date(dateString);
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    if (date.toDateString() === today.toDateString()) {
        return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
    } else if (date.toDateString() === yesterday.toDateString()) {
        return 'Yesterday';
    } else {
        return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    }
}

export function showMessage(message, duration = 3000) {
    const banner = document.createElement('div');
    banner.className = 'notification-banner';
    banner.textContent = message;
    document.body.appendChild(banner);
    setTimeout(() => {
        banner.classList.add('show');
    }, 10);
    setTimeout(() => {
        banner.classList.remove('show');
        setTimeout(() => banner.remove(), 300);
    }, duration);
}

export function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

export function logError(context, error) {
    console.error(`[${context}]`, error);
}

export function makeId(prefix) {
    return `${prefix}_${Math.random().toString(36).substr(2, 9)}`;
}
