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

export function showCustomConfirm(message) {
    return new Promise((resolve) => {
        let modal = document.getElementById('customConfirmModal');
        if (!modal) {
            modal = document.createElement('div');
            modal.id = 'customConfirmModal';
            modal.className = 'modal-overlay hidden';
            document.body.appendChild(modal);
        }
        modal.innerHTML = `
            <div class="modal-card custom-dialog-card">
                <h3 class="custom-dialog-title">Confirm Action</h3>
                <p class="custom-dialog-text">${escapeHtml(message)}</p>
                <div class="custom-dialog-actions">
                    <button class="custom-dialog-btn secondary" id="customConfirmCancel">Cancel</button>
                    <button class="custom-dialog-btn primary" id="customConfirmOk">Confirm</button>
                </div>
            </div>
        `;
        
        const isDelete = message.toLowerCase().includes('delete') || message.toLowerCase().includes('clear') || message.toLowerCase().includes('remove');
        const okBtn = modal.querySelector('#customConfirmOk');
        const cancelBtn = modal.querySelector('#customConfirmCancel');
        
        if (isDelete) {
            okBtn.classList.add('destructive');
            okBtn.textContent = 'Delete';
        }
        
        modal.classList.remove('hidden');
        okBtn.focus();
        
        const cleanup = (value) => {
            modal.classList.add('hidden');
            resolve(value);
        };
        
        okBtn.onclick = () => cleanup(true);
        cancelBtn.onclick = () => cleanup(false);
        modal.onclick = (e) => {
            if (e.target === modal) cleanup(false);
        };
    });
}

export function showCustomPrompt(message, defaultValue = '') {
    return new Promise((resolve) => {
        let modal = document.getElementById('customPromptModal');
        if (!modal) {
            modal = document.createElement('div');
            modal.id = 'customPromptModal';
            modal.className = 'modal-overlay hidden';
            document.body.appendChild(modal);
        }
        modal.innerHTML = `
            <div class="modal-card custom-dialog-card">
                <h3 class="custom-dialog-title">${escapeHtml(message)}</h3>
                <div class="custom-dialog-input-wrap">
                    <input type="text" id="customPromptInput" class="custom-dialog-input" value="${escapeHtml(defaultValue)}" placeholder="Enter name...">
                </div>
                <div class="custom-dialog-actions">
                    <button class="custom-dialog-btn secondary" id="customPromptCancel">Cancel</button>
                    <button class="custom-dialog-btn primary" id="customPromptOk">OK</button>
                </div>
            </div>
        `;
        
        const okBtn = modal.querySelector('#customPromptOk');
        const cancelBtn = modal.querySelector('#customPromptCancel');
        const input = modal.querySelector('#customPromptInput');
        
        modal.classList.remove('hidden');
        input.focus();
        input.select();
        
        const cleanup = (value) => {
            modal.classList.add('hidden');
            resolve(value);
        };
        
        okBtn.onclick = () => cleanup(input.value.trim());
        cancelBtn.onclick = () => cleanup(null);
        input.onkeydown = (e) => {
            if (e.key === 'Enter') {
                e.preventDefault();
                cleanup(input.value.trim());
            } else if (e.key === 'Escape') {
                cleanup(null);
            }
        };
        modal.onclick = (e) => {
            if (e.target === modal) cleanup(null);
        };
    });
}
