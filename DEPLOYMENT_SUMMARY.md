# Production Deployment - Issues Fixed and Steps Summary

## Issues Found and Fixed

### 1. Missing Files
- ✅ **Created `nginx.conf`** - Production nginx configuration with SSL support
- ✅ **Created `.env.production`** - Production environment variables file
- ✅ **Created `ssl/` directory** - For SSL certificates
- ✅ **Created health check endpoint** - `/health` route for monitoring

### 2. Configuration Issues
- ✅ **Fixed database.yml** - Corrected default username from "pisoftsolutions" to "postgres"
- ✅ **Fixed production.rb** - Made SSL forcing configurable via environment variable
- ✅ **Added localhost to allowed hosts** - For development compatibility

### 3. Missing Scripts
- ✅ **Created `deploy_production.sh`** - Comprehensive deployment script
- ✅ **Created `setup_production.sh`** - Quick setup script for environment configuration
- ✅ **Created `PRODUCTION_DEPLOYMENT.md`** - Detailed deployment guide

## Files Created/Modified

### New Files
1. `nginx.conf` - Nginx reverse proxy configuration
2. `.env.production` - Production environment variables
3. `.env.production.example` - Example environment file
4. `deploy_production.sh` - Deployment script
5. `setup_production.sh` - Setup script
6. `PRODUCTION_DEPLOYMENT.md` - Deployment guide
7. `app/controllers/health_controller.rb` - Health check controller
8. `ssl/` directory - For SSL certificates

### Modified Files
1. `config/database.yml` - Fixed production database username
2. `config/environments/production.rb` - Made SSL configurable, added localhost to hosts
3. `config/routes.rb` - Added health check route

## Production Deployment Steps

### Quick Start (Recommended)
```bash
# 1. Run the setup script
./setup_production.sh

# 2. Review and edit .env.production if needed
nano .env.production

# 3. Deploy with nginx
./deploy_production.sh --with-nginx
```

### Manual Setup
```bash
# 1. Create environment file
cp .env.production.example .env.production
nano .env.production

# 2. Create SSL certificates (optional)
mkdir -p ssl
# Add your SSL certificates to ssl/cert.pem and ssl/key.pem

# 3. Deploy
./deploy_production.sh --with-nginx
```

## Required Environment Variables

### Critical (Must be set)
- `RAILS_MASTER_KEY` - Rails master key for credentials
- `POSTGRES_PASSWORD` - Database password
- `DOMAIN` - Your domain name

### Important (Should be set)
- `RAZORPAY_KEY_ID` - Razorpay API key ID
- `RAZORPAY_KEY_SECRET` - Razorpay API secret
- `SMTP_USERNAME` - Email username
- `SMTP_PASSWORD` - Email password

### Optional
- `CDN_HOST` - CDN domain for assets
- `AWS_*` - AWS S3 configuration
- `FORCE_SSL` - Set to 'false' to disable SSL forcing

## SSL Certificate Setup

### Option 1: Let's Encrypt (Recommended)
```bash
sudo apt install certbot
sudo certbot certonly --standalone -d your-domain.com
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem ssl/key.pem
sudo chown $USER:$USER ssl/cert.pem ssl/key.pem
```

### Option 2: Self-Signed (Testing)
The deployment script will automatically create self-signed certificates if real ones are not found.

## Health Check Endpoints

- `/health` - Detailed health status (JSON)
- `/up` - Simple up/down status (Rails default)

## Monitoring and Maintenance

### View Logs
```bash
# All services
docker-compose -f docker-compose.prod.yml logs

# Specific service
docker-compose -f docker-compose.prod.yml logs web
docker-compose -f docker-compose.prod.yml logs nginx
```

### Check Status
```bash
# Container status
docker-compose -f docker-compose.prod.yml ps

# Health check
curl http://localhost:3000/health
```

### Update Application
```bash
git pull origin main
./deploy_production.sh --with-nginx
```

## Security Considerations

1. **Environment Variables**
   - Never commit `.env.production` to version control
   - Use strong, unique passwords
   - Rotate secrets regularly

2. **SSL/TLS**
   - Use real SSL certificates for production
   - Enable HSTS headers
   - Regular certificate renewal

3. **Firewall**
   - Configure firewall to allow ports 80, 443, 3000
   - Use fail2ban for additional protection

4. **Backups**
   - Set up regular database backups
   - Backup uploaded files
   - Test backup restoration

## Troubleshooting

### Common Issues

1. **Database Connection Errors**
   - Check database container is running
   - Verify credentials in `.env.production`
   - Check database logs

2. **SSL Certificate Issues**
   - Verify certificate files exist in `ssl/` directory
   - Check certificate validity
   - Ensure proper file permissions

3. **Asset Precompilation Errors**
   - Check all required gems are installed
   - Verify Node.js dependencies
   - Check asset compilation logs

4. **Razorpay Integration Issues**
   - Verify API keys in `.env.production`
   - Check webhook configuration
   - Test in test mode first

### Performance Optimization

1. **Database**
   - Add indexes for frequently queried columns
   - Configure connection pooling
   - Monitor slow queries

2. **Caching**
   - Enable Redis caching
   - Configure CDN for static assets
   - Use browser caching headers

3. **Monitoring**
   - Set up application monitoring
   - Configure log aggregation
   - Set up alerting

## Support

For issues:
1. Check application logs
2. Review troubleshooting section
3. Check Rails documentation
4. Contact development team

## Files to Never Commit

- `.env.production`
- `ssl/cert.pem`
- `ssl/key.pem`
- `config/master.key`
- Any files containing real API keys or passwords
