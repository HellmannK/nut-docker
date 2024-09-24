# Networkupstools "nut" with mail-notification, nut-cgi and wol
FROM debian:bookworm
LABEL Karim Ellmann

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ Etc/UTC

# Update the package list and install NUT and Apache
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    nut \
    nut-cgi \
    nginx \
    fcgiwrap \
    postfix \
    mailutils \
    etherwake && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir run/nut && \
    mkdir /opt/scripts && \
    mkdir /opt/scripts/configs && \
    mkdir /var/run/fcgiwrap && \
    touch /etc/nut/nut-scanner-output.txt && \
    chown nut:nut /etc/nut/nut-scanner-output.txt && \
    chown nut:nut /run/nut && \
    chown www-data:www-data /var/run/fcgiwrap && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Define exposed Ports
EXPOSE 3493/tcp 9095/tcp

# Copy static scripts
COPY scripts/wol.sh /opt/scripts/wol.sh
COPY entrypoint.sh /usr/local/bin/

# Copy configs
COPY configs/nginx.conf /etc/nginx/nginx.conf
COPY configs/wol_clients.conf /opt/scripts/configs/wol_clients.conf

# Make scripts executable
RUN chmod +x /usr/local/bin/entrypoint.sh /opt/scripts/wol.sh

# Define volumes to hold configuration files
VOLUME ["/etc/nginx", "/etc/nut", "/etc/postfix", "/opt/scripts/configs"]

# Set the entrypoint to the script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
