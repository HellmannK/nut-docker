# Networkupstools "nut" with mail-notification, nut-cgi and wol
FROM debian:bookworm
LABEL Karim Ellmann, Mirko Schimkat

# Set environment variables for non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Update the package list and install NUT and Apache
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nut \
        nut-cgi \
        nginx-light \
        fcgiwrap \
        postfix \
        mailutils \
        etherwake && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /run/nut /opt/scripts/configs && \
    chown nut:nut /run/nut && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Define exposed Ports
EXPOSE 3493/tcp 9090/tcp

# Copy static scripts
COPY scripts/wol.sh /opt/scripts/wol.sh
COPY entrypoint.sh /usr/local/bin/

# Copy initial config for wol
COPY configs/wol_clients.conf /opt/scripts/configs/wol_clients.conf

# Make scripts executable
RUN chmod +x /usr/local/bin/entrypoint.sh /opt/scripts/wol.sh

# Define volumes to hold configuration files
VOLUME ["/etc/nginx", "/etc/nut", "/etc/postfix", "/opt/scripts"]

# Set the entrypoint to the script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
