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

# Ensure log directories exist and have proper permissions
RUN mkdir -p /var/log && \
    touch /var/log/mail.log && \
    chmod 644 /var/log/mail.log && \
    chown syslog:adm /var/log/mail.log

# Create a proper startup script with permissions fixes
RUN echo '#!/bin/bash\n\
# Ensure log files have proper permissions\n\
mkdir -p /var/log\n\
touch /var/log/mail.log\n\
chmod 644 /var/log/mail.log\n\
chown syslog:adm /var/log/mail.log\n\
\n\
# Start rsyslog with proper configuration\n\
rsyslogd -n &\n\
\n\
# Initialize Postfix directories\n\
postfix stop || true\n\
mkdir -p /var/spool/postfix/pid\n\
mkdir -p /var/mail\n\
chmod 777 /var/mail\n\
\n\
# Start Postfix\n\
postfix start\n\
\n\
# Keep container running\n\
tail -f /var/log/mail.log\n\
' > /start-services.sh && chmod +x /start-services.sh

# Expose ports
EXPOSE 25

# Start services
CMD ["/start-services.sh"]