# Docker Setup for Pisoft Solutions Rails App

This document provides instructions for running the Pisoft Solutions Rails application using Docker.

## Prerequisites

- Docker Desktop installed and running
- Docker Compose (usually comes with Docker Desktop)

## Quick Start

### Option 1: Using the setup script (Recommended)

```bash
./docker-setup.sh
```

This script will:
- Build the Docker images
- Start the containers
- Set up the database
- Run migrations and seed data

### Option 2: Manual setup

1. **Build and start the containers:**
   ```bash
   docker-compose up --build -d
   ```

2. **Wait for the database to be ready (about 10-15 seconds)**

3. **Set up the database:**
   ```bash
   docker-compose exec web bundle exec rails db:create db:migrate db:seed
   ```

## Accessing the Application

- **Rails Application:** http://localhost:3000
- **Database:** localhost:5432 (PostgreSQL)

## Useful Commands

### View logs
```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f web
docker-compose logs -f db
```

### Stop the application
```bash
docker-compose down
```

### Restart the application
```bash
docker-compose restart
```

### Access Rails console
```bash
docker-compose exec web rails console
```

### Access database console
```bash
docker-compose exec web rails dbconsole
```

### Run Rails commands
```bash
# Run migrations
docker-compose exec web bundle exec rails db:migrate

# Run seeds
docker-compose exec web bundle exec rails db:seed

# Run tests
docker-compose exec web bundle exec rails test
```

### Rebuild containers
```bash
docker-compose down
docker-compose up --build -d
```

## Environment Variables

The application uses the following environment variables (configured in docker-compose.yml):

- `RAILS_ENV`: development
- `POSTGRES_HOST`: db
- `POSTGRES_PORT`: 5432
- `POSTGRES_USER`: postgres
- `POSTGRES_PASSWORD`: password
- `POSTGRES_DB`: pisoftsolutions_development

## Troubleshooting

### Port already in use
If you get an error about ports being in use, you can:
1. Stop any existing Rails server: `pkill -f rails`
2. Stop any existing PostgreSQL service
3. Or change the ports in `docker-compose.yml`

### Database connection issues
If the database connection fails:
1. Check if the database container is running: `docker-compose ps`
2. Check database logs: `docker-compose logs db`
3. Restart the containers: `docker-compose restart`

### Permission issues
If you encounter permission issues:
```bash
sudo chown -R $USER:$USER .
```

## Development Workflow

1. **Start the environment:**
   ```bash
   docker-compose up -d
   ```

2. **Make changes to your code** (the app directory is mounted as a volume)

3. **Restart the web service if needed:**
   ```bash
   docker-compose restart web
   ```

4. **View logs to debug:**
   ```bash
   docker-compose logs -f web
   ```

## Production Considerations

For production deployment, you should:
- Use environment-specific Dockerfiles
- Set up proper environment variables
- Configure SSL/TLS
- Set up proper database backups
- Use a reverse proxy (nginx)
- Configure proper logging

## File Structure

```
.
├── Dockerfile              # Rails application container
├── docker-compose.yml      # Multi-container orchestration
├── entrypoint.sh          # Container startup script
├── .dockerignore          # Files to exclude from build
├── docker-setup.sh        # Quick setup script
└── DOCKER_README.md       # This file
```
