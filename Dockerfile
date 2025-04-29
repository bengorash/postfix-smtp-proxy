FROM ubuntu:20.04

# Set non-interactive frontend
ENV DEBIAN_FRONTEND=noninteractive

# Preconfigure Postfix debconf settings
RUN echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections && \
    echo "postfix postfix/mailname string mail.togotrek.com" | debconf-set-selections

# Install Postfix, rsyslog, and SASL dependencies
RUN apt-get update && \
    apt-get install -y postfix rsyslog libsasl2-modules ca-certificates && \
    apt-get clean

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
COPY etc/postfix/sasl_passwd /etc/postfix/sasl_passwd
COPY etc/postfix/header_checks /etc/postfix/header_checks

# Configure SASL password map
RUN postmap /etc/postfix/sasl_passwd && \
    chmod 600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db && \
    chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db

# Copy rsyslog configuration
COPY etc/postfix/rsyslog.conf /etc/rsyslog.d/postfix.conf

# Create required Postfix directories and set permissions
RUN mkdir -p /var/spool/postfix/pid /var/spool/postfix/etc /var/spool/postfix/public /var/spool/postfix/private && \
    chown root:root /var/spool/postfix /var/spool/postfix/* && \
    chmod 755 /var/spool/postfix /var/spool/postfix/*

# Configure rsyslog
RUN echo "module(load=\"imuxsock\")" > /etc/rsyslog.conf && \
    sed -i 's/#module(load="imudp")/module(load="imudp")/' /etc/rsyslog.conf && \
    sed -i 's/#input(type="imudp" port="514")/input(type="imudp" port="514")/' /etc/rsyslog.conf

# Expose SMTP port
EXPOSE 25

# Start rsyslog and Postfix, keep container running
CMD ["/bin/bash", "-c", "service rsyslog start && postfix start && tail -f /var/log/mail.log"]