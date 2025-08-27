# Production Deployment Guide

This guide will walk you through deploying the Pisoft Solutions Rails application to production using Docker.

## Prerequisites

1. **Docker and Docker Compose** installed on your production server
2. **Domain name** pointing to your server
3. **SSL certificates** for your domain (optional for initial setup)
4. **Razorpay account** with API keys
5. **SMTP credentials** for email functionality

## Step 1: Server Setup

### 1.1 Install Docker and Docker Compose

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout and login again for group changes to take effect
```

### 1.2 Clone the Application

```bash
git clone <your-repository-url>
cd pisoftsolutions
```

## Step 2: Environment Configuration

### 2.1 Create Production Environment File

```bash
cp .env.production.example .env.production
nano .env.production
```

### 2.2 Required Environment Variables

Update the following variables in `.env.production`:

```bash
# Rails Configuration
RAILS_ENV=production
RAILS_MASTER_KEY=your_actual_rails_master_key_here
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true

# Database Configuration
POSTGRES_DB=pisoftsolutions_production
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_secure_database_password_here
POSTGRES_HOST=db
POSTGRES_PORT=5432

# Redis Configuration
REDIS_URL=redis://redis:6379/0

# Razorpay Configuration
RAZORPAY_KEY_ID=your_actual_razorpay_key_id
RAZORPAY_KEY_SECRET=your_actual_razorpay_key_secret

# Domain Configuration
DOMAIN=your-actual-domain.com
CDN_HOST=https://your-cdn-domain.com

# SMTP Configuration
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-specific-password

# Security
SECRET_KEY_BASE=your_actual_secret_key_base

# Application Settings
RAILS_MAX_THREADS=5
WEB_CONCURRENCY=2
```

### 2.3 Generate Rails Master Key

If you don't have a Rails master key:

```bash
# Generate a new master key
rails credentials:edit
```

Or copy the master key from your development environment:

```bash
# Copy from config/master.key
cp config/master.key ./
```

## Step 3: SSL Certificate Setup (Optional)

### 3.1 Using Let's Encrypt (Recommended)

```bash
# Install Certbot
sudo apt install certbot

# Get SSL certificate
sudo certbot certonly --standalone -d your-domain.com -d www.your-domain.com

# Copy certificates to the ssl directory
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem ssl/key.pem
sudo chown $USER:$USER ssl/cert.pem ssl/key.pem
```

### 3.2 Self-Signed Certificates (For Testing)

The deployment script will automatically create self-signed certificates if real ones are not found.

## Step 4: Database Setup

### 4.1 Initial Database Setup

The deployment script will handle this automatically, but you can also do it manually:

```bash
# Start database
docker-compose -f docker-compose.prod.yml up -d db redis

# Wait for database to be ready
sleep 10

# Run migrations
docker-compose -f docker-compose.prod.yml exec web rails db:migrate

# Seed database (if needed)
docker-compose -f docker-compose.prod.yml exec web rails db:seed
```

## Step 5: Deployment

### 5.1 Basic Deployment (Without Nginx)

```bash
./deploy_production.sh
```

### 5.2 Deployment with Nginx (Recommended)

```bash
./deploy_production.sh --with-nginx
```

## Step 6: Post-Deployment Configuration

### 6.1 Firewall Configuration

```bash
# Allow necessary ports
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 3000/tcp  # Rails app (if not using nginx)

# Enable firewall
sudo ufw enable
```

### 6.2 SSL Certificate Renewal (Let's Encrypt)

Create a renewal script:

```bash
#!/bin/bash
# /etc/cron.daily/renew-ssl

certbot renew --quiet
cp /etc/letsencrypt/live/your-domain.com/fullchain.pem /path/to/your/app/ssl/cert.pem
cp /etc/letsencrypt/live/your-domain.com/privkey.pem /path/to/your/app/ssl/key.pem
docker-compose -f /path/to/your/app/docker-compose.prod.yml restart nginx
```

Make it executable:

```bash
sudo chmod +x /etc/cron.daily/renew-ssl
```

## Step 7: Monitoring and Maintenance

### 7.1 Health Checks

The application provides health check endpoints:

- `/health` - Detailed health status
- `/up` - Simple up/down status

### 7.2 Logs

View application logs:

```bash
# All services
docker-compose -f docker-compose.prod.yml logs

# Specific service
docker-compose -f docker-compose.prod.yml logs web
docker-compose -f docker-compose.prod.yml logs nginx
```

### 7.3 Backup Strategy

Create a backup script:

```bash
#!/bin/bash
# backup.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups"

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup database
docker-compose -f docker-compose.prod.yml exec -T db pg_dump -U postgres pisoftsolutions_production > $BACKUP_DIR/db_backup_$DATE.sql

# Backup uploaded files
tar -czf $BACKUP_DIR/files_backup_$DATE.tar.gz storage/

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
```

### 7.4 Updates

To update the application:

```bash
# Pull latest changes
git pull origin main

# Rebuild and restart
./deploy_production.sh --with-nginx
```

## Troubleshooting

### Common Issues

1. **Database Connection Errors**
   - Check if database container is running
   - Verify database credentials in `.env.production`
   - Check database logs: `docker-compose -f docker-compose.prod.yml logs db`

2. **SSL Certificate Issues**
   - Verify certificate files exist in `ssl/` directory
   - Check certificate validity: `openssl x509 -in ssl/cert.pem -text -noout`
   - Ensure proper file permissions

3. **Asset Precompilation Errors**
   - Check if all required gems are installed
   - Verify Node.js dependencies if using JavaScript assets
   - Check asset compilation logs

4. **Razorpay Integration Issues**
   - Verify API keys in `.env.production`
   - Check Razorpay webhook configuration
   - Test payment flow in test mode first

### Performance Optimization

1. **Database Optimization**
   - Add database indexes for frequently queried columns
   - Configure connection pooling
   - Monitor slow queries

2. **Caching**
   - Enable Redis caching for sessions and fragments
   - Configure CDN for static assets
   - Use browser caching headers

3. **Monitoring**
   - Set up application monitoring (New Relic, DataDog, etc.)
   - Configure log aggregation
   - Set up alerting for critical issues

## Security Considerations

1. **Environment Variables**
   - Never commit `.env.production` to version control
   - Use strong, unique passwords
   - Rotate secrets regularly

2. **SSL/TLS**
   - Use strong SSL configuration
   - Enable HSTS headers
   - Regular certificate renewal

3. **Firewall**
   - Restrict access to necessary ports only
   - Use fail2ban for additional protection
   - Regular security updates

4. **Application Security**
   - Keep Rails and gems updated
   - Regular security audits
   - Monitor for suspicious activity

## Support

For issues specific to this application:

1. Check the application logs
2. Review the troubleshooting section
3. Check Rails documentation for specific errors
4. Contact the development team

## Maintenance Schedule

- **Daily**: Check application health and logs
- **Weekly**: Review security updates and backup verification
- **Monthly**: SSL certificate renewal check and performance review
- **Quarterly**: Full security audit and dependency updates
