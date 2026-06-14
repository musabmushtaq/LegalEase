# Privacy Policy

**Effective Date**: June 14, 2026

LegalEase values your privacy. This Privacy Policy explains how we handle your data, files, and interactions across the LegalEase platform, including our mobile application, web client, backend services, and database.

---

## 1. Data Collection & Synchronization

To provide a seamless cross-platform experience (mobile and web), LegalEase synchronizes user data with a secured central database:

- **Account Credentials**: We store your email address, username, and a secure cryptographic hash of your password (using the Bcrypt algorithm).
- **Chat History & Context**: Your chat messages and dynamically generated user-profile background context are stored in our central database to maintain conversation continuity.
- **File Uploads**: When you upload legal documents for analysis, the files are securely stored in a designated, user-scoped directory on our server, and metadata is recorded in our database.

---

## 2. Audio & Voice Call Data Processing

Our Live Call feature utilizes advanced local processing pipelines to handle voice data:

- **Speech-to-Text (STT)**: When speaking during a Live Call, your voice audio is sent as a secure raw stream to our backend, where it is transcribed into text using a local GPU-accelerated Whisper model.
- **Text-to-Speech (TTS)**: AI responses are converted back to audio using a local Kokoro TTS model on the server and streamed back to your device.
- **Transient Audio**: The raw voice audio processed during a Live Call is transient; it is used only to perform speech-to-text conversion and is not persisted. The resulting text transcript is only saved to your persistent chat history if explicitly recorded.

---

## 3. Third-Party AI Integrations

To perform sophisticated legal analysis, your text messages and document extracts are sent to external AI APIs (such as Google Gemini):

- Only the text content, relevant context, and conversation history are sent to the AI API.
- All transmissions are encrypted and subject to the privacy policies of the third-party providers.

---

## 4. Security & Protection

We implement robust administrative and technical controls to safeguard your data:

- **Transit Encryption**: All client-server communications and API requests use secure protocols.
- **Password Protection**: Passwords are never stored in plaintext and are hashed with 12 rounds of Bcrypt.
- **Storage Isolation**: File uploads are partitioned using secure user-scoped folder paths on the server.

---

## 5. User Control & Deletion Rights

You have complete control over your data stored in LegalEase:

- **Manual Deletion**: You can edit or delete individual messages in your chats at any time.
- **Purge Chat History**: You can wipe all chat history from your profile at any time.
- **Account Deletion**: You can permanently delete your user account. Deleting your account will immediately and permanently purge your profile, context data, all chats you own, and all uploaded files from our database and disk.

---

## 6. Changes to This Policy

We may update this Privacy Policy as LegalEase evolves. Any changes will be published in the application and updated in this repository.

For questions or issues regarding your data privacy, please consult the project documentation or contact the maintainers.

