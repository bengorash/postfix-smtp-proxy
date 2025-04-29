FROM ubuntu:20.04

# Install all dependencies in a single layer to reduce image size
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    postfix \
    postfix-pcre \
    rsyslog \
    netcat \
    iproute2 \
    net-tools \
    procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create the entrypoint script directly in the Dockerfile
RUN echo '#!/bin/bash\n\
\n\
# Do not exit on errors\n\
set +e\n\
\n\
# Create log file if it does not exist\n\
mkdir -p /var/log\n\
touch /var/log/mail.log\n\
chmod 644 /var/log/mail.log\n\
\n\
# Configure rsyslog - create a basic config that works in Docker\n\
cat > /etc/rsyslog.conf << EOF\n\
module(load="imuxsock")\n\
\n\
# Set the default permissions for all log files\n\
$FileOwner root\n\
$FileGroup adm\n\
$FileCreateMode 0640\n\
$DirCreateMode 0755\n\
$Umask 0022\n\
\n\
# Include all config files in /etc/rsyslog.d/\n\
$IncludeConfig /etc/rsyslog.d/*.conf\n\
\n\
# Log everything to /var/log/mail.log\n\
mail.*                                                  /var/log/mail.log\n\
EOF\n\
\n\
# Start rsyslog without relying on service command\n\
echo "Starting rsyslog daemon..."\n\
rsyslogd\n\
\n\
# Configure postfix\n\
echo "Checking Postfix configuration..."\n\
postfix check\n\
\n\
echo "Setting Postfix permissions..."\n\
postfix set-permissions\n\
\n\
# Make sure Postfix listens on all interfaces\n\
postconf -e "inet_interfaces = all"\n\
postconf -e "inet_protocols = all"\n\
\n\
echo "Starting Postfix..."\n\
postfix start\n\
sleep 2\n\
\n\
echo "Postfix status:"\n\
postfix status\n\
\n\
echo "Network connections:"\n\
netstat -tulnp | grep :25 || echo "Warning: Port 25 not showing in netstat"\n\
\n\
echo "Postfix has been started. Showing mail logs..."\n\
\n\
# Keep the container running and restart Postfix if it stops\n\
while true; do\n\
    if ! postfix status > /dev/null 2>&1; then\n\
        echo "Postfix stopped. Restarting..."\n\
        postfix start\n\
    fi\n\
    sleep 30 & wait $!\n\
done\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

# Copy configuration files
COPY etc/postfix/main.cf /etc/postfix/main.cf
COPY etc/postfix/master.cf /etc/postfix/master.cf
COPY etc/postfix/recipient_canonical /etc/postfix/recipient_canonical
COPY etc/postfix/transport /etc/postfix/transport
COPY etc/postfix/header_checks /etc/postfix/header_checks
COPY etc/postfix/blacklist /etc/postfix/blacklist
COPY etc/postfix/rsyslog.conf /etc/rsyslog.d/postfix.conf

# Process maps
RUN postmap /etc/postfix/transport && \
    postmap /etc/postfix/blacklist && \
    postmap /etc/postfix/recipient_canonical

# Create necessary directories and files
RUN mkdir -p /var/spool/postfix/pid && \
    mkdir -p /var/spool/postfix/etc && \
    mkdir -p /var/log && \
    touch /var/log/mail.log && \
    chmod 644 /var/log/mail.log && \
    chown -R postfix:root /var/spool/postfix

# Expose port 25
EXPOSE 25

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]