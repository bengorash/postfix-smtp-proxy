FROM ubuntu:20.04

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y postfix rsyslog netcat iproute2 net-tools procps

# Copy configuration files
COPY etc/postfix/main.cf /etc/postfix/main.cf
COPY etc/postfix/master.cf /etc/postfix/master.cf
COPY etc/postfix/recipient_canonical /etc/postfix/recipient_canonical
COPY etc/postfix/transport /etc/postfix/transport
COPY etc/postfix/header_checks /etc/postfix/header_checks
COPY etc/postfix/blacklist /etc/postfix/blacklist
COPY etc/postfix/rsyslog.conf /etc/rsyslog.d/postfix.conf

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Process maps
RUN postmap /etc/postfix/transport && \
    postmap /etc/postfix/blacklist

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