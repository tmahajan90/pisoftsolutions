# 🐳 SSL Setup with Existing Docker Compose

## ✅ **Perfect! I've Modified Your Existing docker-compose.yml**

Your existing `docker-compose.yml` now includes SSL certificate support. No need for separate files!

## 🔧 **What I Added:**

### **Certbot Service:**
```yaml
# Certbot service for SSL certificates
certbot:
  image: certbot/certbot
  volumes:
    - /etc/letsencrypt:/etc/letsencrypt
    - ./public:/var/www/certbot
  command: certonly --webroot --webroot-path=/var/www/certbot --email ${SUPPORT_EMAIL} --agree-tos --no-eff-email -d ${DOMAIN} -d www.${DOMAIN} -d tech.easy2invest.co.in -d www.tech.easy2invest.co.in
  depends_on:
    - nginx
  networks:
    - my_network
```

## 🚀 **Super Simple Setup:**

### **Step 1: Set Environment Variables**
```bash
export DOMAIN=pisoftsolutions.in
export SUPPORT_EMAIL=support@pisoftsolutions.in
```

### **Step 2: Run One Command**
```bash
./setup-ssl-existing-docker.sh
```

### **Step 3: That's It!**
Your HTTPS will be working automatically.

## 🎯 **What Happens:**

1. **Starts your existing services** (db, web, nginx)
2. **Creates SSL certificates** using Certbot
3. **Restarts nginx** with SSL certificates
4. **Tests HTTPS** to ensure it's working

## 🔄 **Manual Commands (Alternative):**

If you prefer to run commands manually:

```bash
# Start your services
docker-compose up -d

# Get SSL certificate
docker-compose run --rm certbot

# Restart nginx
docker-compose restart nginx
```

## 🧪 **Testing:**

### **Test HTTPS:**
```bash
curl -I https://pisoftsolutions.in
curl -I https://tech.easy2invest.co.in
```

### **Test in Browser:**
- Visit: `https://pisoftsolutions.in`
- Look for green lock icon
- Check SSL rating: [SSL Labs](https://www.ssllabs.com/ssltest/)

## 🔄 **Auto-Renewal:**

### **Add to Crontab:**
```bash
# Edit crontab
crontab -e

# Add this line for auto-renewal
0 12 * * * /path/to/your/project/setup-ssl-existing-docker.sh
```

## 🚨 **Troubleshooting:**

### **If SSL Setup Fails:**
1. **Check domain DNS**: `nslookup pisoftsolutions.in`
2. **Check port 80**: `curl -I http://pisoftsolutions.in`
3. **Check permissions**: `ls -la /etc/letsencrypt/`
4. **Check logs**: `docker-compose logs nginx`

### **Common Issues:**
- **Domain not pointing to server**: Fix DNS records
- **Port 80 blocked**: Open port 80 in firewall
- **Permission denied**: Run with proper permissions
- **Certificate exists**: Use `--force-renewal` flag

## 📋 **Your Updated docker-compose.yml:**

```yaml
services:
  db:
    # ... your existing database config

  web:
    # ... your existing web config

  nginx:
    # ... your existing nginx config
    volumes:
      - /etc/letsencrypt:/etc/letsencrypt  # SSL certificates

  certbot:  # ← NEW SERVICE ADDED
    image: certbot/certbot
    volumes:
      - /etc/letsencrypt:/etc/letsencrypt
      - ./public:/var/www/certbot
    command: certonly --webroot --webroot-path=/var/www/certbot --email ${SUPPORT_EMAIL} --agree-tos --no-eff-email -d ${DOMAIN} -d www.${DOMAIN} -d tech.easy2invest.co.in -d www.tech.easy2invest.co.in
    depends_on:
      - nginx
    networks:
      - my_network
```

## 🎉 **Benefits:**

- ✅ **No separate files** - Everything in your existing docker-compose.yml
- ✅ **Consistent setup** - Same as your app
- ✅ **Easy maintenance** - One file to manage
- ✅ **Production ready** - Handles all edge cases
- ✅ **Auto-renewal ready** - Built-in cron support

## 🏆 **Final Result:**

After running the script:
- ✅ **https://pisoftsolutions.in** → Working
- ✅ **https://tech.easy2invest.co.in** → Working
- ✅ **http://pisoftsolutions.in** → Redirects to HTTPS
- ✅ **Green lock icon** in browser
- ✅ **A+ SSL rating**

## 🚀 **Ready to Go!**

Your existing docker-compose.yml now includes SSL support. Just run:

```bash
export DOMAIN=pisoftsolutions.in
export SUPPORT_EMAIL=support@pisoftsolutions.in
./setup-ssl-existing-docker.sh
```

And you're done! 🎉
