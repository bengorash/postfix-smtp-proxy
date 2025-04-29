FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && \
    apt-get install -y postfix rsyslog ca-certificates netcat procps && \
    apt-get clean

# Set up proper postfix configuration
RUN echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections && \
    echo "postfix postfix/mailname string mail.togotrek.com" | debconf-set-selections

# Copy configuration files
COPY etc/postfix/main.cf /etc/postfix/main.cf
COPY etc/postfix/master.cf /etc/postfix/master.cf
COPY etc/postfix/header_checks /etc/postfix/header_checks
COPY etc/postfix/rsyslog.conf /etc/rsyslog.d/postfix.conf

# Create a proper startup script
RUN echo '#!/bin/bash\n\
# Create necessary directories and pipes\n\
mkdir -p /var/spool/postfix/public\n\
mkdir -p /var/spool/postfix/private\n\
mkdir -p /var/spool/postfix/pid\n\
mkdir -p /var/mail\n\
chmod 777 /var/mail\n\
\n\
# Ensure Postfix has right permissions\n\
chown -R postfix:postfix /var/spool/postfix\n\
\n\
# Configure and start rsyslog\n\
echo "*.* /var/log/mail.log" > /etc/rsyslog.d/mail.conf\n\
mkdir -p /var/log\n\
touch /var/log/mail.log\n\
chmod 644 /var/log/mail.log\n\
rsyslogd\n\
\n\
# Start Postfix with full initialization\n\
postfix stop\n\
sleep 1\n\
postfix start\n\
\n\
# Verify Postfix initialization\n\
sleep 2\n\
ls -la /var/spool/postfix/public /var/spool/postfix/private >> /var/log/mail.log 2>&1\n\
\n\
# Keep container running\n\
tail -f /var/log/mail.log\n\
' > /start-services.sh && chmod +x /start-services.sh

# Expose ports
EXPOSE 25 587

# Start services
CMD ["/start-services.sh"]