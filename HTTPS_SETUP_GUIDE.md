# 🔒 HTTPS Setup Guide for PiSoftSolutions

## 🎯 **Goal:**
Enable HTTPS (SSL) for your websites:
- `https://pisoftsolutions.in`
- `https://www.pisoftsolutions.in`
- `https://tech.easy2invest.co.in`

## 📋 **Prerequisites:**
- ✅ Domain pointing to your server (195.250.24.176)
- ✅ Nginx configured for SSL
- ✅ Port 443 open on your server

## 🔧 **Step 1: Install Certbot**

### **On Your Server:**
```bash
# Update system
sudo apt update

# Install Certbot
sudo apt install certbot

# Install nginx plugin (if needed)
sudo apt install python3-certbot-nginx
```

## 🔧 **Step 2: Get SSL Certificates**

### **For pisoftsolutions.in:**
```bash
sudo certbot certonly --webroot -w ./public \
  -d pisoftsolutions.in \
  -d www.pisoftsolutions.in
```

### **For tech.easy2invest.co.in:**
```bash
sudo certbot certonly --webroot -w ./public \
  -d tech.easy2invest.co.in \
  -d www.tech.easy2invest.co.in
```

### **For All Domains (Combined):**
```bash
sudo certbot certonly --webroot -w ./public \
  -d pisoftsolutions.in \
  -d www.pisoftsolutions.in \
  -d tech.easy2invest.co.in \
  -d www.tech.easy2invest.co.in
```

## 🔧 **Step 3: Update Nginx Configuration**

Your nginx.conf already has SSL configuration, but let me add HTTP to HTTPS redirect:

### **Add HTTP to HTTPS Redirect:**
```nginx
# HTTP to HTTPS redirect
server {
    listen 80;
    server_name pisoftsolutions.in www.pisoftsolutions.in tech.easy2invest.co.in www.tech.easy2invest.co.in;
    return 301 https://$server_name$request_uri;
}
```

## 🔧 **Step 4: Restart Services**

```bash
# Restart nginx
docker-compose restart nginx

# Or restart all services
docker-compose restart
```

## 🧪 **Step 5: Test HTTPS**

### **Test SSL Certificate:**
```bash
# Test certificate
sudo certbot certificates

# Test HTTPS access
curl -I https://pisoftsolutions.in
curl -I https://tech.easy2invest.co.in
```

### **Test in Browser:**
- Visit: `https://pisoftsolutions.in`
- Visit: `https://tech.easy2invest.co.in`
- Look for the lock icon in the address bar

## 🔧 **Step 6: Auto-Renewal Setup**

### **Test Auto-Renewal:**
```bash
sudo certbot renew --dry-run
```

### **Set up Cron Job:**
```bash
# Edit crontab
sudo crontab -e

# Add this line for auto-renewal
0 12 * * * /usr/bin/certbot renew --quiet
```

## 📋 **Complete nginx.conf SSL Configuration:**

```nginx
# HTTP to HTTPS redirect
server {
    listen 80;
    server_name pisoftsolutions.in www.pisoftsolutions.in tech.easy2invest.co.in www.tech.easy2invest.co.in;
    return 301 https://$server_name$request_uri;
}

# HTTPS server
server {
    listen 443 ssl;
    server_name pisoftsolutions.in www.pisoftsolutions.in tech.easy2invest.co.in www.tech.easy2invest.co.in;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/pisoftsolutions.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/pisoftsolutions.in/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/pisoftsolutions.in/chain.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Your application
    location / {
        proxy_pass http://web:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 🚨 **Troubleshooting:**

### **1. Certificate Not Found:**
```bash
# Check certificate location
sudo ls -la /etc/letsencrypt/live/

# Check certificate files
sudo ls -la /etc/letsencrypt/live/pisoftsolutions.in/
```

### **2. Permission Issues:**
```bash
# Fix permissions
sudo chown -R root:root /etc/letsencrypt/
sudo chmod -R 755 /etc/letsencrypt/
```

### **3. Nginx SSL Error:**
```bash
# Test nginx configuration
sudo nginx -t

# Check nginx logs
docker-compose logs nginx
```

### **4. Port 443 Not Open:**
```bash
# Check if port 443 is open
sudo netstat -tlnp | grep :443

# Open port 443 (if using ufw)
sudo ufw allow 443
```

## ✅ **Expected Results:**

After setup:
- ✅ **https://pisoftsolutions.in** → Your website with SSL
- ✅ **https://www.pisoftsolutions.in** → Your website with SSL
- ✅ **https://tech.easy2invest.co.in** → Your website with SSL
- ✅ **http://pisoftsolutions.in** → Redirects to HTTPS
- ✅ **Green lock icon** in browser address bar
- ✅ **A+ SSL rating** on SSL Labs

## 🔄 **Auto-Renewal:**

Certificates expire every 90 days. Set up auto-renewal:

```bash
# Add to crontab
0 12 * * * /usr/bin/certbot renew --quiet && docker-compose restart nginx
```

## 🎉 **Success Indicators:**

- ✅ **HTTPS URLs** work in browser
- ✅ **Lock icon** appears in address bar
- ✅ **HTTP redirects** to HTTPS
- ✅ **No SSL warnings** in browser
- ✅ **Fast loading** times

Your website will be secure with HTTPS! 🔒🌟
