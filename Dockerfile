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
    mkdir -p /opt/scripts/configs /var/run/fcgiwrap && \
    touch /etc/nut/nut-scanner-output.txt && \
    chown nut:nut /etc/nut/nut-scanner-output.txt && \
    chown nut:nut /run/nut && \
    chown www-data:www-data /var/run/fcgiwrap

# Define exposed Ports
EXPOSE 3493/tcp 9095/tcp

# Copy static scripts
COPY wol.sh /opt/scripts/wol.sh
COPY entrypoint.sh /usr/local/bin/

# Copy configs
COPY nginx.conf /etc/nginx/nginx.conf
COPY wol_clients.conf /opt/scripts/configs/wol_clients.conf

# Make scripts executable
RUN chmod +x /usr/local/bin/entrypoint.sh /opt/scripts/wol.sh

RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Set the entrypoint to the script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
