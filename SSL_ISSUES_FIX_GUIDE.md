# 🔧 SSL Certificate Issues Fix Guide

## 🚨 **Issues Identified:**

### **1. tech.easy2invest.co.in - Connection Refused**
- **Problem**: Port 80 not accessible
- **Error**: `Connection refused`

### **2. www.tech.easy2invest.co.in - DNS NXDOMAIN**
- **Problem**: DNS record missing
- **Error**: `DNS problem: NXDOMAIN looking up A for www.tech.easy2invest.co.in`

### **3. pisoftsolutions.in - 404 Error**
- **Problem**: Webroot path not accessible
- **Error**: `Invalid response from https://pisoftsolutions.in/.well-known/acme-challenge/`

### **4. www.pisoftsolutions.in - 404 Error**
- **Problem**: Webroot path not accessible
- **Error**: `Invalid response from https://www.pisoftsolutions.in/.well-known/acme-challenge/`

## 🔧 **Step-by-Step Fixes:**

### **Fix 1: DNS Records**

#### **For www.tech.easy2invest.co.in:**
Add this DNS record in GoDaddy:
```
Type: A
Name: www.tech
Value: 195.250.24.176
TTL: 600
```

#### **For pisoftsolutions.in:**
Ensure these DNS records exist:
```
Type: A
Name: @
Value: 195.250.24.176

Type: A
Name: www
Value: 195.250.24.176
```

### **Fix 2: Port 80 Access**

#### **Check if port 80 is open:**
```bash
# Test locally
curl -I http://localhost:80

# Test externally
curl -I http://195.250.24.176:80
```

#### **Open port 80 if blocked:**
```bash
# If using ufw
sudo ufw allow 80

# If using iptables
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
```

### **Fix 3: Webroot Access**

#### **Create webroot directory:**
```bash
mkdir -p ./public/.well-known/acme-challenge
chmod 755 ./public/.well-known/acme-challenge
```

#### **Test webroot access:**
```bash
# Create test file
echo "test" > ./public/.well-known/acme-challenge/test

# Test access
curl -I http://pisoftsolutions.in/.well-known/acme-challenge/test
curl -I http://tech.easy2invest.co.in/.well-known/acme-challenge/test

# Remove test file
rm ./public/.well-known/acme-challenge/test
```

### **Fix 4: Nginx Configuration**

#### **Check nginx configuration:**
```bash
docker-compose exec nginx nginx -t
```

#### **Restart nginx:**
```bash
docker-compose restart nginx
```

## 🚀 **Quick Fix Script:**

Run this script to fix most issues:
```bash
sudo ./fix-ssl-issues.sh
```

## 🔄 **Retry SSL Certificate Generation:**

### **After fixing issues, retry:**
```bash
# Set environment variables
export DOMAIN=pisoftsolutions.in
export SUPPORT_EMAIL=support@pisoftsolutions.in

# Retry SSL certificate generation
docker-compose run --rm certbot
```

### **Or use force renewal:**
```bash
docker-compose run --rm certbot certonly --webroot --webroot-path=/var/www/certbot --email ${SUPPORT_EMAIL} --agree-tos --no-eff-email --force-renewal -d ${DOMAIN} -d www.${DOMAIN} -d tech.easy2invest.co.in
```

## 🧪 **Testing:**

### **Test each domain:**
```bash
# Test HTTP access
curl -I http://pisoftsolutions.in
curl -I http://www.pisoftsolutions.in
curl -I http://tech.easy2invest.co.in
curl -I http://www.tech.easy2invest.co.in

# Test webroot access
curl -I http://pisoftsolutions.in/.well-known/acme-challenge/
curl -I http://tech.easy2invest.co.in/.well-known/acme-challenge/
```

### **Test in browser:**
- Visit: `http://pisoftsolutions.in`
- Visit: `http://tech.easy2invest.co.in`
- Check if both show your website

## 🚨 **Troubleshooting:**

### **If port 80 is still not accessible:**
1. **Check firewall**: `sudo ufw status`
2. **Check nginx logs**: `docker-compose logs nginx`
3. **Check if nginx is running**: `docker-compose ps`

### **If DNS is still not working:**
1. **Wait for DNS propagation**: 5-30 minutes
2. **Check DNS with different tools**: `nslookup`, `dig`
3. **Contact GoDaddy support** if needed

### **If webroot is still not accessible:**
1. **Check nginx configuration**: `docker-compose exec nginx nginx -t`
2. **Check file permissions**: `ls -la ./public/.well-known/`
3. **Check nginx logs**: `docker-compose logs nginx`

## 📋 **Complete Fix Checklist:**

- [ ] **DNS Records**: All domains point to 195.250.24.176
- [ ] **Port 80**: Open and accessible
- [ ] **Webroot Directory**: Created and accessible
- [ ] **Nginx**: Running and configured correctly
- [ ] **HTTP Access**: All domains accessible via HTTP
- [ ] **Webroot Access**: /.well-known/acme-challenge/ accessible

## 🎯 **Expected Results:**

After fixes:
- ✅ **http://pisoftsolutions.in** → Your website
- ✅ **http://www.pisoftsolutions.in** → Your website
- ✅ **http://tech.easy2invest.co.in** → Your website
- ✅ **http://www.tech.easy2invest.co.in** → Your website
- ✅ **SSL certificate generation** → Success

## 🚀 **Next Steps:**

1. **Fix DNS records** in GoDaddy
2. **Ensure port 80 is open**
3. **Run the fix script**: `sudo ./fix-ssl-issues.sh`
4. **Retry SSL certificate generation**
5. **Test HTTPS access**

Your SSL certificates will work once these issues are resolved! 🔒
