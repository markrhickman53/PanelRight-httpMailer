#!/usr/bin/env python3
"""
HTTP server that accepts POST requests to multiple endpoints:
- /authenticate: Handles authentication emails with 'email' and 'code' parameters
- /contactUS: Handles contact form submissions with 'name', 'email', 'subject', and 'message' parameters
"""

import json
import subprocess
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs
import os

class MailHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        """Handle POST requests for both authentication and contact form"""
        if self.path == '/authenticate':
            self._handle_authenticate()
        elif self.path == '/contactUS':
            self._handle_contact_us()
        else:
            self.send_error(404, "Not Found")
            return
    
    def _handle_authenticate(self):
        """Handle authentication endpoint"""
        try:
            # Get the content length
            content_length = int(self.headers.get('Content-Length', 0))
            
            # Read the POST data
            post_data = self.rfile.read(content_length)
            
            # Parse JSON or form data
            email = None
            code = None
            
            # Try to parse as JSON first
            try:
                data = json.loads(post_data.decode('utf-8'))
                email = data.get('email')
                code = data.get('code')
            except json.JSONDecodeError:
                # Try to parse as form data
                try:
                    parsed_data = parse_qs(post_data.decode('utf-8'))
                    email = parsed_data.get('email', [None])[0]
                    code = parsed_data.get('code', [None])[0]
                except Exception:
                    pass
            
            # Validate required parameters
            if not email or not code:
                self.send_error(400, "Missing required parameters 'email' and 'code'")
                return
            
            # Call the authenticate.sh script
            script_path = os.path.join(os.path.dirname(__file__), 'utils', 'authenticate.sh')
            
            try:
                result = subprocess.run(
                    [script_path, email, code],
                    capture_output=True,
                    text=True,
                    timeout=30
                )
                
                # Send response based on script result
                if result.returncode == 0:
                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json')
                    self.send_header('Access-Control-Allow-Origin', '*')
                    self.end_headers()
                    response = {
                        'success': True,
                        'message': 'Authentication successful',
                        'output': result.stdout.strip()
                    }
                    self.wfile.write(json.dumps(response).encode('utf-8'))
                else:
                    self.send_response(401)
                    self.send_header('Content-Type', 'application/json')
                    self.send_header('Access-Control-Allow-Origin', '*')
                    self.end_headers()
                    response = {
                        'success': False,
                        'message': 'Authentication failed',
                        'error': result.stderr.strip()
                    }
                    self.wfile.write(json.dumps(response).encode('utf-8'))
                    
            except subprocess.TimeoutExpired:
                self.send_error(504, "Authentication timeout")
            except FileNotFoundError:
                self.send_error(500, "Authentication script not found")
            except Exception as e:
                self.send_error(500, f"Internal server error: {str(e)}")
                
        except Exception as e:
            self.send_error(500, f"Error processing request: {str(e)}")
    
    def _handle_contact_us(self):
        """Handle contact form endpoint"""
        try:
            # Get the content length
            content_length = int(self.headers.get('Content-Length', 0))
            
            # Read the POST data
            post_data = self.rfile.read(content_length)
            
            # Parse JSON or form data
            name = None
            email = None
            subject = None
            message = None
            
            # Try to parse as JSON first
            try:
                data = json.loads(post_data.decode('utf-8'))
                name = data.get('name')
                email = data.get('email')
                subject = data.get('subject')
                message = data.get('message')
            except json.JSONDecodeError:
                # Try to parse as form data
                try:
                    parsed_data = parse_qs(post_data.decode('utf-8'))
                    name = parsed_data.get('name', [None])[0]
                    email = parsed_data.get('email', [None])[0]
                    subject = parsed_data.get('subject', [None])[0]
                    message = parsed_data.get('message', [None])[0]
                except Exception:
                    pass
            
            # Validate required parameters
            if not name or not email or not subject or not message:
                self.send_error(400, "Missing required parameters: 'name', 'email', 'subject', and 'message'")
                return
            
            # Call the contactUS.sh script
            script_path = os.path.join(os.path.dirname(__file__), 'utils', 'contactUS.sh')
            
            try:
                result = subprocess.run(
                    [script_path, name, email, subject, message],
                    capture_output=True,
                    text=True,
                    timeout=30
                )
                
                # Send response based on script result
                if result.returncode == 0:
                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json')
                    self.send_header('Access-Control-Allow-Origin', '*')
                    self.end_headers()
                    response = {
                        'success': True,
                        'message': 'Contact form submitted successfully',
                        'output': result.stdout.strip()
                    }
                    self.wfile.write(json.dumps(response).encode('utf-8'))
                else:
                    self.send_response(500)
                    self.send_header('Content-Type', 'application/json')
                    self.send_header('Access-Control-Allow-Origin', '*')
                    self.end_headers()
                    response = {
                        'success': False,
                        'message': 'Failed to send contact form',
                        'error': result.stderr.strip()
                    }
                    self.wfile.write(json.dumps(response).encode('utf-8'))
                    
            except subprocess.TimeoutExpired:
                self.send_error(504, "Contact form submission timeout")
            except FileNotFoundError:
                self.send_error(500, "Contact form script not found")
            except Exception as e:
                self.send_error(500, f"Internal server error: {str(e)}")
                
        except Exception as e:
            self.send_error(500, f"Error processing request: {str(e)}")
    
    def do_GET(self):
        """Handle GET requests - show usage info"""
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-Type', 'text/html')
            self.end_headers()
            html = """
            <!DOCTYPE html>
            <html>
            <head>
                <title>PanelRight Mail Service</title>
            </head>
            <body>
                <h1>PanelRight Mail Service</h1>
                
                <h2>Authentication Endpoint</h2>
                <p>Send POST requests to <code>/authenticate</code> with the following parameters:</p>
                <ul>
                    <li><strong>email</strong>: User email address</li>
                    <li><strong>code</strong>: Authentication code</li>
                </ul>
                
                <h2>Contact Form Endpoint</h2>
                <p>Send POST requests to <code>/contactUS</code> with the following parameters:</p>
                <ul>
                    <li><strong>name</strong>: Contact person's name</li>
                    <li><strong>email</strong>: Contact person's email</li>
                    <li><strong>subject</strong>: Message subject</li>
                    <li><strong>message</strong>: Message content</li>
                </ul>
                
                <p>Both endpoints support JSON and form data formats.</p>
                
                <h2>Example usage:</h2>
                <h3>Authentication:</h3>
                <pre>
curl -X POST http://localhost:8000/authenticate \\
  -H "Content-Type: application/json" \\
  -d '{"email": "user@example.com", "code": "123456"}'
                </pre>
                
                <h3>Contact Form:</h3>
                <pre>
curl -X POST http://localhost:8000/contactUS \\
  -H "Content-Type: application/json" \\
  -d '{
    "name": "John Doe", 
    "email": "john@example.com", 
    "subject": "Inquiry", 
    "message": "Hello, I have a question..."
  }'
                </pre>
            </body>
            </html>
            """
            self.wfile.write(html.encode('utf-8'))
        else:
            self.send_error(404, "Not Found")

def run_server(port=8000):
    """Start the HTTP server"""
    server = HTTPServer(('', port), MailHandler)
    print(f"Starting mail service server on port {port}")
    print(f"Available endpoints:")
    print(f"  - POST http://localhost:{port}/authenticate")
    print(f"  - POST http://localhost:{port}/contactUS")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server...")
        server.shutdown()

if __name__ == "__main__":
    port = 8000
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            print("Invalid port number")
            sys.exit(1)
    
    run_server(port)
