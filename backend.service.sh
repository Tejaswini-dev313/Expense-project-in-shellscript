

[Unit]
Description = Backend Service

[Service]
User=expense
Environment=DB_HOST="3.86.48.228"
ExecStart=/bin/node /app/index.js
SyslogIdentifier=backend

[Install]
WantedBy=multi-user.target