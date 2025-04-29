FROM ubuntu:20.04

# Set non-interactive frontend
ENV DEBIAN_FRONTEND=noninteractive

# Preconfigure Postfix debconf settings
RUN echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections && \
    echo "postfix postfix/mailname string mail.togotrek.com" | debconf-set-selections

# Install Postfix and rsyslog
RUN apt-get update && \
    apt-get install -y postfix rsyslog ca-certificates && \
    apt-get clean && \
    # Ensure Postfix directories are created
    mkdir -p /var/spool/postfix /var/log/postfix /var/spool/postfix/maildrop /var/spool/postfix/incoming /var/spool/postfix/active /var/spool/postfix/bounce /var/spool/postfix/defer /var/spool/postfix/deferred /var/spool/postfix/flush /var/spool/postfix/saved /var/spool/postfix/trace /var/spool/postfix/hold && \
    chown postfix:postfix /var/spool/postfix /var/log/postfix /var/spool/postfix/maildrop /var/spool/postfix/incoming /var/spool/postfix/active /var/spool/postfix/bounce /var/spool/postfix/defer /var/spool/postfix/deferred /var/spool/postfix/flush /var/spool/postfix/saved /var/spool/postfix/trace /var/spool/postfix/hold

# Create mail.log and set permissions
RUN mkdir -p /var/log && \
    touch /var/log/mail.log && \
    chmod 644 /var/log/mail.log && \
    chown syslog:adm /var/log/mail.log

# Clean default Postfix configs
RUN rm -rf /etc/postfix/* && \
    mkdir -p /etc/postfix

# Copy Postfix configuration files
COPY etc/postfix/main.cf /etc/postfix/main.cf
COPY etc/postfix/master.cf /etc/postfix/master.cf
COPY etc/postfix/header_checks /etc/postfix/header_checks

# Copy rsyslog configuration
COPY etc/postfix/rsyslog.conf /etc/rsyslog.d/postfix.conf

# Create required Postfix directories and set permissions
RUN mkdir -p /var/spool/postfix/pid /var/spool/postfix/etc /var/spool/postfix/public /var/spool/postfix/private && \
    chown root:root /var/spool/postfix/pid /var/spool/postfix/etc /var/spool/postfix/public /var/spool/postfix/private && \
    chmod 755 /var/spool/postfix/pid /var/spool/postfix/etc /var/spool/postfix/public /var/spool/postfix/private

# Configure rsyslog
RUN echo "module(load=\"imuxsock\")\nmodule(load=\"imudp\")\ninput(type=\"imudp\" port=\"514\")" > /etc/rsyslog.conf && \
    echo "*.* /var/log/syslog" >> /etc/rsyslog.conf && \
    chmod 644 /etc/rsyslog.conf /etc/rsyslog.d/postfix.conf && \
    chown root:root /etc/rsyslog.conf /etc/rsyslog.d/postfix.conf

# Ensure Postfix is fully initialized
RUN /usr/sbin/postfix upgrade-configuration && \
    /usr/sbin/postfix check

# Expose SMTP port
EXPOSE 25

# Start rsyslog and Postfix, keep container running for debugging
CMD ["/bin/bash", "-c", "service rsyslog start && (postfix start || (echo 'Postfix failed to start' && tail -f /var/log/mail.log))"]