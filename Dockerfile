FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Set up postfix configuration
RUN echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections && \
    echo "postfix postfix/mailname string mail.togotrek.com" | debconf-set-selections

# Install required packages
RUN apt-get update && \
    apt-get install -y postfix rsyslog ca-certificates netcat procps && \
    apt-get clean

# Set up log directories with proper permissions
RUN mkdir -p /var/log && \
    touch /var/log/mail.log /var/log/mail.debug /var/log/syslog && \
    chmod 644 /var/log/mail.log /var/log/mail.debug /var/log/syslog

# Set up postfix directories with proper permissions
RUN mkdir -p /var/spool/postfix /var/log/postfix \
    /var/spool/postfix/pid /var/spool/postfix/etc /var/spool/postfix/lib \
    /var/spool/postfix/public /var/spool/postfix/private /var/mail && \
    chown -R postfix:postfix /var/spool/postfix && \
    chmod 755 /var/spool/postfix && \
    chmod -R 700 /var/spool/postfix/private && \
    chmod -R 710 /var/spool/postfix/public

# Copy configuration files
COPY etc/postfix/main.cf /etc/postfix/main.cf
COPY etc/postfix/master.cf /etc/postfix/master.cf
COPY etc/postfix/header_checks /etc/postfix/header_checks
COPY etc/postfix/rsyslog.conf /etc/rsyslog.d/postfix.conf

# Configure rsyslog
RUN echo "module(load=\"imuxsock\")\nmodule(load=\"imudp\")\ninput(type=\"imudp\" port=\"514\")" > /etc/rsyslog.conf

# Fix man directory permissions issue
RUN mkdir -p /usr/share/man/man1

# Initialize postfix with error handling
RUN newaliases || true && \
    /usr/sbin/postfix set-permissions || true && \
    mkdir -p /var/mail && \
    touch /var/mail/root && \
    chown root:root /var/mail/root && \
    chmod 644 /var/mail/root

# Set up the startup script
COPY start-services.sh /start-services.sh
RUN chmod +x /start-services.sh

# Expose SMTP port
EXPOSE 25

# Start services
CMD ["/start-services.sh"]