FROM debian:bookworm-slim
LABEL author="Karim Ellmann"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    CONFIGS_DIR=/opt/scripts/configs \
    SCRIPTS_DIR=/opt/scripts \
    POSTFIX_DIR=/etc/postfix \
    NUT_DIR=/etc/nut

# Update, install necessary packages and clean up
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    nut \
    nut-cgi \
    nginx \
    fcgiwrap \
    spawn-fcgi \
    postfix \
    mailutils \
    etherwake && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create necessary directories and set permissions
RUN mkdir -p $CONFIGS_DIR /tmp/nut /tmp/postfix /run/nut && \
    touch $NUT_DIR/nut-scanner-output.txt && \
    chown nut:nut $NUT_DIR/nut-scanner-output.txt && \
    chown nut:nut /run/nut && \
    chown www-data:www-data $NUT_DIR/upsset.conf && \
    mv $NUT_DIR/* /tmp/nut

# Copy postfix configs to a temporary location
RUN touch $POSTFIX_DIR/sasl_passwd $POSTFIX_DIR/sender_canonical $POSTFIX_DIR/generic && \
    mv $POSTFIX_DIR/main.cf /tmp/postfix/main.cf && \
    mv $POSTFIX_DIR/sasl_passwd /tmp/postfix/sasl_passwd && \
    mv $POSTFIX_DIR/sender_canonical /tmp/postfix/sender_canonical && \
    mv $POSTFIX_DIR/generic /tmp/postfix/generic

# Define exposed Ports
EXPOSE 3493/tcp 9095/tcp

# Copy static scripts and configuration files
COPY wol.sh $SCRIPTS_DIR/wol.sh
COPY entrypoint.sh /usr/local/bin/
COPY nginx.conf /etc/nginx/nginx.conf
COPY wol_clients.conf $CONFIGS_DIR/wol_clients.conf

# Make scripts executable
RUN chmod +x /usr/local/bin/entrypoint.sh $SCRIPTS_DIR/wol.sh && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]