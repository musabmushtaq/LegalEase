# LegalEase Database Schema

**Database**: MongoDB

# Users

Stores user account information, context, and authentication.

```json
{
  "_id": ObjectId("69da98d356c7c39e39d2dc16"),
  "user_id": "user_3089ba2af7b8",
  "email": "musabmushtaq952@gmail.com",
  "username": "musab",
  "password": "$2b$12$ncNxlwj5nc/SPP2Eft5UDOgXLqoHzGp9F2Jv/6hbIAbXerZyGB42S",
  "context": "I am a real estate attorney looking for landlord-tenant templates.",
  "created_at": "2026-04-11T18:54:11.380895+00:00"
}
```

# Chats

Stores individual chat conversations with messages embedded.

```json
{
  "_id": ObjectId("6a0c35f352680fd21fbcb9f2"),
  "chat_id": "chat_f82cc27847b4",
  "owner_id": "user_af748175fe85",
  "collaborators": ["user_b28192cd44f1"],
  "title": "Contract Review",
  "is_pinned": false,
  "is_shared": false,
  "messages": [
    {
      "id": "msg_8d249f05a1ce",
      "chat_id": "chat_f82cc27847b4",
      "sender": "user",
      "content": "Please review this NDA clause",
      "file_id": "file_a7e937d10b9d",
      "filename": "contract.pdf",
      "created_at": "2026-05-19T10:05:39.980116+00:00"
    },
    {
      "id": "msg_90e38bc2fa01",
      "sender": "ai",
      "content": "I've analyzed the NDA clause. Here are my findings...",
      "created_at": "2026-05-19T10:06:00.284062+00:00"
    }
  ],
  "created_at": "2026-05-19T10:05:39.980116+00:00",
  "updated_at": "2026-05-19T10:06:00.284062+00:00"
}
```

# Files

Stores metadata for uploaded documents (actual files stored locally under the uploads directory).

```json
{
  "_id": ObjectId("6e0c12e847c21faef5d19a2e"),
  "file_id": "file_a7e937d10b9d",
  "filename": "contract.pdf",
  "file_path": "C:\\repo\\LegalEase\\api\\uploads\\file_a7e937d10b9d_contract.pdf",
  "chat_id": "chat_f82cc27847b4",
  "uploaded_at": "2026-05-19T10:05:39.980116+00:00"
}
```

# Relationships

```
users (1 owner) ──────> (many) chats
                           └───> messages Array (Embedded)
                                     └───> references files via file_id/filename

chats (1 chat, many messages)
  ├── owner_id links to user
  ├── collaborators links to array of users
  ├── contains messages array
  └── messages reference files directly via file_id/filename if attachments exist

files (1 file, many chats potentially)
  └── stored at file_path on disk
```
