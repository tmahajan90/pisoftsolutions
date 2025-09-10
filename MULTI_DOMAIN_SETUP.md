# 🌐 Multi-Domain Setup Guide

## 🎯 **Overview:**
Configure your Rails application to accept requests from multiple domains. This allows you to have different domains pointing to the same application.

## 🏗️ **Architecture:**
```
Domain 1 (pisoftsolutions.in) ──┐
Domain 2 (example.com) ─────────┼──▶ Your Rails App
Domain 3 (another.com) ─────────┘    (Same content, different domains)
```

## 📋 **Configuration Steps:**

### **1. Add Additional Domains to Environment**

#### **Method A: Using the Setup Script (Recommended)**
```bash
./setup-multiple-domains.sh
```

#### **Method B: Manual Configuration**
Add to your `.env` file:
```bash
# Primary domain
DOMAIN=pisoftsolutions.in

# Additional domains (comma-separated)
ADDITIONAL_DOMAINS=example.com,another.com,third-domain.com
```

### **2. Update Nginx Configuration**

The nginx configuration will automatically include all domains:
```nginx
server_name pisoftsolutions.in www.pisoftsolutions.in example.com www.example.com another.com www.another.com;
```

### **3. DNS Configuration**

For each domain, add these DNS records:

#### **Domain 1: pisoftsolutions.in**
```
Type: A
Name: @
Value: 195.250.24.176

Type: A
Name: www
Value: 195.250.24.176
```

#### **Domain 2: example.com**
```
Type: A
Name: @
Value: 195.250.24.176

Type: A
Name: www
Value: 195.250.24.176
```

#### **Domain 3: another.com**
```
Type: A
Name: @
Value: 195.250.24.176

Type: A
Name: www
Value: 195.250.24.176
```

## 🔧 **Rails Configuration:**

### **Development Environment:**
```ruby
# config/environments/development.rb
config.hosts << ENV['DOMAIN'] if ENV['DOMAIN'].present?
config.hosts << "www.#{ENV['DOMAIN']}" if ENV['DOMAIN'].present?

# Additional domains
if ENV['ADDITIONAL_DOMAINS'].present?
  ENV['ADDITIONAL_DOMAINS'].split(',').each do |domain|
    domain = domain.strip
    config.hosts << domain
    config.hosts << "www.#{domain}" unless domain.start_with?('www.')
  end
end
```

### **Production Environment:**
```ruby
# config/environments/production.rb
# Same configuration as development
```

## 🚀 **Usage Examples:**

### **Example 1: Add a Single Domain**
```bash
./setup-multiple-domains.sh
# Choose option 2
# Enter: example.com
```

### **Example 2: Add Multiple Domains**
```bash
# Edit .env file manually
ADDITIONAL_DOMAINS=example.com,another.com,third-domain.com
```

### **Example 3: Complete Setup**
```bash
./setup-multiple-domains.sh
# Choose option 5
# Enter: example.com
# This will: add domain + update nginx + restart services
```

## ✅ **Verification:**

### **1. Check Current Domains:**
```bash
./setup-multiple-domains.sh
# Choose option 1
```

### **2. Test Domain Access:**
```bash
# Test each domain
curl -I http://pisoftsolutions.in
curl -I http://example.com
curl -I http://another.com
```

### **3. Check Rails Logs:**
```bash
docker-compose logs web | grep "Blocked hosts"
# Should show no blocked hosts errors
```

## 🔒 **SSL Certificate Setup:**

### **For Multiple Domains:**
```bash
# Get SSL certificate for all domains
sudo certbot certonly --webroot -w ./public \
  -d pisoftsolutions.in \
  -d www.pisoftsolutions.in \
  -d example.com \
  -d www.example.com \
  -d another.com \
  -d www.another.com
```

### **Update Nginx SSL Configuration:**
```nginx
server {
    listen 443 ssl;
    server_name pisoftsolutions.in www.pisoftsolutions.in example.com www.example.com another.com www.another.com;
    
    ssl_certificate /etc/letsencrypt/live/pisoftsolutions.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/pisoftsolutions.in/privkey.pem;
    
    # ... rest of SSL configuration
}
```

## 📊 **Benefits of Multi-Domain Setup:**

### **1. Brand Flexibility:**
- Use different domains for different markets
- Redirect old domains to new ones
- A/B testing with different domains

### **2. SEO Benefits:**
- Multiple entry points to your site
- Domain authority distribution
- Localized domains for different regions

### **3. Business Benefits:**
- Acquire competitors' domains
- Use domain names that match your business
- Create memorable URLs for different services

## 🚨 **Troubleshooting:**

### **Common Issues:**

#### **1. "Blocked hosts" Error:**
```bash
# Check if domain is in .env file
grep -E "DOMAIN|ADDITIONAL_DOMAINS" .env

# Restart services
docker-compose restart web
```

#### **2. Domain Not Working:**
```bash
# Check DNS propagation
nslookup yourdomain.com

# Check nginx configuration
docker-compose logs nginx
```

#### **3. SSL Certificate Issues:**
```bash
# Check certificate
sudo certbot certificates

# Renew certificate
sudo certbot renew
```

## 📚 **File Structure:**

```
├── .env                          # Domain configuration
├── config/environments/
│   ├── development.rb            # Development domain config
│   └── production.rb             # Production domain config
├── nginx.conf                    # Nginx multi-domain config
├── setup-multiple-domains.sh     # Domain management script
└── MULTI_DOMAIN_SETUP.md         # This guide
```

## 🎉 **Quick Start:**

1. **Add your first additional domain:**
   ```bash
   ./setup-multiple-domains.sh
   ```

2. **Configure DNS records** for the new domain

3. **Set up SSL certificate** for all domains

4. **Test all domains** to ensure they work

Your Rails application now supports multiple domains! 🌟
