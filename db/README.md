# LegalEase Database Setup & Management

**Status**: Production Ready | MongoDB | Fully Configured 
**Database**: MongoDB (NoSQL) 
**Last Updated**: June 14, 2026

This guide walks you through setting up, initializing, and managing the MongoDB database for LegalEase.

---

## Prerequisites

- **MongoDB Community Server** (version 5.0+) running on port `27017`
- **Python 3.11+** (for running the automated initialization script)
- **MongoDB Compass** (Optional: graphical client for database exploration)

### Requirements Checklist

- [ ] MongoDB Community Server installed and running
- [ ] Python 3.11+ installed
- [ ] 500 MB free disk space minimum
- [ ] Port `27017` available

---

## Installation

### Windows

1. Download the installer from [mongodb.com/try/download/community](https://www.mongodb.com/try/download/community).
2. Run the installer and choose **"Install MongoDB as a Service"** to ensure it starts automatically on boot.
3. Verify the service is running:
   ```powershell
   Get-Service MongoDB
   ```

### macOS

1. Install via Homebrew:
   ```bash
   brew tap mongodb/brew
   brew install mongodb-community
   brew services start mongodb-community
   ```

### Linux (Ubuntu/Debian)

1. Install package updates and MongoDB:
   ```bash
   sudo apt-get install -y mongodb-org
   sudo systemctl start mongod
   sudo systemctl enable mongod
   ```

---

## Database Initialization

### 1. Start MongoDB Service

- **Windows**: `net start MongoDB`
- **macOS**: `brew services start mongodb-community`
- **Linux**: `sudo systemctl start mongod`

### 2. Run Automated Initialization Script

Navigate to the `db/` folder in a terminal, install drivers, and run `init_db.py` to create the database schema structures and indexes:

```bash
cd db
python -m venv .venv
# Activate venv:
# Windows: .venv\Scripts\activate
# macOS/Linux: source .venv/bin/activate

pip install -r requirements.txt
python init_db.py
```

**Expected output**:
```
Connecting to MongoDB at mongodb://localhost:27017...
Pass Connected to legalease

 Creating indexes...
  Pass users indexes created
  Pass chats indexes created
  Pass files indexes created

 Database initialized successfully!
```

---

### Manual Setup (Alternative CLI Instructions)

If you prefer to configure the collections manually via `mongosh`, execute the following queries:

#### 1. Create Database and Collections
```javascript
// Open mongosh
mongosh

// Switch to legalease database
use legalease

// Create users collection with schema validation
db.createCollection("users", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["user_id", "email", "password"],
      properties: {
        _id: { bsonType: "objectId" },
        user_id: { bsonType: "string" },
        email: { bsonType: "string" },
        username: { bsonType: "string" },
        password: { bsonType: "string" },
        context: { bsonType: "string" },
        created_at: { bsonType: "string" }
      }
    }
  }
})

// Create chats collection
db.createCollection("chats")

// Create files collection
db.createCollection("files")
```

#### 2. Create Indexes
```javascript
use legalease

// Users indexes
db.users.createIndex({ "user_id": 1 }, { unique: true })
db.users.createIndex({ "email": 1 }, { unique: true })
db.users.createIndex({ "username": 1 }, { unique: true })

// Chats indexes
db.chats.createIndex({ "chat_id": 1 }, { unique: true })
db.chats.createIndex({ "owner_id": 1, "updated_at": -1 })

// Files indexes
db.files.createIndex({ "file_id": 1 }, { unique: true })
db.files.createIndex({ "chat_id": 1 })
```

---

## File Storage Setup

Create a local storage directory on your server disk where uploaded legal files will be saved:

- **Windows**: Create folder `C:\repo\LegalEase\api\uploads`
- **macOS/Linux**: Create directory `~/repo/LegalEase/api/uploads`

Files are saved securely under unique names referencing their document records (e.g. `file_a7e937d10b9d_contract.pdf`).

---

## Backup & Restore

### Export Database
```bash
mongodump --db legalease --out C:\backups\legalease_backup
```

### Import/Restore Database
```bash
mongorestore --db legalease C:\backups\legalease_backup\legalease
```

---

## Troubleshooting

| Issue | Cause | Solution |
| :--- | :--- | :--- |
| **Connection Refused** | MongoDB service isn't running | Run `net start MongoDB` (Windows) or `brew services start mongodb-community` (macOS). |
| **Port Collision** | Port 27017 is taken | Find and kill active processes holding the port. |
| **Validation Error** | Mismatching payload keys | Ensure your application routes submit queries matching the snake_case schema (e.g., `user_id`, not `userId`). |
| **Index creation failed** | Duplicate entries exist | Clear collections before running index command. |
