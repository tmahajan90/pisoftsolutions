# 🚀 Pisoft Solutions - One-Command Deployment

## 📋 Prerequisites

Before running the script, make sure you have:
- ✅ **Docker** installed and running
- ✅ **Git** installed
- ✅ **Bash** shell available

## 🎯 Quick Start

### **For Development:**
```bash
./run.sh dev
```

### **For Production:**
```bash
./run.sh prod
```

### **Show Help:**
```bash
./run.sh help
```

## 🎉 What Happens When You Run the Script

The script automatically:

1. **🔍 Checks Prerequisites**
   - Verifies Docker is running
   - Confirms all required files exist

2. **🐳 Sets Up Docker Environment**
   - Builds Docker images
   - Starts all services (web, database, redis)
   - Waits for services to be ready

3. **🗄️ Configures Database**
   - Runs database migrations
   - Seeds database with initial data
   - Creates admin and demo users

4. **🎨 Prepares Application**
   - Precompiles assets
   - Clears cache
   - Verifies application is running

5. **📱 Shows Access Information**
   - Displays URLs for accessing the application
   - Shows default login credentials
   - Provides useful management commands

## 🌐 Access Points

After running the script, you can access:

- **Main Application**: http://localhost:3000
- **Admin Panel**: http://localhost:3000/admin

## 🔑 Default Credentials

- **Admin User**: admin@shopease.com
- **Demo User**: demo@example.com / demo123

## 📝 Useful Commands

### **Stop Application:**
```bash
# Development
docker-compose down

# Production
docker-compose -f docker-compose.prod.yml down
```

### **View Logs:**
```bash
# Development
docker-compose logs -f web

# Production
docker-compose -f docker-compose.prod.yml logs -f web
```

### **Rails Console:**
```bash
# Development
docker-compose exec web rails console

# Production
docker-compose -f docker-compose.prod.yml exec web rails console
```

### **Restart Application:**
```bash
# Development
docker-compose restart web

# Production
docker-compose -f docker-compose.prod.yml restart web
```

## 🔄 Restarting the Application

To restart the application, simply run the script again:

```bash
./run.sh dev    # Restart development
./run.sh prod   # Restart production
```

## 🛠️ Troubleshooting

### **If Docker is not running:**
```bash
# Start Docker Desktop or Docker daemon
# Then run the script again
./run.sh dev
```

### **If ports are already in use:**
```bash
# Stop existing containers
docker-compose down

# Then run the script again
./run.sh dev
```

### **If database connection fails:**
```bash
# Wait a bit longer and try again
sleep 30
./run.sh dev
```

## 🎯 Production Deployment

For production deployment:

1. **Set Environment Variables:**
   ```bash
   export RAILS_ENV=production
   export SECRET_KEY_BASE=your_secret_key_here
   ```

2. **Run Production Script:**
   ```bash
   ./run.sh prod
   ```

3. **Configure Domain:**
   - Update your domain in the application
   - Configure SSL certificates
   - Set up reverse proxy if needed

## 📊 Monitoring

### **Check Application Health:**
```bash
curl http://localhost:3000/
```

### **Check Database:**
```bash
docker-compose exec web rails db:version
```

### **Check Redis:**
```bash
docker-compose exec web rails runner "puts Redis.new.ping"
```

## 🎉 Success!

Once the script completes successfully, your application will be fully functional with:

- ✅ **12 Products** with trial options
- ✅ **Admin Panel** for management
- ✅ **User Management** system
- ✅ **Order Processing** capabilities
- ✅ **Contact Management** system
- ✅ **Trial System** for customer acquisition

---

**💡 Tip**: This script handles everything automatically. Just run it and your application will be ready to use!
