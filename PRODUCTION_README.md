# Production Docker Setup for Pisoft Solutions Rails App

This document provides instructions for deploying the Pisoft Solutions Rails application in a production environment using Docker.

## 🚀 Quick Start

### Option 1: Using the production setup script (Recommended)

```bash
./docker-setup-prod.sh
```

This script will:
- Check for required environment variables
- Generate SSL certificates
- Generate secret key base
- Build and start production containers
- Set up the database
- Run migrations and seed data if needed

### Option 2: Manual setup

1. **Set up environment variables:**
   ```bash
   cp env.production.example .env.production
   # Edit .env.production with your actual values
   ```

2. **Generate SECRET_KEY_BASE (if missing):**
   ```bash
   ./generate-secret-key.sh
   ```

2. **Generate SSL certificates:**
   ```bash
   mkdir -p ssl
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
       -keyout ssl/key.pem \
       -out ssl/cert.pem \
       -subj "/C=US/ST=State/L=City/O=Organization/CN=yourdomain.com"
   ```

3. **Build and start containers:**
   ```bash
   docker-compose -f docker-compose.prod.yml up --build -d
   ```

4. **Set up database:**
   ```bash
   docker-compose -f docker-compose.prod.yml exec web bundle exec rails db:create db:migrate db:seed
   ```

## 🔧 Required Environment Variables

Create a `.env.production` file with the following variables:

```bash
# Database Configuration
POSTGRES_PASSWORD=your_secure_database_password_here
POSTGRES_USER=postgres
POSTGRES_DB=pisoftsolutions_production

# Rails Configuration
RAILS_ENV=production
SECRET_KEY_BASE=your_secret_key_base_here

# Razorpay Configuration
RAZORPAY_KEY_ID=your_razorpay_key_id_here
RAZORPAY_KEY_SECRET=your_razorpay_key_secret_here

# Application Configuration
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
```

## 🌐 Access Points

- **Main Application (HTTPS)**: https://localhost
- **Direct Rails**: http://localhost:3000
- **Database**: localhost:5432
- **Health Check**: https://localhost/health

## 📋 Production Commands

### View logs
```bash
# View all logs
docker-compose -f docker-compose.prod.yml logs -f

# View specific service logs
docker-compose -f docker-compose.prod.yml logs -f web
docker-compose -f docker-compose.prod.yml logs -f db
docker-compose -f docker-compose.prod.yml logs -f nginx
```

### Stop the application
```bash
docker-compose -f docker-compose.prod.yml down
```

### Restart the application
```bash
docker-compose -f docker-compose.prod.yml restart
```

### Access Rails console
```bash
docker-compose -f docker-compose.prod.yml exec web rails console
```

### Run database commands
```bash
# Run migrations
docker-compose -f docker-compose.prod.yml exec web bundle exec rails db:migrate

# Run seeds
docker-compose -f docker-compose.prod.yml exec web bundle exec rails db:seed

# Database console
docker-compose -f docker-compose.prod.yml exec web rails dbconsole
```

### Backup database
```bash
docker-compose -f docker-compose.prod.yml exec db pg_dump -U postgres pisoftsolutions_production > backup.sql
```

## 🔒 Security Features

### Production Dockerfile Features
- **Multi-stage build** for smaller image size
- **Non-root user** (rails:1000) for security
- **Alpine Linux** base for minimal attack surface
- **Production-only gems** (excludes development/test)

### Nginx Configuration Features
- **SSL/TLS encryption** with modern protocols
- **Security headers** (HSTS, XSS protection, etc.)
- **Rate limiting** for API and login endpoints
- **Gzip compression** for better performance
- **Static file caching** with immutable headers

### Environment Security
- **Environment variables** for sensitive data
- **Secret key base** generation
- **Database password** protection
- **API key** management

## 📊 Performance Optimizations

### Docker Optimizations
- **Multi-stage builds** reduce final image size
- **Layer caching** for faster builds
- **Alpine Linux** base image
- **Production-only dependencies**

### Rails Optimizations
- **Precompiled assets** in Docker build
- **Static file serving** enabled
- **Logging to stdout** for container logs
- **Database connection pooling**

### Nginx Optimizations
- **Gzip compression** for text files
- **Static file caching** with long expiration
- **Connection pooling** to Rails app
- **Rate limiting** to prevent abuse

## 🚨 Production Checklist

### Before Deployment
- [ ] Set secure passwords in `.env.production`
- [ ] Generate proper SSL certificates
- [ ] Configure Razorpay API keys
- [ ] Set up database backups
- [ ] Configure monitoring and logging
- [ ] Test all payment flows
- [ ] Verify admin user access

### After Deployment
- [ ] Test HTTPS redirects
- [ ] Verify SSL certificate
- [ ] Check application logs
- [ ] Test database connectivity
- [ ] Verify payment processing
- [ ] Monitor performance metrics
- [ ] Set up automated backups

## 🔧 Troubleshooting

### Common Issues

**SSL Certificate Errors**
```bash
# Regenerate certificates
rm -rf ssl/
./docker-setup-prod.sh
```

**Database Connection Issues**
```bash
# Check database logs
docker-compose -f docker-compose.prod.yml logs db

# Restart database
docker-compose -f docker-compose.prod.yml restart db
```

**Rails Application Errors**
```bash
# Check Rails logs
docker-compose -f docker-compose.prod.yml logs web

# Restart Rails app
docker-compose -f docker-compose.prod.yml restart web
```

**Nginx Issues**
```bash
# Check nginx logs
docker-compose -f docker-compose.prod.yml logs nginx

# Test nginx configuration
docker-compose -f docker-compose.prod.yml exec nginx nginx -t
```

### Performance Monitoring

**Check container resources:**
```bash
docker stats
```

**Monitor application performance:**
```bash
# Check response times
curl -w "@curl-format.txt" -o /dev/null -s https://localhost

# Monitor logs in real-time
docker-compose -f docker-compose.prod.yml logs -f --tail=100
```

## 📈 Scaling Considerations

### Horizontal Scaling
- Use external PostgreSQL service
- Implement Redis for session storage
- Use load balancer for multiple web instances
- Configure shared file storage

### Vertical Scaling
- Increase container memory limits
- Optimize database queries
- Use CDN for static assets
- Implement caching strategies

## 🔄 Deployment Workflow

### Development to Production
1. **Test in development environment**
2. **Update environment variables**
3. **Build production image**
4. **Deploy to staging (if available)**
5. **Run database migrations**
6. **Deploy to production**
7. **Monitor and verify**

### Zero-Downtime Deployment
```bash
# Blue-green deployment approach
docker-compose -f docker-compose.prod.yml up -d --scale web=2
docker-compose -f docker-compose.prod.yml up -d --no-deps web
```

## 📞 Support

For production deployment issues:
1. Check the logs: `docker-compose -f docker-compose.prod.yml logs -f`
2. Verify environment variables
3. Test database connectivity
4. Check SSL certificate validity
5. Monitor system resources

## 📁 File Structure

```
.
├── Dockerfile.prod              # Production Rails container
├── docker-compose.prod.yml      # Production orchestration
├── entrypoint.prod.sh          # Production startup script
├── nginx.conf                  # Nginx configuration
├── env.production.example      # Environment variables template
├── docker-setup-prod.sh        # Production setup script
├── ssl/                        # SSL certificates directory
│   ├── cert.pem               # SSL certificate
│   └── key.pem                # SSL private key
└── PRODUCTION_README.md       # This file
```
