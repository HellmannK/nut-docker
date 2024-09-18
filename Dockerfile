# Networkupstools "nut" with mail-notification, nut-cgi and wol
FROM debian:bookworm
LABEL Karim Ellmann, Mirko Schimkat

# Set environment variables for non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Update the package list and install NUT and Apache
RUN apt-get update && \
    apt-get install -y nut nut-cgi nginx-light fcgiwrap postfix mailutils curl etherwake && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /opt/scripts/configs /run/nut && \
    chown nut:nut /run/nut && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Define exposed Ports
EXPOSE 3493/tcp 80/tcp

# Copy configuration for NUT, NUT-CGI, POSTFIX, and NGINX
COPY configs/nginx.conf /etc/nginx/nginx.conf
COPY configs/hosts.conf /etc/nut/hosts.conf
COPY configs/nut.conf /etc/nut/nut.conf
COPY configs/ups.conf /etc/nut/ups.conf
COPY configs/upsd.conf /etc/nut/upsd.conf
COPY configs/upsd.users /etc/nut/upsd.users
COPY configs/upsmon.conf /etc/nut/upsmon.conf
COPY configs/main.cf /etc/postfix/main.cf
COPY scripts/wol.sh /opt/scripts/wol.sh
COPY configs/wol_clients.conf /opt/scripts/wol_clients.conf

# Adjust permissions to avoid world-readable warnings
RUN chmod 640 /etc/nut/upsd.conf /etc/nut/upsd.users

# Copy entrypoint script into the container
COPY entrypoint.sh /usr/local/bin/

# Make scripts executable
RUN chmod +x /usr/local/bin/entrypoint.sh /opt/scripts/wol.sh

# Set the entrypoint to the script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
