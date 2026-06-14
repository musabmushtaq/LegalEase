# LegalEase Database Schema Reference

**Database System**: MongoDB
**Driver Engine**: Async Motor (Python)

---

## 1. Users Collection (`users`)

Stores user account registrations, credentials, and dynamic context summaries compiled during conversations.

### Document Structure (JSON Representation)
```json
{
  "_id": ObjectId("69da98d356c7c39e39d2dc16"),
  "user_id": "user_3089ba2af7b8",
  "username": "musab",
  "email": "musabmushtaq952@gmail.com",
  "password": "$2b$12$ncNxlwj5nc/SPP2Eft5UDOgXLqoHzGp9F2Jv/6hbIAbXerZyGB42S",
  "context": "I am a real estate attorney looking for landlord-tenant templates.",
  "created_at": "2026-04-11T18:54:11.380895+00:00"
}
```

### Collection Fields
| Field Name | Type | Purpose |
| :--- | :--- | :--- |
| `_id` | `ObjectId` | Auto-generated MongoDB primary key. |
| `user_id` | `String` | Unique application-level identifier (prefixed with `user_`). |
| `username` | `String` | Unique login username handle. |
| `email` | `String` | Unique email address. |
| `password` | `String` | One-way Bcrypt hashed password. |
| `context` | `String / null` | Facts extracted about the user for personalized AI context. |
| `created_at` | `String (ISO)` | Creation timestamp. |

---

## 2. Chats Collection (`chats`)

Stores metadata for active and archived conversation threads. Individual user/assistant messages are embedded directly inside the parent chat document as an array to minimize network joins.

### Document Structure (JSON Representation)
```json
{
  "_id": ObjectId("6a0c35f352680fd21fbcb9f2"),
  "chat_id": "chat_f82cc27847b4",
  "owner_id": "user_af748175fe85",
  "title": "Landlord-Tenant Dispute Review",
  "is_pinned": false,
  "messages": [
    {
      "id": "msg_8d249f05a1ce",
      "chat_id": "chat_f82cc27847b4",
      "sender": "user",
      "content": "Please review this lease agreement clause.",
      "file_id": "file_a7e937d10b9d",
      "filename": "lease_agreement.pdf",
      "created_at": "2026-05-19T10:05:39.980116+00:00"
    },
    {
      "id": "msg_90e38bc2fa01",
      "sender": "ai",
      "content": "Analysis: The clause enforces immediate eviction without notice, which is unenforceable under regional laws...",
      "created_at": "2026-05-19T10:05:44.284062+00:00"
    }
  ],
  "created_at": "2026-05-19T10:05:39.980116+00:00",
  "updated_at": "2026-05-19T10:05:44.284062+00:00"
}
```

### Collection Fields
| Field Name | Type | Purpose |
| :--- | :--- | :--- |
| `_id` | `ObjectId` | Auto-generated MongoDB primary key. |
| `chat_id` | `String` | Unique conversation ID (prefixed with `chat_`). |
| `owner_id` | `String` | The `user_id` of the user who owns this chat room. |
| `title` | `String` | The display title of the conversation. |
| `is_pinned` | `Boolean` | True if the chat is pinned to the top of the chat drawer. |
| `messages` | `Array[Object]` | Embedded array of message turns (structure detailed below). |
| `created_at` | `String (ISO)` | Chat creation timestamp. |
| `updated_at` | `String (ISO)` | Timestamp of the last user input or model output (controls sorting chronology). |

### Embedded Message Fields (`messages` Array)
* **`id`**: Unique message ID (prefixed with `msg_`).
* **`chat_id`**: Associated chat room ID.
* **`sender`**: Identifies speaker, either `"user"` or `"ai"`.
* **`content`**: Text of the message block.
* **`file_id`**: *(Optional)* File ID reference if a document attachment was analyzed.
* **`filename`**: *(Optional)* Plain text filename of the attached document.
* **`created_at`**: Precise timestamp.

---

## 3. Files Collection (`files`)

Stores metadata pointers for document attachments. Actual PDF, DOCX, TXT, or image files reside on the local system storage.

### Document Structure (JSON Representation)
```json
{
  "_id": ObjectId("6e0c12e847c21faef5d19a2e"),
  "file_id": "file_a7e937d10b9d",
  "filename": "lease_agreement.pdf",
  "file_path": "C:\\repo\\LegalEase\\api\\uploads\\file_a7e937d10b9d_lease_agreement.pdf",
  "chat_id": "chat_f82cc27847b4",
  "uploaded_at": "2026-05-19T10:05:39.980116+00:00"
}
```

### Collection Fields
| Field Name | Type | Purpose |
| :--- | :--- | :--- |
| `_id` | `ObjectId` | Auto-generated MongoDB primary key. |
| `file_id` | `String` | Unique application-level file identifier (prefixed with `file_`). |
| `filename` | `String` | Original uploaded document name. |
| `file_path` | `String` | Absolute path on server disk containing the binary file. |
| `chat_id` | `String` | The conversation ID where the file upload occurred. |
| `uploaded_at` | `String (ISO)`| Upload timestamp. |

---

## 4. Key Integrity Relationships

1. **Owner-to-Chat**: One-to-many relationship mapping `users.user_id` to `chats.owner_id`.
2. **Chat-to-File**: One-to-many relationship mapping `chats.chat_id` to `files.chat_id`.
3. **Message-to-File**: Embedding reference from `chats.messages[n].file_id` to `files.file_id` for instant query resolution.
