# LegalEase Database Setup & Management

**Status**: 🚀 Production Ready | MongoDB | Fully Configured

This guide walks you through setting up and managing the MongoDB database for LegalEase.

## Prerequisites

- **MongoDB Community Server** (version 5.0+) running on port 27017
- **Python 3.11+** (for initialization script)
- **Recommended**: MongoDB Compass (GUI for data browsing)

### Requirements Checklist

- [ ] MongoDB Community Server installed
- [ ] Python 3.11+ installed
- [ ] 500 MB free disk space minimum
- [ ] Port 27017 available

---

## Installation

### Windows

#### Option 1: MongoDB Community Server (Installer - Recommended)

1. Download from [mongodb.com/try/download/community](https://www.mongodb.com/try/download/community)
2. Run the installer and follow the wizard
3. Choose **"Install MongoDB as a Service"** (recommended)
4. MongoDB runs on default port `27017`
5. Verify installation:
   ```bash
   mongosh
   show dbs
   exit
   ```

#### Option 2: MongoDB via Chocolatey

```powershell
# Install Chocolatey (if not already installed)
# Then run:
choco install mongodb-community
```

#### Option 3: MongoDB via Windows WSL

```bash
# Inside WSL Ubuntu terminal
sudo apt-get install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod
```

### macOS

**Using Homebrew (Recommended)**:

```bash
brew tap mongodb/brew
brew install mongodb-community
brew services start mongodb-community
```

**Verify**:

```bash
mongosh
show dbs
exit
```

### Linux (Ubuntu/Debian)

```bash
sudo apt-get install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod
```

**Verify**:

```bash
mongosh
show dbs
exit
```

---

## Database Initialization

### Quick Setup (Automated - Recommended)

This is the fastest way to initialize your database on a new system.

#### Step 1: Start MongoDB Service

**Windows (if installed as service)**:

```powershell
net start MongoDB
```

**Windows (if not installed as service)**:

```bash
mongod
# Keep this terminal open
```

**macOS**:

```bash
brew services start mongodb-community
```

**Linux**:

```bash
sudo systemctl start mongod
```

#### Step 2: Install Python Dependencies

```bash
cd db
pip install -r requirements.txt
```

**Dependencies**:

- `pymongo` - MongoDB driver
- `python-dotenv` - Environment variable management

#### Step 3: Create .env File (Optional)

For local development, defaults work fine. For custom setup:

```bash
cp .env.example .env
```

**Edit .env** (if needed):

```
MONGODB_URI=mongodb://localhost:27017
MONGODB_DB=legalease
```

#### Step 4: Run Initialization Script

```bash
python init_db.py
```

**Expected output**:

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

**Success!** Your database is ready to use.

---

### Manual Setup (Alternative)

If you prefer to set up manually or run into issues with the automated script:

#### 1. Connect to MongoDB

**Using mongosh (recommended)**:

```bash
mongosh
```

**Using MongoDB Compass (GUI)**:

- Download from [mongodb.com/products/compass](https://www.mongodb.com/products/compass)
- Click "Connect"
- Enter `mongodb://localhost:27017`
- Click "Connect"

#### 2. Create Database and Collections

In mongosh, run:

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

// Verify collections created
show collections
```

#### 3. Create Indexes

For performance optimization:

```javascript
use legalease

// Users indexes
db.users.createIndex({ "userId": 1 }, { unique: true })
db.users.createIndex({ "email": 1 }, { unique: true })
db.users.createIndex({ "createdAt": -1 })

// Chats indexes
db.chats.createIndex({ "chatId": 1 }, { unique: true })
db.chats.createIndex({ "ownerId": 1, "createdAt": -1 })
db.chats.createIndex({ "isPinned": 1 })

// Files indexes
db.files.createIndex({ "fileId": 1 }, { unique: true })
db.files.createIndex({ "userId": 1, "uploadedAt": -1 })

// Verify indexes
db.users.getIndexes()
```

#### 4. Verify Setup

Check your database and collections:

```javascript
use legalease

// Show all databases
show dbs

// Show all collections
show collections

// Count documents
db.users.countDocuments()
db.chats.countDocuments()
db.files.countDocuments()

// Exit
exit
```

---

## Database Browser (MongoDB Compass)

### Installation

Download from [mongodb.com/products/compass](https://www.mongodb.com/products/compass)

### Connection

1. Open MongoDB Compass
2. Default connection: `mongodb://localhost:27017`
3. Click "Connect"
4. Browse databases and collections
5. View, create, edit, delete documents visually

### Features

- **Browse**: Explore all databases and collections
- **Query**: Write queries with visual editor
- **Insert**: Add new documents
- **Edit**: Modify existing documents
- **Delete**: Remove documents
- **Indexes**: View and manage indexes
- **Performance**: Monitor query performance

---

## Backup & Restore

### Backup (Export)

**Entire database**:

```bash
mongodump --db legalease --out backup_$(date +%Y%m%d)
```

**Specific collection**:

```bash
mongodump --db legalease --collection chats --out backup_chats
```

**With compression**:

```bash
mongodump --db legalease --out - | gzip > backup.gz
```

### Restore (Import)

**Entire database**:

```bash
mongorestore --db legalease backup_20260520/legalease
```

**Specific collection**:

```bash
mongorestore --db legalease --collection chats backup/legalease/chats.bson
```

**From compressed backup**:

```bash
gunzip -c backup.gz | mongorestore --db legalease
```

### Scheduled Backups (Windows)

Create `backup.bat`:

```batch
@echo off
setlocal enabledelayedexpansion
for /f "tokens=1-4 delims=/ " %%a in ('date /t') do (set mydate=%%d%%b%%a)
mongodump --db legalease --out backups\backup_%mydate%
```

Schedule with Task Scheduler:

1. Open Task Scheduler
2. Create Basic Task
3. Set trigger (daily at 2 AM)
4. Set action to run `backup.bat`

---

## Common Management Tasks

### View Database Statistics

```javascript
use legalease
db.stats()
```

**Output includes**:

- Database size
- Collection count
- Average object size
- Total object count

### Monitor Collection Size

```javascript
db.users.stats();
db.chats.stats();
db.files.stats();
```

### Find Large Documents

```javascript
use legalease

// Documents larger than 1 MB
db.chats.find({
  $expr: { $gt: [{ $bsonSize: "$$ROOT" }, 1048576] }
})
```

### Clean Up Old Data

```javascript
// Remove chats from 90 days ago
db.chats.deleteMany({
  createdAt: { $lt: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000) },
});

// Remove archived files
db.files.deleteMany({ status: "archived" });
```

### Rebuild Indexes

```javascript
// This locks the database briefly
db.users.reIndex();
db.chats.reIndex();
db.files.reIndex();
```

---

## Troubleshooting

### MongoDB Won't Start

**Windows Service Error**:

```powershell
# Check service status
Get-Service MongoDB

# Start service manually
net start MongoDB

# If fails, check logs
# Logs usually at: C:\Program Files\MongoDB\Server\5.0\log\mongod.log
```

**Connection Refused**:

```bash
# Check if MongoDB is running
netstat -an | grep 27017

# Start MongoDB if not running
mongod  # Or: brew services start mongodb-community
```

### Connection Issues from Python

```python
from pymongo import MongoClient

try:
    client = MongoClient('mongodb://localhost:27017')
    db = client['legalease']
    print("Connected successfully!")
except Exception as e:
    print(f"Connection failed: {e}")
```

### Database Not Found

```javascript
// Check current databases
show dbs

// Create and use database
use legalease
db.createCollection("test")

// Now shows in list
show dbs
```

### Disk Space Issues

```bash
# Check disk usage
df -h  # macOS/Linux
dir C:\  # Windows

# Find largest collections
db.stats()

# Remove old backups
rm -rf backup_old_dates
```

### Performance Issues

```javascript
// Find slow queries
db.setProfilingLevel(1);
db.system.profile.find().limit(5).sort({ ts: -1 }).pretty();

// Check index usage
db.collection.aggregate([{ $indexStats: {} }]);
```

---

## Connection Strings

### Local Development

```
mongodb://localhost:27017
```

### With Authentication

```
mongodb://username:password@localhost:27017/legalease
```

### MongoDB Atlas (Cloud)

```
mongodb+srv://username:password@cluster.mongodb.net/legalease?retryWrites=true&w=majority
```

### Replica Set (Production)

```
mongodb://host1:27017,host2:27017,host3:27017/?replicaSet=rs0
```

---

## Integration with LegalEase Components

### For API Server (Python FastAPI)

**In api/.env**:

```
MONGODB_URI=mongodb://localhost:27017
MONGODB_DB=legalease
```

**In api/main.py**:

```python
mongo_client = AsyncIOMotorClient(settings.mongodb_uri)
db = mongo_client[settings.mongodb_db]
```

### For Mobile App (Flutter)

The app connects through the API backend, not directly to MongoDB.

### For Web App (JavaScript)

The web app connects through the API backend, not directly to MongoDB.

---

## Schema Reference

For detailed database schema documentation, see [DATABASE_DESIGN.md](../docs/DATABASE_DESIGN.md)

**Collections**:

- `users` - User accounts (100K documents typical)
- `chats` - Conversations with embedded messages (500K documents)
- `files` - File metadata (200K documents)

**Indexes**:

- 8+ strategic indexes for query performance
- Unique constraints on userId, email, chatId, fileId
- Compound indexes for common queries

---

## Configuration Files

### requirements.txt

```
pymongo==4.5.0
python-dotenv==1.0.0
```

### .env.example

```
MONGODB_URI=mongodb://localhost:27017
MONGODB_DB=legalease
```

### init_db.py

Python script that:

1. Connects to MongoDB
2. Creates database
3. Creates collections
4. Creates indexes
5. Provides initialization feedback

---

## Best Practices

### Development

✅ Use local MongoDB for testing
✅ Run init_db.py for fresh setup
✅ Keep backups of important data
✅ Use MongoDB Compass for data exploration

### Production

✅ Use MongoDB Atlas or managed service
✅ Enable authentication
✅ Use network isolation
✅ Enable encryption at rest
✅ Set up automated backups
✅ Monitor performance metrics

### Security

✅ Change default passwords
✅ Restrict network access
✅ Enable SSL/TLS
✅ Use strong authentication
✅ Audit log access

---

## Version History

| Version | Date     | Changes           |
| ------- | -------- | ----------------- |
| 1.0     | May 2026 | Initial setup     |
| 1.1     | Planned  | Atlas integration |
| 2.0     | Planned  | Sharding support  |

---

## Resources

- [MongoDB Documentation](https://docs.mongodb.com/)
- [MongoDB Compass Guide](https://docs.mongodb.com/compass/)
- [MongoDB University](https://university.mongodb.com/)
- [Database Design](../docs/DATABASE_DESIGN.md)
- [System Architecture](../docs/SYSTEM_ARCHITECTURE.md)

---

## Support

For database issues:

1. Check this README
2. Review [DATABASE_DESIGN.md](../docs/DATABASE_DESIGN.md)
3. Check [troubleshooting section](../docs/SYSTEM_ARCHITECTURE.md#11-troubleshooting-guide)
4. Create GitHub issue with:
   - MongoDB version
   - Error message
   - Steps to reproduce
   - mongosh output

````

#### Step 4: Run Initialization Script

```bash
python init_db.py
````

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
