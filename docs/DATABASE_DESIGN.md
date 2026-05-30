# LegalEase Database Design & Schema

**Version**: 1.0  
**Database**: MongoDB (NoSQL)  
**Engine**: Community Server 5.0+  
**Last Updated**: May 20, 2026

---

## Table of Contents

1. [Design Philosophy](#design-philosophy)
2. [Collections Overview](#collections-overview)
3. [Users Collection](#users-collection)
4. [Chats Collection](#chats-collection)
5. [Files Collection](#files-collection)
6. [Data Relationships](#data-relationships)
7. [Indexes & Performance](#indexes--performance)
8. [Aggregation Examples](#aggregation-examples)
9. [Backup & Recovery](#backup--recovery)
10. [Scaling Considerations](#scaling-considerations)

---

## Design Philosophy

### Key Principles

1. **Document-Oriented**: Each entity is a self-contained document
2. **Flexibility**: Schema allows evolution without migrations
3. **Denormalization**: Some data duplication for query efficiency
4. **Embedded vs Referenced**: Messages embedded in chats for atomic operations
5. **Indexing**: Strategic indexes for common query patterns
6. **Scalability**: Designed for horizontal scaling via sharding

### Design Decisions

**Why Embedded Messages**:

- All messages for a chat are queries together (atomic)
- Eliminates need for JOIN operations
- Keeps related data together
- Transactions simpler

**Why Referenced Files**:

- Files may be referenced in multiple chats
- Separate storage for large files
- Enables file sharing across conversations
- Easier cleanup/archival

---

## Collections Overview

| Collection | Documents | Primary Use       | Size Growth                     |
| ---------- | --------- | ----------------- | ------------------------------- |
| users      | ~100K     | User accounts     | Linear with users               |
| chats      | ~500K     | Conversations     | Linear with users \* chats/user |
| files      | ~200K     | Document metadata | Linear with uploads             |

---

## Users Collection

### Document Structure

```json
{
  "_id": ObjectId("507f1f77bcf86cd799439011"),
  "userId": "user_123",
  "email": "lawyer@example.com",
  "username": "john_doe",
  "passwordHash": "$2b$12$...", // bcrypt hash
  "context": "I am a corporate attorney specializing in mergers and acquisitions",
  "preferences": {
    "theme": "dark",
    "notifications": true,
    "emailAlerts": false
  },
  "subscription": {
    "tier": "premium",
    "startDate": ISODate("2026-05-01T00:00:00Z"),
    "endDate": ISODate("2026-06-01T00:00:00Z")
  },
  "stats": {
    "totalChats": 45,
    "totalMessages": 1250,
    "totalFiles": 87,
    "lastActive": ISODate("2026-05-20T10:00:00Z")
  },
  "createdAt": ISODate("2026-05-01T08:30:00Z"),
  "updatedAt": ISODate("2026-05-20T10:00:00Z")
}
```

### Field Definitions

| Field        | Type     | Description               | Constraints        |
| ------------ | -------- | ------------------------- | ------------------ |
| \_id         | ObjectId | MongoDB auto-generated ID | Unique             |
| userId       | String   | Application-level user ID | Unique, indexed    |
| email        | String   | User email address        | Unique, indexed    |
| username     | String   | Display name              | Unique, 3-50 chars |
| passwordHash | String   | Bcrypt hashed password    | Never plaintext    |
| context      | String   | Professional context      | 0-1000 chars       |
| preferences  | Object   | User settings             | Optional           |
| subscription | Object   | Subscription info         | Optional           |
| stats        | Object   | User statistics           | Auto-updated       |
| createdAt    | Date     | Account creation time     | ISO 8601           |
| updatedAt    | Date     | Last profile update       | ISO 8601           |

### Indexes

```javascript
// Unique user identifier
db.users.createIndex({ userId: 1 }, { unique: true });

// Email for authentication
db.users.createIndex({ email: 1 }, { unique: true });

// Username for searches
db.users.createIndex({ username: 1 }, { unique: true });

// Account creation (for analytics)
db.users.createIndex({ createdAt: -1 });

// Last active for activity tracking
db.users.createIndex({ "stats.lastActive": -1 });
```

### Validation Schema (Optional)

```javascript
db.runCommand({
  collMod: "users",
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["userId", "email", "username", "passwordHash"],
      properties: {
        userId: { bsonType: "string", pattern: "^user_[a-f0-9]{24}$" },
        email: { bsonType: "string", pattern: "^[^@]+@[^@]+\\.[^@]+$" },
        username: { bsonType: "string", minLength: 3, maxLength: 50 },
        passwordHash: { bsonType: "string" },
        context: { bsonType: "string", maxLength: 1000 },
      },
    },
  },
});
```

---

## Chats Collection

### Document Structure

```json
{
  "_id": ObjectId("507f1f77bcf86cd799439012"),
  "chatId": "chat_abc123xyz789",
  "ownerId": "user_123",
  "title": "Contract Review - NDA Clause Analysis",
  "description": "Analyzing specific clauses in our service NDA",
  "isPinned": true,
  "isArchived": false,
  "tags": ["contract-review", "nda", "urgent"],
  "messages": [
    {
      "messageId": "msg_001",
      "userId": "user_123",
      "role": "user",
      "content": "Please review the non-compete clause in section 3.2",
      "attachments": [
        {
          "fileId": "file_xyz123",
          "filename": "service_nda.pdf",
          "fileType": "pdf",
          "uploadedAt": ISODate("2026-05-20T10:00:00Z")
        }
      ],
      "createdAt": ISODate("2026-05-20T10:05:00Z"),
      "editedAt": null
    },
    {
      "messageId": "msg_002",
      "userId": null,
      "role": "assistant",
      "content": "I've reviewed the non-compete clause. Here are my observations:\n\n**Key Points:**\n1. Duration: 2 years post-termination...",
      "attachments": [],
      "createdAt": ISODate("2026-05-20T10:06:00Z")
    }
  ],
  "metadata": {
    "messageCount": 2,
    "fileCount": 1,
    "readCount": 1,
    "shareCount": 0
  },
  "createdAt": ISODate("2026-05-20T10:00:00Z"),
  "updatedAt": ISODate("2026-05-20T10:06:00Z"),
  "archivedAt": null
}
```

### Field Definitions

| Field       | Type     | Description           | Constraints           |
| ----------- | -------- | --------------------- | --------------------- |
| \_id        | ObjectId | MongoDB ID            | Unique                |
| chatId      | String   | Application chat ID   | Unique, indexed       |
| ownerId     | String   | User who created chat | Indexed               |
| title       | String   | Chat title            | 1-200 chars           |
| description | String   | Chat description      | Optional, 0-500 chars |
| isPinned    | Boolean  | Pinned status         | Default: false        |
| isArchived  | Boolean  | Archive status        | Default: false        |
| tags        | Array    | Search tags           | Optional              |
| messages    | Array    | Embedded messages     | Auto-managed          |
| metadata    | Object   | Statistics            | Auto-updated          |
| createdAt   | Date     | Creation timestamp    | ISO 8601              |
| updatedAt   | Date     | Last update timestamp | ISO 8601              |
| archivedAt  | Date     | Archive timestamp     | Optional              |

### Message Sub-document Structure

```json
{
  "messageId": "msg_001",
  "userId": "user_123",
  "role": "user" | "assistant",
  "content": "Message text",
  "attachments": [
    {
      "fileId": "file_xyz123",
      "filename": "document.pdf",
      "fileType": "pdf",
      "uploadedAt": ISODate("2026-05-20T10:00:00Z")
    }
  ],
  "createdAt": ISODate("2026-05-20T10:05:00Z"),
  "editedAt": null
}
```

### Indexes

```javascript
// Primary chat lookup
db.chats.createIndex({ chatId: 1 }, { unique: true });

// User's chat history (most recent first)
db.chats.createIndex({ ownerId: 1, createdAt: -1 });

// User's pinned chats
db.chats.createIndex({ ownerId: 1, isPinned: 1 });

// Archive queries
db.chats.createIndex({ ownerId: 1, isArchived: 1 });

// Tag-based search
db.chats.createIndex({ tags: 1 });
```

---

## Files Collection

### Document Structure

```json
{
  "_id": ObjectId("507f1f77bcf86cd799439013"),
  "fileId": "file_xyz123",
  "userId": "user_123",
  "filename": "service_nda.pdf",
  "originalFilename": "NDA_FINAL.pdf",
  "filepath": "C:\\legalEaseDB\\user_123\\service_nda.pdf",
  "mimeType": "application/pdf",
  "size": 256000,
  "encoding": "utf-8",
  "metadata": {
    "pages": 8,
    "extractedText": "Document content extracted...",
    "language": "en",
    "hasImages": true,
    "hasForm": false
  },
  "references": {
    "chatIds": ["chat_abc123xyz789", "chat_def456uij012"],
    "messageIds": ["msg_001", "msg_003"]
  },
  "status": "active",
  "uploadedAt": ISODate("2026-05-20T10:00:00Z"),
  "scannedAt": ISODate("2026-05-20T10:02:00Z"),
  "expiresAt": null
}
```

### Field Definitions

| Field            | Type     | Description          | Constraints                     |
| ---------------- | -------- | -------------------- | ------------------------------- |
| \_id             | ObjectId | MongoDB ID           | Unique                          |
| fileId           | String   | Application file ID  | Unique, indexed                 |
| userId           | String   | Uploader user ID     | Indexed                         |
| filename         | String   | Stored filename      | System-generated                |
| originalFilename | String   | Original filename    | User-provided                   |
| filepath         | String   | Full filesystem path | Windows/Linux path              |
| mimeType         | String   | Content type         | e.g., "application/pdf"         |
| size             | Number   | File size in bytes   | <= 50MB                         |
| metadata         | Object   | Extracted metadata   | Auto-populated                  |
| references       | Object   | Chat/message links   | Auto-updated                    |
| status           | String   | File status          | "active", "archived", "deleted" |
| uploadedAt       | Date     | Upload timestamp     | ISO 8601                        |
| expiresAt        | Date     | Expiration date      | Optional for temp files         |

### Supported File Types

| Type | MIME Type                                                               | Extension   | Max Size |
| ---- | ----------------------------------------------------------------------- | ----------- | -------- |
| PDF  | application/pdf                                                         | .pdf        | 50MB     |
| Word | application/vnd.openxmlformats-officedocument.wordprocessingml.document | .docx       | 50MB     |
| Text | text/plain                                                              | .txt        | 10MB     |
| PNG  | image/png                                                               | .png        | 20MB     |
| JPEG | image/jpeg                                                              | .jpg, .jpeg | 20MB     |

### Indexes

```javascript
// Primary file lookup
db.files.createIndex({ fileId: 1 }, { unique: true });

// User's file history
db.files.createIndex({ userId: 1, uploadedAt: -1 });

// Status filtering
db.files.createIndex({ userId: 1, status: 1 });

// Cleanup - expired files
db.files.createIndex({ expiresAt: 1 });
```

---

## Data Relationships

### Entity-Relationship Diagram

```
┌─────────────────────┐
│      USERS          │
├─────────────────────┤
│ userId (PK)         │
│ email               │
│ username            │
│ passwordHash        │
│ context             │
│ preferences         │
│ stats               │
└──────────┬──────────┘
           │ 1
           │
           │ (1 owner)
           │
           │ M
    ┌──────▼──────────┐
    │      CHATS      │
    ├─────────────────┤
    │ chatId (PK)     │
    │ ownerId (FK)    │
    │ title           │
    │ messages[...]   │
    │ metadata        │
    └──────┬──────────┘
           │
           │ (contains)
           │ M
    ┌──────▼──────────────┐
    │    MESSAGES         │
    │  (embedded array)   │
    ├─────────────────────┤
    │ messageId           │
    │ userId              │
    │ role (user|asst)    │
    │ content             │
    │ attachments[...]    │
    └──────┬──────────────┘
           │
           │ M
           │
    ┌──────▼───────────┐
    │     FILES        │
    ├──────────────────┤
    │ fileId (PK)      │
    │ userId (FK)      │
    │ filename         │
    │ filepath         │
    │ mimeType         │
    │ size             │
    │ references[]     │
    └──────────────────┘
```

### Relationship Types

**1-to-Many (Users → Chats)**

```javascript
// Find all chats for a user
db.chats.find({ ownerId: "user_123" });

// Add new chat reference to user stats
db.users.updateOne({ userId: "user_123" }, { $inc: { "stats.totalChats": 1 } });
```

**1-to-Many (Chats → Messages)**

```javascript
// Messages are embedded in chats
// Find chat with all messages
db.chats.findOne({ chatId: "chat_123" })

// Add message to chat
db.chats.updateOne(
  { chatId: "chat_123" },
  {
    $push: { messages: { messageId: "msg_new", ... } },
    $inc: { "metadata.messageCount": 1 }
  }
)
```

**Many-to-Many (Files ← References → Chats)**

```javascript
// Find all chats referencing a file
db.chats.find({ "messages.attachments.fileId": "file_xyz123" });

// Update file references when attachment added
db.files.updateOne(
  { fileId: "file_xyz123" },
  {
    $addToSet: { "references.chatIds": "chat_123" },
    $addToSet: { "references.messageIds": "msg_001" },
  },
);
```

---

## Indexes & Performance

### Index Strategy

**Principle**: Create indexes for fields that appear in WHERE clauses of common queries.

### Index Definitions

#### Users Collection Indexes

```javascript
// 1. User lookup (most critical)
db.users.createIndex({ userId: 1 }, { unique: true });
// Used by: GET /users/{user_id}

// 2. Email authentication
db.users.createIndex({ email: 1 }, { unique: true });
// Used by: Login, registration validation

// 3. Username search
db.users.createIndex({ username: 1 }, { unique: true });
// Used by: User search, profile lookup

// 4. Activity tracking
db.users.createIndex({ "stats.lastActive": -1 });
// Used by: Analytics, user activity reports
```

#### Chats Collection Indexes

```javascript
// 1. Chat lookup (critical)
db.chats.createIndex({ chatId: 1 }, { unique: true });

// 2. User's chat history (very common)
db.chats.createIndex({ ownerId: 1, createdAt: -1 });
// Used by: GET /users/{user_id}/chats

// 3. Pinned chats filter
db.chats.createIndex({ ownerId: 1, isPinned: 1 });
// Used by: Filter pinned chats

// 4. Archive queries
db.chats.createIndex({ ownerId: 1, isArchived: 1 });
// Used by: Filter archived chats

// 5. Tag-based search
db.chats.createIndex({ tags: 1 });
// Used by: Search by tags
```

#### Files Collection Indexes

```javascript
// 1. File lookup (critical)
db.files.createIndex({ fileId: 1 }, { unique: true });

// 2. User's file history
db.files.createIndex({ userId: 1, uploadedAt: -1 });
// Used by: List user files

// 3. File status queries
db.files.createIndex({ userId: 1, status: 1 });
// Used by: Filter active/archived files

// 4. Cleanup queries
db.files.createIndex({ expiresAt: 1 }, { sparse: true });
// Used by: Find expired files for deletion
```

### Index Analysis

Check index performance:

```javascript
// Analyze query execution plan
db.chats.find({ ownerId: "user_123" }).explain("executionStats");

// List all indexes
db.chats.getIndexes();

// Index statistics
db.chats.aggregate([{ $indexStats: {} }]);
```

---

## Aggregation Examples

### Example 1: User Activity Dashboard

```javascript
// Get stats for a user
db.chats.aggregate([
  {
    $match: { ownerId: "user_123" },
  },
  {
    $group: {
      _id: "$ownerId",
      totalChats: { $sum: 1 },
      totalMessages: { $sum: { $size: "$messages" } },
      totalFiles: { $sum: { $size: "$messages.attachments" } },
      lastUpdated: { $max: "$updatedAt" },
    },
  },
]);
```

### Example 2: Most Active Chats

```javascript
// Find top 10 most active chats
db.chats.aggregate([
  {
    $addFields: {
      messageCount: { $size: "$messages" },
    },
  },
  {
    $sort: { messageCount: -1 },
  },
  {
    $limit: 10,
  },
  {
    $project: {
      chatId: 1,
      title: 1,
      messageCount: 1,
      updatedAt: 1,
    },
  },
]);
```

### Example 3: File Upload Trends

```javascript
// Files uploaded per day (last 30 days)
db.files.aggregate([
  {
    $match: {
      uploadedAt: {
        $gte: new Date(new Date().setDate(new Date().getDate() - 30)),
      },
    },
  },
  {
    $group: {
      _id: {
        $dateToString: { format: "%Y-%m-%d", date: "$uploadedAt" },
      },
      count: { $sum: 1 },
      totalSize: { $sum: "$size" },
    },
  },
  {
    $sort: { _id: -1 },
  },
]);
```

### Example 4: User Engagement Metrics

```javascript
// Users by number of chats and engagement
db.users.aggregate([
  {
    $lookup: {
      from: "chats",
      localField: "userId",
      foreignField: "ownerId",
      as: "userChats",
    },
  },
  {
    $project: {
      userId: 1,
      username: 1,
      email: 1,
      chatCount: { $size: "$userChats" },
      totalMessages: {
        $sum: {
          $map: {
            input: "$userChats",
            as: "chat",
            in: { $size: "$$chat.messages" },
          },
        },
      },
      createdAt: 1,
    },
  },
  {
    $match: { chatCount: { $gt: 0 } },
  },
  {
    $sort: { totalMessages: -1 },
  },
]);
```

---

## Backup & Recovery

### Backup Strategy

**Daily Backups**:

```bash
# Export all collections
mongodump --db legalease --out backup_$(date +%Y%m%d)

# Export specific collection
mongodump --db legalease --collection chats --out backup_chats_$(date +%Y%m%d)
```

**Cloud Backup** (MongoDB Atlas):

- Automatic daily snapshots
- Point-in-time recovery
- Geo-redundant storage

### Recovery Procedures

**Restore from backup**:

```bash
# Restore entire database
mongorestore --db legalease backup_20260520/legalease

# Restore specific collection
mongorestore --db legalease --collection chats backup_20260520/legalease/chats.bson
```

**Point-in-time recovery** (Atlas):

1. Go to Backup → Snapshots
2. Select desired timestamp
3. Click "Restore"
4. Choose restore method (new cluster or existing)

---

## Scaling Considerations

### Horizontal Scaling (Sharding)

**When to shard**: Database exceeds 50GB or throughput > 10K ops/sec

**Shard key recommendation**: `userId` (ensures even distribution)

```javascript
// Enable sharding on database
sh.enableSharding("legalease");

// Shard chats collection by userId
sh.shardCollection("legalease.chats", { ownerId: 1 });

// Shard files collection by userId
sh.shardCollection("legalease.files", { userId: 1 });
```

### Vertical Scaling

**Upgrade server capacity**:

- More RAM (cache more data)
- Faster storage (NVMe SSDs)
- More CPU cores (parallel processing)

### Replication

**Replica set** (3 nodes):

```javascript
// Primary node handles writes
// Secondary nodes replicate data
// Read replicas reduce load on primary

// Configure read preference
db.getMongo().setReadPref("secondaryPreferred");
```

---

## Maintenance Tasks

### Regular Maintenance

```javascript
// Rebuild indexes (monthly)
db.chats.reIndex();

// Check database stats
db.stats();

// Collection statistics
db.chats.stats();

// Disk usage
db.chats.storageSize();
```

### Data Cleanup

```javascript
// Remove archived chats older than 90 days
db.chats.deleteMany({
  isArchived: true,
  updatedAt: { $lt: new Date(new Date().setDate(new Date().getDate() - 90)) },
});

// Remove expired files
db.files.deleteMany({
  expiresAt: { $lt: new Date() },
});
```

---

## Security Best Practices

1. **User Authentication**:
   - Always hash passwords with bcrypt
   - Use unique constraints on email/username
   - Validate input before storage

2. **Data Access**:
   - Implement role-based access control (RBAC)
   - Users can only access their own data
   - API validation required

3. **Database Security**:
   - Use MongoDB authentication (username/password)
   - Network isolation (IP whitelisting)
   - Enable encryption at rest
   - Encrypt backups

4. **Audit Logging**:
   - Track who accessed what data
   - Log all modifications
   - Retention: 1 year minimum

---

## Migration Guide

### Adding New Field to Users

```javascript
// Add new field to all users
db.users.updateMany({}, { $set: { newField: defaultValue } });

// Add new index
db.users.createIndex({ newField: 1 });
```

### Restructuring Documents

```javascript
// Rename field (e.g., passwordHash → password_hash)
db.users.updateMany({}, [{ $rename: { passwordHash: "password_hash" } }]);

// Add nested field
db.chats.updateMany({}, { $set: { "metadata.version": 1 } });
```
