# 🔒 SSL Setup Guide for PiSoftSolutions

## Quick Start

### Automatic SSL Setup (Recommended)

1. **Set environment variables in `.env`:**
```bash
FORCE_SSL=true
DOMAIN=pisoftsolutions.in
SUPPORT_EMAIL=support@pisoftsolutions.in
```

2. **Run the setup:**
```bash
RAILS_ENV=production ./docker-setup.sh
```

SSL will be automatically configured if `FORCE_SSL=true`!

### Manual SSL Setup

If you prefer manual control:

```bash
# Generate SSL certificates
./setup-ssl.sh

# Renew certificates
./renew-ssl.sh

# Auto-detect and setup SSL
./auto-ssl-setup.sh
```

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `FORCE_SSL` | Enable automatic SSL setup | `true` or `false` |
| `DOMAIN` | Your primary domain | `pisoftsolutions.in` |
| `SUPPORT_EMAIL` | Email for Let's Encrypt | `support@pisoftsolutions.in` |

## Features

- ✅ **Automatic SSL detection** based on `FORCE_SSL` variable
- ✅ **Let's Encrypt certificates** with auto-renewal
- ✅ **HTTP to HTTPS redirects**
- ✅ **Modern SSL configuration** (TLS 1.2/1.3)
- ✅ **Security headers** (HSTS, XSS protection, etc.)
- ✅ **A+ SSL rating**

## URLs

After SSL setup, your site will be available at:
- `https://pisoftsolutions.in`
- `https://www.pisoftsolutions.in`
- `https://tech.easy2invest.co.in`
- `https://www.tech.easy2invest.co.in`

All HTTP traffic automatically redirects to HTTPS.

## Troubleshooting

### Common Issues

1. **Domain not pointing to server**
   ```bash
   nslookup pisoftsolutions.in
   ```

2. **Port 80 not accessible**
   ```bash
   curl -I http://pisoftsolutions.in
   sudo ufw allow 80
   ```

3. **Check SSL certificate**
   ```bash
   openssl s_client -connect pisoftsolutions.in:443 -servername pisoftsolutions.in
   ```

### Logs

```bash
# View nginx logs
docker-compose logs nginx

# View certbot logs
docker-compose logs certbot
```

## Certificate Renewal

Certificates auto-renew every 60 days. Manual renewal:

```bash
./renew-ssl.sh
```

## Security

- **A+ SSL Rating** with modern TLS
- **HSTS** (HTTP Strict Transport Security)
- **Security headers** for XSS protection
- **Automatic HTTP→HTTPS redirects**
