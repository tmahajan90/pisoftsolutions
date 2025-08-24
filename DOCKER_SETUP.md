# 🐳 Docker Setup for Pisoft Solutions

This guide will help you set up and run the Pisoft Solutions Rails application using Docker.

## 📋 Prerequisites

- Docker Desktop installed on your machine
- Docker Compose (usually comes with Docker Desktop)
- Git

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/tmahajan90/pisoftsolutions.git
cd pisoftsolutions
```

### 2. Set Up Environment Variables
Create a `.env` file in the project root:
```bash
# Copy the example file
cp env_example.txt .env

# Edit the file with your actual values
nano .env
```

Add your Razorpay API keys:
```bash
RAZORPAY_KEY_ID=your_actual_razorpay_key_id
RAZORPAY_KEY_SECRET=your_actual_razorpay_key_secret
```

### 3. Build and Start the Application
```bash
# Build and start all services
docker-compose up --build

# Or run in background
docker-compose up -d --build
```

### 4. Access the Application
- **Rails App**: http://localhost:3000
- **Database**: localhost:5432
- **Redis**: localhost:6379

## 🛠️ Development Commands

### Start Services
```bash
# Start all services
docker-compose up

# Start in background
docker-compose up -d

# Start only specific services
docker-compose up db redis
```

### Stop Services
```bash
# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: This will delete all data)
docker-compose down -v
```

### View Logs
```bash
# View all logs
docker-compose logs

# View specific service logs
docker-compose logs web
docker-compose logs db

# Follow logs in real-time
docker-compose logs -f web
```

### Database Operations
```bash
# Run migrations
docker-compose exec web rails db:migrate

# Reset database
docker-compose exec web rails db:reset

# Seed database
docker-compose exec web rails db:seed

# Access database console
docker-compose exec web rails dbconsole
```

### Rails Console
```bash
# Access Rails console
docker-compose exec web rails console

# Run Rails commands
docker-compose exec web rails routes
docker-compose exec web rails generate model User
```

### Bundle Operations
```bash
# Install new gems
docker-compose exec web bundle install

# Add new gem to Gemfile
# Edit Gemfile, then run:
docker-compose exec web bundle install
```

## 🏗️ Production Deployment

### 1. Set Up Production Environment
Create a `.env.production` file:
```bash
POSTGRES_DB=pisoftsolutions_production
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_secure_password
RAZORPAY_KEY_ID=your_live_razorpay_key_id
RAZORPAY_KEY_SECRET=your_live_razorpay_key_secret
RAILS_MASTER_KEY=your_rails_master_key
```

### 2. Build Production Image
```bash
# Build production image
docker build -t pisoftsolutions:latest .

# Or use docker-compose
docker-compose -f docker-compose.prod.yml build
```

### 3. Deploy
```bash
# Deploy with docker-compose
docker-compose -f docker-compose.prod.yml up -d

# Or run individual containers
docker run -d \
  --name pisoftsolutions-web \
  -p 3000:3000 \
  --env-file .env.production \
  pisoftsolutions:latest
```

## 🔧 Configuration

### Environment Variables
The application uses these environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `RAILS_ENV` | Rails environment | `development` |
| `DATABASE_URL` | PostgreSQL connection string | Auto-generated |
| `REDIS_URL` | Redis connection string | `redis://redis:6379/0` |
| `RAZORPAY_KEY_ID` | Razorpay API Key ID | Test key |
| `RAZORPAY_KEY_SECRET` | Razorpay API Key Secret | Test key |
| `RAILS_MASTER_KEY` | Rails master key (production) | Required for production |

### Database Configuration
The application uses PostgreSQL with these default settings:
- **Host**: `db` (Docker service name)
- **Port**: `5432`
- **Database**: `pisoftsolutions_development`
- **Username**: `postgres`
- **Password**: `password`

### Redis Configuration
Redis is used for caching and sessions:
- **Host**: `redis` (Docker service name)
- **Port**: `6379`
- **Database**: `0`

## 🐛 Troubleshooting

### Common Issues

#### 1. Port Already in Use
```bash
# Check what's using the port
lsof -i :3000

# Kill the process or change the port in docker-compose.yml
```

#### 2. Database Connection Issues
```bash
# Check if database is running
docker-compose ps db

# Restart database
docker-compose restart db

# Check database logs
docker-compose logs db
```

#### 3. Permission Issues
```bash
# Fix file permissions
sudo chown -R $USER:$USER .

# Or run with proper permissions
docker-compose exec web chown -R rails:rails /app
```

#### 4. Build Issues
```bash
# Clean build cache
docker-compose build --no-cache

# Remove all containers and images
docker-compose down --rmi all --volumes --remove-orphans
```

### Debugging Commands
```bash
# Check container status
docker-compose ps

# Check container resources
docker stats

# Access container shell
docker-compose exec web bash

# Check application logs
docker-compose logs -f web

# Check database logs
docker-compose logs -f db
```

## 📁 File Structure

```
pisoftsolutions/
├── Dockerfile              # Production Dockerfile
├── Dockerfile.dev          # Development Dockerfile
├── docker-compose.yml      # Development services
├── docker-compose.prod.yml # Production services
├── entrypoint.sh           # Container entrypoint script
├── .dockerignore           # Files to exclude from build
├── .env                    # Environment variables (not in git)
├── env_example.txt         # Environment variables template
└── DOCKER_SETUP.md         # This file
```

## 🔒 Security Notes

- Never commit `.env` files to version control
- Use strong passwords for production databases
- Keep Docker images updated
- Use secrets management in production
- Enable HTTPS in production

## 🚀 Next Steps

1. **Set up CI/CD pipeline** for automated deployments
2. **Configure monitoring** and logging
3. **Set up backup strategy** for database
4. **Configure SSL certificates** for production
5. **Set up load balancing** for high availability

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Rails Docker Guide](https://guides.rubyonrails.org/development_dependencies_install.html#docker)
- [PostgreSQL Docker Image](https://hub.docker.com/_/postgres)
- [Redis Docker Image](https://hub.docker.com/_/redis)
