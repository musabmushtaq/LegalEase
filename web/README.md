# LegalEase Web Interface (Vite SPA)

**Status**: Production-Ready | Modern Single Page Application (SPA)

This directory contains the web application client for LegalEase. Built with modular Vanilla JavaScript (ES6) and bundled using Vite, it provides a responsive legal assistant console matching the Flutter mobile app.

---

## 1. Core Capabilities & Feature Status

| Feature | Status | Implementation Details |
| :--- | :--- | :--- |
| **State Management** |  Complete | Centralized, reactive state store in `src/app.js` |
| **User Authentication** |  Complete | Secure login and signup via JWT session tokens |
| **Document Uploads** |  Complete | Multipart attachment streaming for legal analysis |
| **Chat Q&A Search** |  Complete | Dynamic RESTful search across message contents |
| **auto-Scroll Engine** |  Complete | requestAnimationFrame deceleration scroll preventing overlays jumpiness |

---

## 2. Directory Structure

```
web/
+--- index.html            # Main HTML document template
+--- package.json          # Node dependency configuration & Vite scripts
+--- vite.config.js        # Vite compiler and development configuration
+--- run.bat               # Automated dependency checker and dev server launcher
+--- src/
    +--- main.js           # SPA bootstrapping & window-level event listeners
    +--- app.js            # Global state store & action dispatcher
    +--- styles.css        # Premium HSL dark-mode styling & breakpoints
    +--- js/
        +--- api.js        # HTTP client fetch wrapper with implicit JWT header
        +--- auth.js       # Login, registration, and session token controller
        +--- chat.js       # Chat action handlers and mutations
        +--- config.js     # Default settings & environment configuration
        +--- ui.js         # DOM renderer & animations
        +--- utils.js      # Text formatting, escaping, and validation functions
```

---

## 3. Technology Stack & Developer Tools

* **Core**: HTML5, CSS3, Vanilla ES6 JavaScript.
* **Build System**: Vite 5+ for local development HMR (Hot Module Replacement) and optimized static production asset bundling.
* **Dev Server Port**: Configured to run on port `8080` by default.

---

## 4. Setup & Local Development

### Prerequisites
* **Node.js**: Version 18+ and `npm` installed.
* **Backend API**: The FastAPI server running (typically on `http://localhost:8000`).

### Running via run.bat (Recommended)
Double-click `run.bat` in the `web/` directory. The batch script will automatically check if Node.js is installed, install dependencies if `node_modules/` is missing, and launch the Vite development server.

### Manual Launch
1. Navigate to the web subdirectory:
   ```bash
   cd web
   ```
2. Install npm dependencies:
   ```bash
   npm install
   ```
3. Run the development server:
   ```bash
   npm run dev
   ```
4. Open your web browser to: `http://localhost:8080`

---

## 5. Architectural Flow Chart

```
             +------------------------------------------+
             |                USER LAYER                |
             |           (Browser DOM / UI)             |
             +--------------------+---------------------+
                                  | Triggers Events
                                  v
             +------------------------------------------+
             |            app.js (Global State)         |
             +------+-----------------------------------+
                    |
      HTTP Requests | (api.js REST client)
                    v
             +------------------------------------------+
             |              FastAPI Backend             |
             +------------------------------------------+
```

---

## 6. CSS & Responsive Typography Guidelines

* **Harmonious Dark Theme**: Uses HSL color values matching the mobile design:
  - Background: `#131313`
  - Accent Color: `#FCE566`
  - Cards / Messages: Dark gray `#222` / Accent translucent bounds
* **Mobile Breakpoint (<1023px)**: Collapses the conversation drawer into a slide-out hamburger side menu for clear mobile-first console views.
* **Layout Sizing**: Enforces touch-friendly heights (`60px` inputs, `18px` text bubble bounds) with deceleration animations.
