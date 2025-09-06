# Domain and SSL Certificate Configuration

## mrhickman.hopto.org Credentials

**ANSWER: No, the mrhickman.hopto.org credentials are NOT required for this service.**

The httpMailer service runs as a local HTTP server that:
- Accepts POST requests on the configured port (default: port 25)
- Processes authentication and contact form requests
- Sends emails via the local Postfix server using `sendmail`

The domain name `mrhickman.hopto.org` would only be needed if:
1. You want external clients to access the service by domain name
2. You're setting up reverse proxy or port forwarding
3. You need SSL/TLS certificates for HTTPS

## Port Configuration

The service is configured to run on **port 25** by default. However, consider these important points:

### Port 25 Considerations:
- Port 25 is traditionally used for SMTP (mail transfer)
- Many ISPs block outbound port 25 to prevent spam
- Running HTTP on port 25 may confuse network administrators
- Consider using alternative ports like:
  - **8080** - Common HTTP alternative
  - **8000** - Development HTTP port  
  - **3000** - Node.js common port
  - **5000** - Flask common port

### To change the port:
Edit the `SERVICE_PORT` variable in `installHttpMailer.sh` before running:
```bash
SERVICE_PORT="8080"  # Change from "25" to desired port
```

## OpenWRT Router Configuration for Let's Encrypt

**ANSWER: Yes, your OpenWRT router at 192.168.1.1 CAN be configured to handle Let's Encrypt certificates centrally.**

### Benefits of Router-Based Certificate Management:
1. **Centralized SSL Management** - One place to manage certificates for all services
2. **Automatic Renewal** - Router handles certificate renewal automatically
3. **Simplified Host Configuration** - Individual services don't need certificate management
4. **Better Security** - Certificates stored in one secure location

### OpenWRT SSL Certificate Setup:

#### 1. Install Required Packages:
```bash
# SSH into your OpenWRT router
opkg update
opkg install luci-app-acme acme curl ca-certificates
```

#### 2. Configure ACME (Let's Encrypt) in LuCI:
- Navigate to: **Services → ACME certificates**
- Add domain: `mrhickman.hopto.org`
- Configure challenge type (HTTP-01 recommended)
- Set email for notifications

#### 3. Configure Reverse Proxy:
Install nginx or lighttpd on OpenWRT:
```bash
opkg install nginx-ssl nginx-mod-http-ssl
```

#### 4. Example nginx Configuration:
```nginx
# /etc/nginx/conf.d/httpmailer.conf
server {
    listen 443 ssl http2;
    server_name mrhickman.hopto.org;
    
    # SSL Certificate (managed by ACME)
    ssl_certificate /etc/ssl/acme/mrhickman.hopto.org/fullchain.pem;
    ssl_certificate_key /etc/ssl/acme/mrhickman.hopto.org/privkey.pem;
    
    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # Proxy to httpMailer service
    location /authenticate {
        proxy_pass http://192.168.1.100:8080/authenticate;  # Your Pi's IP
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /contactUS {
        proxy_pass http://192.168.1.100:8080/contactUS;     # Your Pi's IP
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name mrhickman.hopto.org;
    return 301 https://$server_name$request_uri;
}
```

#### 5. Port Forwarding Setup:
Configure your OpenWRT firewall to forward traffic:
- **External Port 443** → **Router Port 443** (HTTPS)
- **External Port 80** → **Router Port 80** (HTTP for ACME challenges)

### Alternative: Individual Host Certificates

If you prefer each service to manage its own certificates:

#### Install Certbot on Pi:
```bash
sudo apt install certbot
```

#### Get Certificate:
```bash
sudo certbot certonly --standalone \
    --preferred-challenges http \
    --email your-email@example.com \
    --agree-tos \
    --non-interactive \
    --domains mrhickman.hopto.org
```

#### Modify httpMailer for HTTPS:
You would need to modify `http_server.py` to use SSL:
```python
import ssl
# ... in run_server function:
context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.load_cert_chain('/etc/letsencrypt/live/mrhickman.hopto.org/fullchain.pem',
                       '/etc/letsencrypt/live/mrhickman.hopto.org/privkey.pem')
server.socket = context.wrap_socket(server.socket, server_side=True)
```

## Recommendations

### For Production Use:
1. **Use OpenWRT router for SSL termination** (recommended approach)
2. **Change service port from 25 to 8080**
3. **Set up proper firewall rules**
4. **Configure automatic certificate renewal**

### Security Considerations:
- The httpMailer service itself doesn't require domain credentials
- SSL/TLS should be handled at the network edge (router) or load balancer
- Keep the service behind a firewall, accessible only via reverse proxy
- Monitor logs for suspicious activity

### Network Architecture:
```
Internet → OpenWRT Router (SSL termination) → Raspberry Pi (httpMailer)
         Port 443/80                          Port 8080
```

This approach provides:
- ✅ Centralized certificate management
- ✅ Better security isolation
- ✅ Easier maintenance
- ✅ Professional deployment pattern
