FROM ubuntu:22.04

# Set noninteractive installation to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install Postfix and supporting tools
RUN apt-get update && apt-get install -y \
    postfix \
    postfix-pcre \
    libsasl2-modules \
    ca-certificates \
    tzdata \
    curl \
    python3 \
    python3-pip \
    supervisor \
    rsyslog \
    nano \
    iputils-ping \
    netcat \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip3 install requests

# Create necessary directories
RUN mkdir -p /var/log/supervisor \
    && mkdir -p /usr/local/bin

# Copy scripts first and set their permissions
COPY scripts/blacklist_policy.py /usr/local/bin/
COPY scripts/health_monitor.py /usr/local/bin/
COPY scripts/entrypoint.sh /
RUN chmod 755 /usr/local/bin/blacklist_policy.py \
    && chmod 755 /usr/local/bin/health_monitor.py \
    && chmod 755 /entrypoint.sh

# Copy configuration files
COPY config/main.cf /etc/postfix/main.cf
COPY config/master.cf /etc/postfix/master.cf
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy TLS certificates
COPY cert.pem /etc/postfix/cert.pem
COPY key.pem /etc/postfix/key.pem

# Set certificate permissions
RUN chmod 600 /etc/postfix/key.pem \
    && chmod 644 /etc/postfix/cert.pem

# Prepare Postfix environment
RUN mkdir -p /var/spool/postfix/etc \
    && cp /etc/services /var/spool/postfix/etc/services \
    && cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf \
    && mkdir -p /var/spool/postfix/pid \
    && chown -R postfix:root /var/spool/postfix/ \
    && chmod 755 /var/spool/postfix/

# Expose SMTP port
EXPOSE 2525

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]