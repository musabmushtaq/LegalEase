# LegalEase Database Setup

This guide walks you through setting up the MongoDB database for LegalEase.

## Prerequisites

- **MongoDB Community Server** (version 5.0+) running on port 27017
- **Python 3.11+** (for initialization script)

**Note:** MongoDB Compass (GUI) is optional - it's useful for viewing data but not required for setup.

---

## Installation

### Windows

**Option 1: MongoDB Community Server (Installer)**

1. Download from [mongodb.com/try/download/community](https://www.mongodb.com/try/download/community)
2. Run the installer and follow the wizard
3. Choose "Install MongoDB as a Service" (recommended)
4. MongoDB runs on default port `27017`

**Option 2: MongoDB via Chocolatey**

```powershell
choco install mongodb-community
```

**Option 3: MongoDB via Windows WSL**

```bash
sudo apt-get install -y mongodb-org
sudo systemctl start mongod
```

### macOS

```bash
brew tap mongodb/brew
brew install mongodb-community
brew services start mongodb-community
```

### Linux

```bash
sudo apt-get install -y mongodb-org
sudo systemctl start mongod
```

---

## Database Initialization

### Quick Setup (Automated - Recommended)

This is the fastest way to initialize your database on a new system.

#### Step 1: Start MongoDB Service

**Windows (if installed as service):**

```powershell
net start MongoDB
```

**macOS:**

```bash
brew services start mongodb-community
```

**Linux:**

```bash
sudo systemctl start mongod
```

#### Step 2: Install Python Dependencies

```bash
cd db
pip install -r requirements.txt
```

#### Step 3: Create .env File

Copy the example and configure (optional, defaults work for local dev):

```bash
cp .env.example .env
```

Edit `.env` if needed:

```
MONGODB_URI=mongodb://localhost:27017
MONGODB_DB=legalease
```

#### Step 4: Run Initialization Script

```bash
python init_db.py
```

**Expected output:**

```
🔌 Connecting to MongoDB at mongodb://localhost:27017...
✓ Connected to database: legalease

📊 Creating indexes...
  ✓ users collection indexes created
  ✓ chats collection indexes created
  ✓ files collection indexes created

✅ Database initialized successfully!
   Collections: users, chats, files
   Database: legalease
```

---

### Manual Setup (Alternative)

If you prefer to set up manually or run into issues with the automated script:

#### 1. Connect to MongoDB

**Using mongosh (CLI):**

```bash
mongosh
```

**Using MongoDB Compass (GUI):**

- Download from [mongodb.com/products/compass](https://www.mongodb.com/products/compass)
- Connect to `mongodb://localhost:27017`

#### 2. Create Database and Collections

Run this in `mongosh`:

```javascript
// Switch to legalease database (creates if doesn't exist)
use legalease

// Create users collection with schema validation
db.createCollection("users", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["userId", "email", "passwordHash"],
      properties: {
        _id: { bsonType: "objectId" },
        userId: { bsonType: "string" },
        email: { bsonType: "string" },
        username: { bsonType: "string" },
        passwordHash: { bsonType: "string" },
        context: { bsonType: "string" }
      }
    }
  }
})

// Create chats collection
db.createCollection("chats")

// Create files collection
db.createCollection("files")
```

#### 3. Create Indexes

Run in `mongosh`:

```javascript
use legalease

// Users indexes
db.users.createIndex({ "userId": 1 }, { unique: true })
db.users.createIndex({ "email": 1 }, { unique: true })

// Chats indexes
db.chats.createIndex({ "chatId": 1 }, { unique: true })
db.chats.createIndex({ "ownerId": 1, "createdAt": -1 })
db.chats.createIndex({ "isPinned": 1 })

// Files indexes
db.files.createIndex({ "fileId": 1 }, { unique: true })
db.files.createIndex({ "userId": 1, "uploadedAt": -1 })
```

#### 4. Verify Setup

Check your database and collections:

```javascript
// Show all databases
show dbs

// Show current database collections
show collections

// Count documents in each collection
db.users.countDocuments()
db.chats.countDocuments()
db.files.countDocuments()

// Check indexes
db.users.getIndexes()
db.chats.getIndexes()
db.files.getIndexes()
```

---

## Connection String

For your API code, use this connection string:

```
mongodb://localhost:27017/legalease
```

**Environment Variable (.env):**

```
MONGODB_URI=mongodb://localhost:27017/legalease
```

---

## File Storage Setup

Create the local file storage directory:

**Windows:**

```powershell
mkdir C:\legalEaseDB
```

**macOS/Linux:**

```bash
mkdir -p ~/legalEaseDB
```

Your API will store uploaded files here with structure:

```
C:\legalEaseDB\
├── user_123\
│   ├── contract.pdf
│   ├── agreement.docx
│   └── ...
├── user_456\
│   └── ...
```

---

## Quick Reset (Wipe Database)

⚠️ **Use only for development!**

```javascript
use legalease

// Delete all collections
db.users.deleteMany({})
db.chats.deleteMany({})
db.files.deleteMany({})

// Or drop entire database
db.dropDatabase()
```

Then re-run the **Create Database and Collections** section above.

---

## Verify MongoDB is Running

**Check status:**

```powershell
# Windows
Get-Service MongoDB

# macOS
brew services list

# Linux
sudo systemctl status mongod
```

**Test connection:**

```bash
mongosh --eval "db.adminCommand('ping')"
```

Expected output:

```
{ ok: 1 }
```

---

## Access Control (Optional - For Production)

For production setups, create users with authentication:

```javascript
use admin

// Create admin user
db.createUser({
  user: "admin",
  pwd: "your_secure_password",
  roles: [ "root" ]
})

// Create app user with limited permissions
use legalease
db.createUser({
  user: "legalease_app",
  pwd: "app_password",
  roles: [ { role: "readWrite", db: "legalease" } ]
})
```

Then connect with:

```
mongodb://legalease_app:app_password@localhost:27017/legalease
```

---

## Troubleshooting

| Issue               | Solution                                                              |
| ------------------- | --------------------------------------------------------------------- |
| MongoDB won't start | Check if port 27017 is already in use: `netstat -ano \| find "27017"` |
| Connection refused  | Verify MongoDB service is running: `net start MongoDB` (Windows)      |
| Database not found  | Databases are created automatically on first write                    |
| Indexes not working | Run index creation again, ensure no typos in field names              |
| Permission denied   | Run mongosh with admin privileges or fix folder permissions           |

---

## Next Steps

1. **Start MongoDB**: Run service as shown in "Quick Setup" above
2. **Install dependencies**: `cd db && pip install -r requirements.txt`
3. **Initialize database**: `python init_db.py`
4. **Create file storage**: Make `C:\legalEaseDB` directory
5. **Run API**: Set up and start your FastAPI server (see `api/README.md`)
6. **Start Flutter app**: Run Flutter on emulator or physical device (see `app/README.md`)

Database is now ready for development! 🚀
