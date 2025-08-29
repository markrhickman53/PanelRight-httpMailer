#!/bin/bash

# contactUS.sh - Send contact form emails
# Parameters: $1=name, $2=email, $3=subject, $4=message

NAME="$1"
EMAIL="$2"
SUBJECT="$3"
MESSAGE="$4"

# Validate required parameters
if [ -z "$NAME" ] || [ -z "$EMAIL" ] || [ -z "$SUBJECT" ] || [ -z "$MESSAGE" ]; then
    echo "Error: Missing required parameters (name, email, subject, message)" >&2
    exit 1
fi

# Send email to your contact address (replace with your actual email)
CONTACT_EMAIL="inquiries@panelright.com"

sendmail -f "noreply@panelright.com" "$CONTACT_EMAIL" <<EOF
Subject: Contact Form: $SUBJECT
MIME-Version: 1.0
Content-Type: text/html; charset=UTF-8
Reply-To: $EMAIL

<html>
  <body style="font-family: Arial, sans-serif; background-color: #f4f4f4; color: #333; padding: 20px;">
    <div style="max-width: 600px; margin: auto; background-color: #ffffff; border: 1px solid #ddd; border-radius: 8px; padding: 30px; box-shadow: 0 2px 5px rgba(0,0,0,0.1);">
      
      <h2 style="color: #799d7f; text-align: center; border-bottom: 2px solid #799d7f; padding-bottom: 10px;">
        Contact Form Submission
      </h2>
      
      <div style="margin: 20px 0;">
        <h3 style="color: #555; margin-bottom: 5px;">From:</h3>
        <p style="margin: 5px 0; padding: 10px; background-color: #f9f9f9; border-left: 3px solid #799d7f;">
          <strong>$NAME</strong><br>
          <a href="mailto:$EMAIL" style="color: #799d7f;">$EMAIL</a>
        </p>
      </div>
      
      <div style="margin: 20px 0;">
        <h3 style="color: #555; margin-bottom: 5px;">Subject:</h3>
        <p style="margin: 5px 0; padding: 10px; background-color: #f9f9f9; border-left: 3px solid #799d7f;">
          $SUBJECT
        </p>
      </div>
      
      <div style="margin: 20px 0;">
        <h3 style="color: #555; margin-bottom: 5px;">Message:</h3>
        <div style="margin: 5px 0; padding: 15px; background-color: #f9f9f9; border-left: 3px solid #799d7f; white-space: pre-wrap; line-height: 1.6;">
$MESSAGE
        </div>
      </div>
      
      <hr style="border: none; height: 1px; background-color: #ddd; margin: 30px 0;">
      
      <p style="font-size: 12px; color: #777; text-align: center;">
        This message was sent via the PanelRight contact form.<br>
        Reply directly to this email to respond to <strong>$NAME</strong> at <a href="mailto:$EMAIL" style="color: #799d7f;">$EMAIL</a>
      </p>
      
    </div>
  </body>
</html>
EOF

# Also send a confirmation email to the sender
sendmail -f "noreply@panelright.com" "$EMAIL" <<EOF
Subject: Thank you for contacting PanelRight
MIME-Version: 1.0
Content-Type: text/html; charset=UTF-8

<html>
  <body style="font-family: Arial, sans-serif; background-color: #f4f4f4; color: #333; padding: 20px;">
    <div style="max-width: 600px; margin: auto; background-color: #ffffff; border: 1px solid #ddd; border-radius: 8px; padding: 30px; box-shadow: 0 2px 5px rgba(0,0,0,0.1);">
      
      <h2 style="color: #799d7f; text-align: center;">Thank You for Contacting Us!</h2>
      
      <p style="font-size: 16px; line-height: 1.6;">
        Dear <strong>$NAME</strong>,
      </p>
      
      <p style="font-size: 16px; line-height: 1.6;">
        Thank you for reaching out to PanelRight. We have received your message regarding "<strong>$SUBJECT</strong>" and will get back to you as soon as possible.
      </p>
      
      <div style="background-color: #f9f9f9; border-left: 3px solid #799d7f; padding: 15px; margin: 20px 0;">
        <h4 style="color: #555; margin: 0 0 10px 0;">Your message:</h4>
        <div style="white-space: pre-wrap; line-height: 1.6;">$MESSAGE</div>
      </div>
      
      <p style="font-size: 16px; line-height: 1.6;">
        We typically respond within 24 hours during business days.
      </p>
      
      <p style="font-size: 14px; color: #777; text-align: center; margin-top: 40px; border-top: 1px solid #ddd; padding-top: 20px;">
        <em>This is an automated confirmation. Please do not reply to this email.</em><br>
        For urgent matters, please call us directly.
      </p>
      
    </div>
  </body>
</html>
EOF

echo "Contact form email sent successfully"
