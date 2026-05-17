# LegalEase Deployment Guide

## Overview

This guide provides instructions for deploying LegalEase in production environments with security best practices and scaling considerations.

## Prerequisites

- Python 3.11+
- Node.js 18+ (for web deployment)
- MongoDB 5.0+
- Docker & Docker Compose (optional)
- Nginx or Apache (for reverse proxy)
- SSL certificate (for HTTPS)

## Environment Setup

### 1. Backend API Setup

```bash
cd api
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Create Production .env File

Copy `.env.example` to `.env` and update values:

```bash
cp .env.example .env
```

Edit `.env` with production values:

```
MONGODB_URI=mongodb+srv://user:password@cluster.mongodb.net/legalease
MONGODB_DB=legalease
API_BASE_URL=https://api.yourdomain.com
DEFAULT_SYSTEM_PROMPT=Your legal system prompt here
SECRET_KEY=your_very_long_random_secret_key_min_32_chars
ALGORITHM=HS256
ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
MAX_FILE_SIZE=10485760
RATE_LIMIT=100/minute
```

### 3. Generate Secure SECRET_KEY

```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

### 4. Update CORS Origins

Set `ALLOWED_ORIGINS` to your actual domain(s):

```
ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

## Deployment Options

### Option 1: Traditional Server Deployment

#### 1. Install Gunicorn (Production WSGI Server)

```bash
pip install gunicorn
```

#### 2. Create Systemd Service

Create `/etc/systemd/system/legalease-api.service`:

```ini
[Unit]
Description=LegalEase API
After=network.target mongodb.service

[Service]
Type=notify
User=www-data
WorkingDirectory=/var/www/legalease/api
Environment="PATH=/var/www/legalease/api/venv/bin"
ExecStart=/var/www/legalease/api/venv/bin/gunicorn -w 4 -b 0.0.0.0:8000 -k uvicorn.workers.UvicornWorker main:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl enable legalease-api
sudo systemctl start legalease-api
```

#### 3. Configure Nginx Reverse Proxy

Create `/etc/nginx/sites-available/legalease`:

```nginx
upstream legalease_api {
    server 127.0.0.1:8000;
}

upstream legalease_web {
    server 127.0.0.1:8080;
}

server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # API Routes
    location /api/ {
        proxy_pass http://legalease_api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }
    
    # Web Routes
    location / {
        proxy_pass http://legalease_web/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/legalease /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Option 2: Docker Deployment

#### 1. Create Docker Compose File

See `docker-compose.yml` in the project root.

#### 2. Build and Run

```bash
docker-compose up -d
```

### Option 3: Cloud Deployment (AWS, GCP, Azure)

Use services like:
- **AWS**: EC2 + RDS + ALB
- **GCP**: Cloud Run + Cloud Firestore
- **Azure**: App Service + Cosmos DB

## Security Checklist

- [ ] HTTPS enabled with valid SSL certificate
- [ ] CORS properly configured (not wildcards)
- [ ] Rate limiting enabled (configured in .env)
- [ ] JWT SECRET_KEY is long and random
- [ ] Database credentials in .env (not in code)
- [ ] Regular backups enabled (MongoDB)
- [ ] Firewall rules configured
- [ ] DDoS protection configured
- [ ] Monitoring and alerting setup
- [ ] Regular security updates

## Monitoring and Logging

### API Logs

View API logs:

```bash
sudo journalctl -u legalease-api -f
```

### MongoDB Monitoring

Enable MongoDB profiling:

```javascript
db.setProfilingLevel(1, { slowms: 100 });
```

## Scaling Considerations

1. **Database**: Use MongoDB replication for HA
2. **API Server**: Deploy multiple instances behind load balancer
3. **Static Files**: Serve web assets from CDN
4. **Caching**: Implement Redis for session/chat caching
5. **Message Queue**: Use RabbitMQ for async tasks

## SSL Certificate Setup (Let's Encrypt)

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot certonly --nginx -d yourdomain.com -d www.yourdomain.com
```

Auto-renewal cron job:

```bash
0 12 * * * certbot renew --quiet
```

## Database Backups

### Manual Backup

```bash
mongodump --uri="mongodb://user:password@host:27017/legalease" --out=/backups/legalease_backup_$(date +%Y%m%d)
```

### Automated Backups

Add to crontab:

```bash
0 2 * * * mongodump --uri="mongodb://..." --out=/backups/legalease_$(date +\%Y\%m\%d)
```

## Performance Optimization

1. Enable gzip compression in Nginx
2. Minify CSS and JavaScript
3. Enable browser caching headers
4. Use CDN for static assets
5. Implement database indexing
6. Monitor and optimize slow queries

## Troubleshooting

### API Connection Issues

```bash
# Check API health
curl https://yourdomain.com/health

# Check logs
sudo journalctl -u legalease-api -n 50
```

### Database Connection Issues

```bash
# Test MongoDB connection
mongosh "mongodb+srv://user:password@cluster.mongodb.net/legalease"
```

### SSL Certificate Issues

```bash
# Verify certificate
openssl s_client -connect yourdomain.com:443

# Check renewal
certbot certificates
```

## Support and Updates

- Monitor for security updates
- Keep dependencies updated
- Subscribe to security advisories
- Implement automated testing in CI/CD
