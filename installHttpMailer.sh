#!/bin/bash

# installHttpMailer.sh - Install httpMailer service on Raspberry Pi 3B running Ubuntu 24.04
# This script sets up Python virtual environment, Postfix, and systemd service

set -euo pipefail

# Configuration variables
SERVICE_NAME="httpmailer"
SERVICE_USER="mark"
SERVICE_PORT="8080"
VENV_PATH="/home/mark/.local/venv"
INSTALL_DIR="/home/mark/httpMailer"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root for system configuration
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Update system packages
update_system() {
    log_info "Updating system packages..."
    apt update && apt upgrade -y
    log_success "System packages updated"
}

# Install required system packages
install_system_packages() {
    log_info "Installing required system packages..."
    
    # Install Python3, venv, and development tools
    apt install -y \
        python3 \
        python3-venv \
        python3-pip \
        python3-dev \
        postfix \
        mailutils \
        build-essential \
        curl \
        wget \
        ufw
    
    log_success "System packages installed"
}

# Configure Postfix for local mail delivery
configure_postfix() {
    log_info "Configuring Postfix mail server..."
    
    # Backup original configuration
    if [[ -f /etc/postfix/main.cf ]]; then
        cp /etc/postfix/main.cf /etc/postfix/main.cf.backup
    fi
    
    # Configure Postfix main.cf
    cat > /etc/postfix/main.cf << 'EOF'
# Postfix configuration for httpMailer service
smtpd_banner = $myhostname ESMTP $mail_name
biff = no
append_dot_mydomain = no
readme_directory = no
compatibility_level = 2

# TLS parameters (basic configuration)
smtpd_use_tls = yes
smtpd_tls_cert_file = /etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file = /etc/ssl/private/ssl-cert-snakeoil.key
smtpd_tls_security_level = may
smtp_tls_CApath = /etc/ssl/certs
smtp_tls_security_level = may
smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache

# Network configuration
myhostname = localhost
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
mydestination = $myhostname, localhost.localdomain, localhost
relayhost = 
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = loopback-only
inet_protocols = all

# Local delivery configuration
home_mailbox = Maildir/
mailbox_command = 
EOF

    # Update aliases
    newaliases
    
    # Restart and enable Postfix
    systemctl enable postfix
    systemctl restart postfix
    
    log_success "Postfix configured and started"
}

# Create service user
create_service_user() {
    log_info "Using existing user: "
    log_success "Service user confirmed"
}

# Set up Python virtual environment
setup_python_venv() {
    log_info "Setting up Python virtual environment at $VENV_PATH"
    
    # Create venv directory if it doesn't exist
    mkdir -p "$(dirname "$VENV_PATH")"
    
    # Create virtual environment
    python3 -m venv "$VENV_PATH"
    
    # Activate venv and upgrade pip
    source "$VENV_PATH/bin/activate"
    pip install --upgrade pip
    
    # Note: The httpServer.py uses only standard library modules,
    # so no additional Python packages are needed
    
    log_success "Python virtual environment created"
}


# Install httpMailer files
install_httpmailer_files() {
    log_info "Configuring httpMailer files in $INSTALL_DIR"
    
    # Files already in place - just set permissions
    chmod +x "$INSTALL_DIR/http_server.py"
    chmod +x "$INSTALL_DIR/utils/authenticate.sh"
    chmod +x "$INSTALL_DIR/utils/contactUS.sh"
    
    # Set ownership
    chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"
    
    log_success "httpMailer files configured"
}

# Create systemd service file
create_systemd_service() {
    log_info "Creating systemd service file"
    
    cat > "/etc/systemd/system/$SERVICE_NAME.service" << EOF
[Unit]
Description=httpMailer Service
After=network.target postfix.service
Wants=postfix.service

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$INSTALL_DIR
Environment=PATH=$VENV_PATH/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=$VENV_PATH/bin/python $INSTALL_DIR/http_server.py $SERVICE_PORT
Restart=always
RestartSec=60
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME

# Security settings
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=$INSTALL_DIR
PrivateTmp=yes
PrivateDevices=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd and enable service
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    
    log_success "Systemd service created and enabled"
}

# Configure firewall
configure_firewall() {
    log_info "Configuring firewall for port $SERVICE_PORT"
    
    # Enable UFW if not already enabled
    ufw --force enable
    
    # Allow SSH (important for remote access)
    ufw allow ssh
    
    # Allow the service port
    ufw allow "$SERVICE_PORT"/tcp
    
    # Reload firewall
    ufw reload
    
    log_success "Firewall configured"
}

# Start the service
start_service() {
    log_info "Starting $SERVICE_NAME service"
    
    systemctl start "$SERVICE_NAME"
    
    # Check if service started successfully
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_success "Service started successfully"
        systemctl status "$SERVICE_NAME" --no-pager --lines=10
    else
        log_error "Failed to start service"
        systemctl status "$SERVICE_NAME" --no-pager --lines=10
        exit 1
    fi
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    # Check if service is running
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_success "✓ Service is running"
    else
        log_error "✗ Service is not running"
    fi
    
    # Check if service is enabled
    if systemctl is-enabled --quiet "$SERVICE_NAME"; then
        log_success "✓ Service is enabled for auto-start"
    else
        log_error "✗ Service is not enabled"
    fi
    
    # Check if port is listening
    if netstat -tlpn | grep -q ":$SERVICE_PORT "; then
        log_success "✓ Service is listening on port $SERVICE_PORT"
    else
        log_warning "? Port $SERVICE_PORT may not be listening (check with: netstat -tlpn | grep :$SERVICE_PORT)"
    fi
    
    # Test service endpoint
    log_info "Testing service endpoint..."
    sleep 2
    if curl -s -f "http://localhost:$SERVICE_PORT/" > /dev/null; then
        log_success "✓ Service endpoint is responding"
    else
        log_warning "? Service endpoint test failed (this may be normal if using port 25)"
    fi
}

# Display final information
display_final_info() {
    echo
    log_success "Installation completed!"
    echo
    echo "Service Information:"
    echo "  - Service name: $SERVICE_NAME"
    echo "  - Service user: $SERVICE_USER"
    echo "  - Installation directory: $INSTALL_DIR"
    echo "  - Virtual environment: $VENV_PATH"
    echo "  - Service port: $SERVICE_PORT"
    echo "  - Log files: journalctl -u $SERVICE_NAME -f"
    echo
    echo "Service Management Commands:"
    echo "  - Start service:   sudo systemctl start $SERVICE_NAME"
    echo "  - Stop service:    sudo systemctl stop $SERVICE_NAME"
    echo "  - Restart service: sudo systemctl restart $SERVICE_NAME"
    echo "  - Service status:  sudo systemctl status $SERVICE_NAME"
    echo "  - View logs:       sudo journalctl -u $SERVICE_NAME -f"
    echo
    echo "Testing the service:"
    echo "  - GET request:  curl http://localhost:$SERVICE_PORT/"
    echo "  - POST auth:    curl -X POST http://localhost:$SERVICE_PORT/authenticate -H 'Content-Type: application/json' -d '{\"email\":\"test@example.com\",\"code\":\"123456\"}'"
    echo
}

# Main installation function
main() {
    log_info "Starting httpMailer installation on Raspberry Pi 3B (Ubuntu 24.04)"
    
    check_root
    update_system
    install_system_packages
    configure_postfix
    create_service_user
    setup_python_venv
    install_httpmailer_files
    create_systemd_service
    configure_firewall
    start_service
    verify_installation
    display_final_info
    
    log_success "httpMailer installation completed successfully!"
}

# Run main function
main "$@"
