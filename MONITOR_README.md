# PiSoft Solutions - 24/7 Docker Container Monitor

This monitoring system ensures your Docker containers stay running 24/7 by automatically detecting when they stop and restarting them.

## 📁 Files Created

- `monitor.sh` - Main monitoring script
- `start-monitor.sh` - Simple monitor starter (for macOS/Linux)
- `install-monitor.sh` - Systemd service installer (for Linux)
- `pisoftsolutions-monitor.service` - Systemd service file
- `MONITOR_README.md` - This documentation

## 🚀 Quick Start

### Option 1: Simple Background Monitoring (Recommended for macOS)

```bash
# Start monitoring in background
./start-monitor.sh start

# Check status
./start-monitor.sh status

# View logs
./start-monitor.sh logs

# Stop monitoring
./start-monitor.sh stop
```

### Option 2: Systemd Service (Linux)

```bash
# Install as system service (requires sudo)
sudo ./install-monitor.sh install

# Start the service
sudo ./install-monitor.sh start

# Check status
sudo ./install-monitor.sh status

# View logs
sudo ./install-monitor.sh logs

# Stop service
sudo ./install-monitor.sh stop
```

## 🔧 How It Works

The monitoring system:

1. **Checks every 30 seconds** if your Docker containers are running
2. **Monitors both web and database containers** specifically
3. **Performs health checks** on the application (HTTP 200 response)
4. **Automatically restarts** containers if they stop
5. **Implements restart limits** to prevent infinite restart loops
6. **Logs all activities** for debugging and monitoring
7. **Sends notifications** when containers restart or fail

## ⚙️ Configuration

### Monitor Settings (in `monitor.sh`)

```bash
CHECK_INTERVAL=30          # Check every 30 seconds
MAX_RESTART_ATTEMPTS=5     # Maximum restart attempts
RESTART_COOLDOWN=300       # 5 minutes between restart attempts
```

### Customization

You can modify these settings in `monitor.sh`:

- **Check Interval**: How often to check container status
- **Max Restart Attempts**: Prevent infinite restart loops
- **Restart Cooldown**: Wait time between restart attempts
- **Notification Settings**: Add email/Slack notifications

## 📊 Monitoring Features

### Container Health Checks
- ✅ Docker container status monitoring
- ✅ Application HTTP health checks
- ✅ Database container monitoring
- ✅ Web container monitoring

### Automatic Recovery
- ✅ Graceful container restart
- ✅ Restart attempt limiting
- ✅ Cooldown periods between restarts
- ✅ Failure notification system

### Logging & Monitoring
- ✅ Detailed activity logging
- ✅ Timestamped log entries
- ✅ Error tracking and reporting
- ✅ Status monitoring commands

## 🛠️ Management Commands

### Simple Monitor (start-monitor.sh)

```bash
./start-monitor.sh start     # Start monitoring
./start-monitor.sh stop      # Stop monitoring
./start-monitor.sh restart   # Restart monitoring
./start-monitor.sh status    # Check if running
./start-monitor.sh logs      # View live logs
./start-monitor.sh help      # Show help
```

### Systemd Service (install-monitor.sh)

```bash
sudo ./install-monitor.sh install    # Install service
sudo ./install-monitor.sh start      # Start service
sudo ./install-monitor.sh stop       # Stop service
sudo ./install-monitor.sh restart    # Restart service
sudo ./install-monitor.sh status     # Check status
sudo ./install-monitor.sh logs       # View logs
sudo ./install-monitor.sh uninstall  # Remove service
```

## 📝 Log Files

- `monitor.log` - Main monitoring log file
- `monitor.pid` - Process ID file (for simple monitor)

### Log Levels
- `INFO` - Normal operations
- `WARN` - Warning messages
- `ERROR` - Error conditions
- `SUCCESS` - Successful operations
- `CRITICAL` - Critical failures
- `ALERT` - Notification messages

## 🔔 Notifications

The monitor includes a notification system that you can customize:

```bash
# In monitor.sh, modify the send_notification function:
send_notification() {
    local message=$1
    # Add your notification method here:
    # - Email: echo "$message" | mail -s "Alert" your@email.com
    # - Slack: curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"$message\"}" YOUR_SLACK_WEBHOOK
    # - SMS: curl -X POST "https://api.twilio.com/..." # Twilio SMS
    log_message "ALERT" "Notification: $message"
}
```

## 🚨 Troubleshooting

### Monitor Won't Start
```bash
# Check if Docker is running
docker info

# Check if docker-compose.yml exists
ls -la docker-compose.yml

# Check script permissions
ls -la monitor.sh
chmod +x monitor.sh
```

### Containers Keep Restarting
```bash
# Check container logs
docker-compose logs web
docker-compose logs db

# Check monitor logs
./start-monitor.sh logs

# Check application health
curl http://localhost:3000
```

### Service Issues (Linux)
```bash
# Check systemd service status
sudo systemctl status pisoftsolutions-monitor

# View systemd logs
sudo journalctl -u pisoftsolutions-monitor -f

# Restart systemd daemon
sudo systemctl daemon-reload
```

## 🔒 Security Considerations

- The monitor runs with the same permissions as the user who starts it
- For production, consider running as a dedicated service user
- Monitor logs may contain sensitive information
- Ensure proper file permissions on log files

## 📈 Performance Impact

- **CPU**: Minimal (< 1% when containers are healthy)
- **Memory**: ~5-10MB for the monitoring process
- **Disk**: Log file grows over time (rotate logs periodically)
- **Network**: Only HTTP health checks to localhost

## 🔄 Log Rotation

To prevent log files from growing too large:

```bash
# Add to crontab for daily log rotation
0 0 * * * /usr/sbin/logrotate /path/to/logrotate.conf
```

Example logrotate configuration:
```
/path/to/monitor.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
}
```

## ✅ Verification

To verify the monitor is working:

1. **Start monitoring**: `./start-monitor.sh start`
2. **Check status**: `./start-monitor.sh status`
3. **Stop containers manually**: `docker-compose down`
4. **Wait 30 seconds** for monitor to detect
5. **Check if containers restarted**: `docker-compose ps`
6. **View logs**: `./start-monitor.sh logs`

## 🎯 Best Practices

1. **Test the monitor** before deploying to production
2. **Set up notifications** for critical alerts
3. **Monitor the monitor** - check logs regularly
4. **Use log rotation** to manage disk space
5. **Set appropriate restart limits** to prevent loops
6. **Document your setup** for team members

---

**Your application will now stay up 24/7! 🚀**
