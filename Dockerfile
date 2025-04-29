FROM ubuntu:20.04

# Set non-interactive frontend and preconfigure debconf
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections && \
    echo "postfix postfix/mailname string mail.togotrek.com" | debconf-set-selections

# Install Postfix, rsyslog, and dependencies
RUN apt-get update && \
    apt-get install -y postfix rsyslog libterm-readline-perl-perl && \
    apt-get install -y --reinstall postfix && \
    postconf -e 'inet_interfaces = all' && \
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
COPY etc/postfix/recipient_canonical /etc/postfix/recipient_canonical
COPY etc/postfix/transport /etc/postfix/transport
COPY etc/postfix/header_checks /etc/postfix/header_checks
COPY etc/postfix/blacklist /etc/postfix/blacklist

# Copy rsyslog configuration
COPY etc/postfix/rsyslog.conf /etc/rsyslog.d/postfix.conf

# Compile transport and blacklist maps
RUN postmap /etc/postfix/transport && \
    postmap /etc/postfix/blacklist

# Create required Postfix directories
RUN mkdir -p /var/spool/postfix/pid && \
    mkdir -p /var/spool/postfix/etc && \
    mkdir -p /var/spool/postfix/public && \
    mkdir -p /var/spool/postfix/private

# Configure rsyslog to avoid imklog errors
RUN echo "module(load=\"imuxsock\")" > /etc/rsyslog.conf && \
    sed -i 's/#module(load="imudp")/module(load="imudp")/' /etc/rsyslog.conf && \
    sed -i 's/#input(type="imudp" port="514")/input(type="imudp" port="514")/' /etc/rsyslog.conf

# Expose SMTP port
EXPOSE 25

# Start rsyslog and Postfix
CMD ["/bin/bash", "-c", "service rsyslog start && postfix start && tail -f /var/log/mail.log"]