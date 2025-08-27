# Ubuntu VPS Deployment Guide

This guide covers deploying your Pisoft Solutions Rails application to an Ubuntu VPS server.

## 🚀 Quick VPS Deployment

### Option 1: Automated Deployment (Recommended)
```bash
./deploy-vps.sh
```

This script will:
- ✅ Install Docker and Docker Compose
- ✅ Set up Nginx as reverse proxy
- ✅ Configure firewall (UFW)
- ✅ Set up log rotation
- ✅ Generate SECRET_KEY_BASE
- ✅ Build and deploy containers
- ✅ Set up database

### Option 2: Manual Deployment

#### 1. Server Preparation
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Log out and log back in for Docker group to take effect
```

#### 2. Application Setup
```bash
# Clone your repository
git clone <your-repo-url>
cd pisoftsolutions

# Set up environment
cp env.vps.example .env.production
# Edit .env.production with your values

# Generate SECRET_KEY_BASE
./generate-secret-key.sh

# Deploy
docker-compose -f docker-compose.vps.yml up --build -d
```

#### 3. Nginx Setup
```bash
# Install Nginx
sudo apt install nginx -y

# Create configuration
sudo nano /etc/nginx/sites-available/pisoftsolutions
```

Add this configuration:
```nginx
server {
    listen 80;
    server_name your-domain.com;  # Replace with your domain
    
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/pisoftsolutions /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

## 🔧 Key Differences for VPS Deployment

### 1. Security Considerations
- **Port Binding**: Containers bind to `127.0.0.1` (localhost only)
- **Firewall**: UFW configured to allow only SSH and HTTP/HTTPS
- **Nginx Proxy**: External traffic goes through Nginx, not directly to Rails

### 2. Environment Variables
- **HOST**: Set to your VPS domain or IP
- **Strong Passwords**: Use secure database passwords
- **External Services**: Configure Razorpay with production keys

### 3. File Structure
```
/home/username/pisoftsolutions/
├── docker-compose.vps.yml    # VPS-specific compose file
├── .env.production          # Production environment variables
├── log/                     # Application logs
├── tmp/                     # Temporary files
└── ssl/                     # SSL certificates (if using HTTPS)
```

## 🌐 Domain and SSL Setup

### 1. Domain Configuration
```bash
# Point your domain to your VPS IP
# A record: your-domain.com -> YOUR_VPS_IP
# A record: www.your-domain.com -> YOUR_VPS_IP
```

### 2. SSL with Let's Encrypt
```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Get SSL certificate
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

## 📊 Monitoring and Maintenance

### 1. Log Monitoring
```bash
# Application logs
docker-compose -f docker-compose.vps.yml logs -f

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# System logs
sudo journalctl -u docker -f
```

### 2. Performance Monitoring
```bash
# Check container resources
docker stats

# Check disk usage
df -h

# Check memory usage
free -h

# Check system load
htop
```

### 3. Backup Strategy
```bash
# Database backup
docker-compose -f docker-compose.vps.yml exec db pg_dump -U postgres pisoftsolutions_production > backup_$(date +%Y%m%d_%H%M%S).sql

# Application backup
tar -czf app_backup_$(date +%Y%m%d_%H%M%S).tar.gz . --exclude=log --exclude=tmp --exclude=.git
```

## 🔄 Updates and Maintenance

### 1. Application Updates
```bash
# Pull latest code
git pull origin main

# Rebuild and restart
docker-compose -f docker-compose.vps.yml down
docker-compose -f docker-compose.vps.yml up --build -d

# Run migrations
docker-compose -f docker-compose.vps.yml exec web bundle exec rails db:migrate
```

### 2. System Updates
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Docker
sudo apt install docker-ce docker-ce-cli containerd.io -y
```

## 🚨 Troubleshooting

### Common Issues

**1. Port Already in Use**
```bash
# Check what's using port 3000
sudo netstat -tlnp | grep :3000

# Kill process if needed
sudo kill -9 <PID>
```

**2. Permission Issues**
```bash
# Fix log directory permissions
sudo chown -R $USER:$USER log tmp
chmod 755 log tmp
```

**3. Database Connection Issues**
```bash
# Check database logs
docker-compose -f docker-compose.vps.yml logs db

# Restart database
docker-compose -f docker-compose.vps.yml restart db
```

**4. Nginx Issues**
```bash
# Test nginx configuration
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx

# Check nginx status
sudo systemctl status nginx
```

## 🔒 Security Checklist

- [ ] Change default database password
- [ ] Set up firewall (UFW)
- [ ] Configure SSL certificates
- [ ] Set up regular backups
- [ ] Monitor logs for suspicious activity
- [ ] Keep system packages updated
- [ ] Use strong SECRET_KEY_BASE
- [ ] Configure proper file permissions

## 📞 Support Commands

```bash
# Check application status
docker-compose -f docker-compose.vps.yml ps

# View all logs
docker-compose -f docker-compose.vps.yml logs

# Restart application
docker-compose -f docker-compose.vps.yml restart

# Access Rails console
docker-compose -f docker-compose.vps.yml exec web rails console

# Check system resources
docker stats
```

## 🎯 Performance Tips

1. **Use SSD storage** for better database performance
2. **Configure swap** if you have limited RAM
3. **Enable gzip compression** in Nginx
4. **Use CDN** for static assets
5. **Monitor and optimize database queries**
6. **Set up caching** (Redis) if needed

Your VPS deployment is now ready for production! 🚀
