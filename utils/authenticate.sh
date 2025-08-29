#!/bin/bash

sendmail -f "noreply@panelright.com" $1 <<EOF
Subject: Please Authenticate Yourself to PanelRight
MIME-Version: 1.0
Content-Type: text/html; charset=UTF-8

<html>
  <body style="font-family: Arial, sans-serif; background-color: #b3c8b7.; color: #333; padding: 20px;">
    <div style="max-width: 600px; margin: auto; background-color: #f9f9f9; border: 1px solid #ddd; border-radius: 8px; padding: 30px; box-shadow: 0 2px 5px rgba(0,0,0,0.1);">
      
      <h2 style="color: #799d7f; text-align: center;">PanelRight Authentication</h2>
      
      <p style="font-size: 16px; line-height: 1.5; text-align: center">
        Here is the <strong style="color: #799d7f; font-size: 18px;">authentication code</strong> requested for your login
      </p>
 <p style="text-align: center; margin: 30px 0;">
<span style="
  background-color: #799d7f;
  color: white;
  font-size: 18px;
  font-weight: bold;
  padding: 8px 16px;
  border-radius: 6px;
  display: inline-block;
  margin: 10px 0;
">
        $2
</span>
</p>      
      <p style="font-size: 14px; color: #777; text-align: center; margin-top: 40px;">
        <em>Do not reply to this message. This email address is not monitored.</em>
      </p>
      
    </div>
  </body>
</html>
EOF
