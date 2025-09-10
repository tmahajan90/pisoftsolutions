# 🔒 Quick HTTPS Setup Guide

## 🎯 **Goal:**
Enable HTTPS for your websites with SSL certificates.

## 🚀 **Quick Setup (3 Steps):**

### **Step 1: Install Certbot**
```bash
sudo apt update
sudo apt install certbot
```

### **Step 2: Get SSL Certificate**
```bash
sudo certbot certonly --webroot -w ./public \
  -d pisoftsolutions.in \
  -d www.pisoftsolutions.in \
  -d tech.easy2invest.co.in \
  -d www.tech.easy2invest.co.in
```

### **Step 3: Restart Nginx**
```bash
docker-compose restart nginx
```

## ✅ **That's It!**

Your websites will now be available at:
- ✅ **https://pisoftsolutions.in**
- ✅ **https://www.pisoftsolutions.in**
- ✅ **https://tech.easy2invest.co.in**
- ✅ **https://www.tech.easy2invest.co.in**

## 🔄 **HTTP to HTTPS Redirect:**
- ✅ **http://pisoftsolutions.in** → **https://pisoftsolutions.in**
- ✅ **http://tech.easy2invest.co.in** → **https://tech.easy2invest.co.in**

## 🧪 **Test HTTPS:**
```bash
# Test in browser
https://pisoftsolutions.in
https://tech.easy2invest.co.in

# Test with curl
curl -I https://pisoftsolutions.in
```

## 🔒 **SSL Certificate Details:**
- **Provider**: Let's Encrypt (Free)
- **Validity**: 90 days
- **Auto-renewal**: Recommended

## 📅 **Auto-Renewal Setup:**
```bash
# Add to crontab
sudo crontab -e

# Add this line:
0 12 * * * /usr/bin/certbot renew --quiet && docker-compose restart nginx
```

## 🎉 **Success Indicators:**
- ✅ **Green lock icon** in browser
- ✅ **https://** URLs work
- ✅ **No SSL warnings**
- ✅ **Fast loading times**

Your website is now secure with HTTPS! 🔒🌟
