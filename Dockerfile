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
set -e\n\
\n\
# Start rsyslog for logging\n\
echo "Starting rsyslog service..."\n\
service rsyslog start || echo "Warning: rsyslog service failed to start"\n\
\n\
# Create log file if it does not exist\n\
touch /var/log/mail.log\n\
\n\
# Configure postfix\n\
echo "Checking Postfix configuration..."\n\
postfix check\n\
\n\
echo "Setting Postfix permissions..."\n\
postfix set-permissions\n\
\n\
# Ensure Postfix is set to listen on all interfaces\n\
postconf -e "inet_interfaces = all"\n\
postconf -e "inet_protocols = all"\n\
\n\
echo "Starting Postfix..."\n\
postfix start\n\
\n\
echo "Postfix status:"\n\
postfix status\n\
\n\
echo "Network connections:"\n\
# Check if netstat exists, otherwise use ss\n\
if command -v netstat &> /dev/null; then\n\
    netstat -tulnp | grep :25 || echo "Warning: Port 25 not showing in netstat"\n\
else\n\
    ss -tulnp | grep :25 || echo "Warning: Port 25 not showing in ss"\n\
fi\n\
\n\
echo "Postfix has been started. Showing mail logs..."\n\
\n\
# Keep the container running and show logs\n\
tail -f /var/log/mail.log\n\
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

# Configure rsyslog
RUN echo "module(load=\"imuxsock\")" > /etc/rsyslog.conf && \
    sed -i 's/#module(load="imudp")/module(load="imudp")/' /etc/rsyslog.conf && \
    sed -i 's/#input(type="imudp" port="514")/input(type="imudp" port="514")/' /etc/rsyslog.conf

# Create mail log file
RUN touch /var/log/mail.log && chmod 644 /var/log/mail.log

# Expose port 25
EXPOSE 25

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]