FROM ubuntu:22.04

# Set noninteractive installation
ENV DEBIAN_FRONTEND=noninteractive

# Install Postfix and supporting tools in a single layer
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
    dnsutils \
    net-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip3 install --no-cache-dir requests tenacity

# Create necessary directories
RUN mkdir -p /var/log/supervisor \
    /var/log/postfix \
    /usr/local/bin \
    /var/spool/postfix/pid \
    /var/spool/postfix/etc

# Copy configuration files first
COPY config/main.cf /etc/postfix/main.cf
COPY config/master.cf /etc/postfix/master.cf
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy TLS certificates
COPY cert.pem /etc/postfix/cert.pem
COPY key.pem /etc/postfix/key.pem

# Copy scripts and set permissions
COPY scripts/blacklist_policy.py /usr/local/bin/
COPY scripts/health_monitor.py /usr/local/bin/
COPY scripts/entrypoint.sh /
COPY scripts/postfix-setup.sh /usr/local/bin/

# Set permissions in a single layer
RUN chmod 755 /usr/local/bin/blacklist_policy.py \
    && chmod 755 /usr/local/bin/health_monitor.py \
    && chmod 755 /entrypoint.sh \
    && chmod 755 /usr/local/bin/postfix-setup.sh \
    && chmod 600 /etc/postfix/key.pem \
    && chmod 644 /etc/postfix/cert.pem \
    && chown -R postfix:root /var/spool/postfix/ \
    && chmod 755 /var/spool/postfix/

# Expose SMTP port
EXPOSE 2525

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]