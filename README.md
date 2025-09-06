# httpMailer Service

A lightweight HTTP mail service for Raspberry Pi that handles authentication emails and contact form submissions via HTTP POST requests.

## Features

- **Authentication Endpoint** (`/authenticate`): Sends authentication codes via email
- **Contact Form Endpoint** (`/contactUS`): Processes contact form submissions
- **Auto-restart**: Service automatically restarts on failure with 1-minute intervals
- **Systemd Integration**: Starts automatically on boot
- **Security**: Runs as dedicated system user with restricted permissions

## Quick Start

### Installation

1. **Run the installation script**:
```bash
sudo ./installHttpMailer.sh
```

The script will:
- Update system packages
- Install Python3, Postfix, and dependencies
- Create Python virtual environment at `~/.local/venv`
- Configure Postfix for local mail delivery
- Create systemd service with auto-restart
- Configure firewall rules
- Start the service

### Default Configuration

- **Service Name**: `httpmailer`
- **Port**: 25 (configurable)
- **Installation Directory**: `/opt/httpmailer`
- **Service User**: `httpmailer`
- **Virtual Environment**: `~/.local/venv`

## Usage

### Service Management

```bash
# Check service status
sudo systemctl status httpmailer

# Start/stop/restart service
sudo systemctl start httpmailer
sudo systemctl stop httpmailer
sudo systemctl restart httpmailer

# View logs
sudo journalctl -u httpmailer -f
```

### API Endpoints

#### Authentication Endpoint
Send authentication codes to users:

```bash
curl -X POST http://localhost:25/authenticate \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "code": "123456"}'
```

**Parameters:**
- `email`: User's email address
- `code`: Authentication code to send

#### Contact Form Endpoint
Process contact form submissions:

```bash
curl -X POST http://localhost:25/contactUS \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com", 
    "subject": "Inquiry",
    "message": "Hello, I have a question..."
  }'
```

**Parameters:**
- `name`: Contact person's name
- `email`: Contact person's email
- `subject`: Message subject
- `message`: Message content

### Response Format

Both endpoints return JSON responses:

**Success Response:**
```json
{
  "success": true,
  "message": "Operation successful",
  "output": "Command output"
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message"
}
```

## Configuration

### Change Service Port

Edit the `SERVICE_PORT` variable in `installHttpMailer.sh` before installation:

```bash
SERVICE_PORT="8080"  # Change from default port 25
```

**Recommended ports:** 8080, 8000, 3000, 5000

### Email Configuration

The service sends emails using Postfix. Email templates can be customized by editing:
- `utils/authenticate.sh` - Authentication email template
- `utils/contactUS.sh` - Contact form email templates

### Postfix Configuration

Postfix is configured for local delivery only. To send external emails, you may need to:
1. Configure SMTP relay settings
2. Set up proper SPF/DKIM records
3. Configure authentication with your email provider

## Security Considerations

### Port 25 Warning
- Port 25 is traditionally used for SMTP
- Many ISPs block outbound port 25
- Consider using alternative ports (8080, 8000, etc.)
- For external access, use reverse proxy with SSL termination

### SSL/HTTPS
The service runs HTTP only. For production use:
1. **Recommended**: Use OpenWRT router with SSL termination (see `config/domain-config.md`)
2. **Alternative**: Modify the service to support HTTPS directly

### Firewall
The installation script configures UFW firewall to:
- Allow SSH access
- Allow the service port
- Block all other inbound connections

## Troubleshooting

### Service Won't Start
Check the service logs:
```bash
sudo journalctl -u httpmailer -n 50
```

Common issues:
- Port already in use
- Permission problems
- Python virtual environment issues

### Email Not Sending
Check Postfix status:
```bash
sudo systemctl status postfix
sudo tail -f /var/log/mail.log
```

### Port Access Issues
Verify the port is listening:
```bash
netstat -tlpn | grep :25
```

Test with curl:
```bash
curl -v http://localhost:25/
```

## File Structure

```
/opt/httpmailer/
├── http_server.py          # Main HTTP server
└── utils/
    ├── authenticate.sh     # Authentication email script
    └── contactUS.sh       # Contact form email script

~/.local/venv/             # Python virtual environment
/etc/systemd/system/       
└── httpmailer.service     # Systemd service file
```

## Development

### Local Testing
```bash
# Activate virtual environment
source ~/.local/venv/bin/activate

# Run server manually
python3 http_server.py 8080

# Test endpoints
curl -X GET http://localhost:8080/
```

### Logs and Debugging
```bash
# Follow service logs
sudo journalctl -u httpmailer -f

# Check service status
systemctl status httpmailer --no-pager -l

# Check mail logs
sudo tail -f /var/log/mail.log
```

## Advanced Configuration

For production deployments, see `config/domain-config.md` for:
- SSL certificate management
- OpenWRT router configuration
- Reverse proxy setup
- Domain configuration

## Requirements

- Ubuntu 24.04 (Raspberry Pi 3B recommended)
- Python 3.8+
- Postfix mail server
- systemd
- UFW firewall (optional but recommended)

## License

This project is part of the PanelRight suite of tools.
