# 🌐 DNS Setup Guide for pisoftsolutions.in

## 🎯 **Goal:**
Make your domain `pisoftsolutions.in` point to your server at `195.250.24.176:3000`

## 📋 **Required DNS Records:**

### **1. A Record (Root Domain)**
```
Type: A
Name: @ (or leave blank)
Value: 195.250.24.176
TTL: 300 (or default)
Priority: - (leave blank)
```

### **2. A Record (www Subdomain)**
```
Type: A
Name: www
Value: 195.250.24.176
TTL: 300 (or default)
Priority: - (leave blank)
```

### **3. CNAME Record (Alternative for www)**
```
Type: CNAME
Name: www
Value: pisoftsolutions.in
TTL: 300 (or default)
Priority: - (leave blank)
```

## 🔧 **Step-by-Step Instructions:**

### **Step 1: Access Your Domain Registrar**
Log into your domain registrar's control panel where you purchased `pisoftsolutions.in`

### **Step 2: Find DNS Management**
Look for:
- "DNS Management"
- "DNS Settings"
- "Name Servers"
- "DNS Records"

### **Step 3: Add DNS Records**
Add the records listed above in your DNS management panel.

### **Step 4: Wait for Propagation**
DNS changes can take:
- **Immediate to 5 minutes** (if using Cloudflare)
- **5-30 minutes** (most registrars)
- **Up to 48 hours** (rare cases)

## 🏢 **Common Domain Registrars:**

### **GoDaddy:**
1. Go to "My Products" → "DNS"
2. Click "Manage" next to your domain
3. Add A records as shown above

### **Namecheap:**
1. Go to "Domain List"
2. Click "Manage" next to your domain
3. Go to "Advanced DNS" tab
4. Add A records as shown above

### **Cloudflare:**
1. Go to "DNS" → "Records"
2. Add A records as shown above
3. Set proxy status to "Proxied" (orange cloud) for better performance

### **Google Domains:**
1. Go to "DNS" section
2. Add A records as shown above

## ✅ **Verification Steps:**

### **1. Check DNS Propagation:**
```bash
# Check if DNS is working
nslookup pisoftsolutions.in
dig pisoftsolutions.in
```

### **2. Test Domain Access:**
- Visit: http://pisoftsolutions.in
- Visit: http://www.pisoftsolutions.in
- Both should show your website

### **3. Check with Online Tools:**
- [whatsmydns.net](https://www.whatsmydns.net)
- [dnschecker.org](https://dnschecker.org)

## 🔒 **SSL Certificate Setup (After DNS is Working):**

Once your domain is pointing to your server, you can set up SSL:

### **1. Install Certbot:**
```bash
sudo apt update
sudo apt install certbot
```

### **2. Get SSL Certificate:**
```bash
sudo certbot certonly --webroot -w ./public -d pisoftsolutions.in -d www.pisoftsolutions.in
```

### **3. Restart Nginx:**
```bash
docker-compose restart nginx
```

## 🌐 **Expected Results:**

After DNS propagation:
- ✅ **http://pisoftsolutions.in** → Your website
- ✅ **http://www.pisoftsolutions.in** → Your website
- ✅ **https://pisoftsolutions.in** → Your website (after SSL setup)
- ✅ **https://www.pisoftsolutions.in** → Your website (after SSL setup)

## 🚨 **Troubleshooting:**

### **If Domain Doesn't Work:**

1. **Check DNS Propagation:**
   ```bash
   nslookup pisoftsolutions.in
   # Should return: 195.250.24.176
   ```

2. **Check Nginx Logs:**
   ```bash
   docker-compose logs nginx
   ```

3. **Verify Server is Running:**
   ```bash
   docker-compose ps
   ```

4. **Test Direct IP Access:**
   - http://195.250.24.176:3000 (should work)
   - http://195.250.24.176:80 (should work after DNS setup)

### **Common Issues:**

- **DNS not propagated yet** → Wait 5-30 minutes
- **Wrong DNS records** → Double-check A record values
- **Nginx not running** → `docker-compose up -d`
- **Firewall blocking** → Check server firewall settings

## 📞 **Support:**

If you need help with your specific domain registrar, provide:
1. Your domain registrar name
2. Screenshots of your DNS management panel
3. Any error messages you're seeing

## 🎉 **Success Indicators:**

You'll know it's working when:
- ✅ `nslookup pisoftsolutions.in` returns `195.250.24.176`
- ✅ `http://pisoftsolutions.in` shows your website
- ✅ `http://www.pisoftsolutions.in` shows your website
- ✅ No more need to use IP address directly

Your nginx configuration is already perfect for this setup! 🚀
