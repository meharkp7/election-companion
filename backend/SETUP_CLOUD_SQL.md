# Cloud SQL Setup Guide

## Current Configuration
Your `.env` is set up for Cloud SQL Proxy:
```
DB_HOST=localhost
DB_PORT=5433        # Cloud SQL Proxy port
DB_NAME=voteready
DB_USER=appuser
DB_PASSWORD=Meharkp@7
```

## Option 1: Using Cloud SQL Proxy (Recommended for local dev)

### Step 1: Install Cloud SQL Proxy
```bash
# Download Cloud SQL Proxy
curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.0/cloud-sql-proxy.darwin.amd64

# Make it executable
chmod +x cloud-sql-proxy

# Move to PATH
sudo mv cloud-sql-proxy /usr/local/bin/
```

### Step 2: Start Cloud SQL Proxy
```bash
# Using IAM authentication (recommended)
cloud-sql-proxy --port 5433 vote-ready-8494a:us-central1:voteready-db

# OR using service account key
cloud-sql-proxy --port 5433 --credentials-file=/path/to/key.json vote-ready-8494a:us-central1:voteready-db
```

### Step 3: Verify Connection
```bash
psql -h localhost -p 5433 -U appuser -d voteready
```

## Option 2: Connect Directly to Cloud SQL (Public IP)

Update `.env`:
```
DB_HOST=<CLOUD_SQL_PUBLIC_IP>
DB_PORT=5432
DB_NAME=voteready
DB_USER=appuser
DB_PASSWORD=Meharkp@7
```

Get your Cloud SQL instance IP from:
https://console.cloud.google.com/sql/instances

## Option 3: Use Local PostgreSQL (Quick Testing)

If you want to test locally without Cloud SQL:

```bash
# Install PostgreSQL
brew install postgresql@15

# Start PostgreSQL
brew services start postgresql@15

# Create database
createdb voteready

# Create user
createuser -P appuser  # Set password to Meharkp@7

# Apply schema
psql -d voteready -f src/config/schema.sql
```

Update `.env`:
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=voteready
DB_USER=appuser
DB_PASSWORD=Meharkp@7
```

## Quick Fix (Local Development)

Run this to start local PostgreSQL and set up everything:

```bash
# 1. Start PostgreSQL
brew services start postgresql@15

# 2. Create database
createdb voteready || true

# 3. Apply schema
cd backend
psql -d voteready -f src/config/schema.sql

# 4. Update .env for local connection
cat > .env << 'EOF'
PORT=5001

DB_HOST=localhost
DB_PORT=5432
DB_NAME=voteready
DB_USER=postgres
DB_PASSWORD=

GOOGLE_CLOUD_PROJECT_ID=vote-ready-8494a
GOOGLE_CLOUD_LOCATION=us-central1

NODE_ENV=development
EOF

# 5. Start backend
npm start
```

## Troubleshooting

### Error: "read ECONNRESET"
- Cloud SQL Proxy is not running
- Wrong port configuration
- Database instance is not accessible

### Error: "password authentication failed"
- Wrong username/password in .env
- User doesn't exist in database

### Error: "database 'voteready' does not exist"
- Database hasn't been created yet
- Run: `createdb voteready`

## Verify Database Connection

```bash
cd backend
node -e "
const { pool } = require('./src/config/postgres');
pool.query('SELECT NOW()', (err, res) => {
  if (err) console.error('Connection failed:', err);
  else console.log('Connected! Server time:', res.rows[0].now);
  pool.end();
});
"
```
