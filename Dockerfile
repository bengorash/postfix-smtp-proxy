FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && \
    apt-get install -y postfix rsyslog ca-certificates netcat procps postfix-ldap libsasl2-modules && \
    apt-get clean

# Configure Postfix
RUN echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections && \
    echo "postfix postfix/mailname string mail.togotrek.com" | debconf-set-selections

# Create necessary directories with proper permissions
RUN mkdir -p /var/spool/postfix/public /var/spool/postfix/private \
    /var/spool/postfix/pid /var/spool/postfix/etc /var/spool/postfix/lib && \
    chown -R postfix:postfix /var/spool/postfix && \
    chmod 755 /var/spool/postfix && \
    chmod -R 700 /var/spool/postfix/private && \
    chmod -R 710 /var/spool/postfix/public && \
    mkdir -p /var/mail && \
    chmod 777 /var/mail

# Copy configuration files
COPY etc/postfix/main.cf /etc/postfix/main.cf
COPY etc/postfix/master.cf /etc/postfix/master.cf
COPY etc/postfix/header_checks /etc/postfix/header_checks
COPY etc/postfix/sasl_passwd /etc/postfix/sasl_passwd

# Configure rsyslog
RUN echo 'module(load="imuxsock")' > /etc/rsyslog.conf && \
    echo 'module(load="imudp")' >> /etc/rsyslog.conf && \
    echo 'input(type="imudp" port="514")' >> /etc/rsyslog.conf && \
    echo '*.* /var/log/mail.log' > /etc/rsyslog.d/mail.conf && \
    mkdir -p /var/log && \
    touch /var/log/mail.log && \
    chmod 644 /var/log/mail.log

# Create startup script
COPY start-services.sh /start-services.sh
RUN chmod +x /start-services.sh

# Expose only port 587
EXPOSE 2525

# Start services
CMD ["/start-services.sh"]