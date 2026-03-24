# LegalEase Database Schema

**Database**: MongoDB

# Users

Stores user account information and authentication.

```json
{
  "_id": ObjectId(),
  "userId": "user_123",
  "email": "lawyer@example.com",
  "username": "john_doe",
  "passwordHash": "bcrypt_encrypted_hash",
}
```

# Chats

Stores individual chat conversations with messages embedded.

```json
{
  "_id": ObjectId(),
  "chatId": "chat_abc123",
  "ownerId": "user_123",
  "title": "Contract Review - NDA Clause",
  "isPinned": false,
  "isShared": true,
  "shareToken": "abc123xyz_hardToGuess",
  "shareLink": "https://legalease.app/share/abc123xyz_hardToGuess",
  "messages": [
    {
      "messageId": "msg_001",
      "userId": "user_123",
      "role": "user",
      "content": "Please review this NDA clause",
      "attachments": [
        {
          "fileId": "file_xyz",
          "filename": "contract.pdf"
        }
      ],
      "createdAt": ISODate("2026-03-22T10:05:00Z")
    },
    {
      "messageId": "msg_002",
      "userId": null,
      "role": "assistant",
      "content": "I've analyzed the NDA clause. Here are my findings...",
      "createdAt": ISODate("2026-03-22T10:06:00Z")
    }
    ],
  "createdAt": ISODate("2026-03-22T10:00:00Z"),
  "updatedAt": ISODate("2026-03-22T10:06:00Z")
}
```

# Files

Stores metadata for uploaded documents (actual files stored locally at `C:\legalEaseDB`).

```json
{
  "_id": ObjectId(),
  "fileId": "file_xyz",
  "userId": "user_123",
  "filepath": "C:\\legalEaseDB\\user_123\\contract.pdf",
  "uploadedAt": ISODate("2026-03-22T10:00:00Z")
}
```

# Relationships

```
users (1 owner) ──────> (many) chats

chats (1 chat, many messages)
  ├── ownerId links to user
  ├── contains messages array
  ├── shareToken allows public guest access
  └── references files via fileId in attachments

files (1 file, many chats potentially)
  └── stored at filepath in C:\legalEaseDB
```
