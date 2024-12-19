# Use the official Ubuntu base image
FROM ubuntu

# Set environment variables for non-interactive installs
ENV DEBIAN_FRONTEND=noninteractive

# Update and install necessary packages
RUN apt-get update && \
    apt-get install -y shellinabox sudo python3 npm vim nano && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create a sandboxuser without setting the password here
RUN useradd -m -s /bin/bash sandboxuser && \
    usermod -aG sudo sandboxuser && \
    echo 'sandboxuser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/sandboxuser

# Copy the .env file into the image (or mount it at runtime)
# Make sure you have a .env file in the build context
COPY .env /tmp/.env

# Create a script to set the sandboxuser password from .env and start Shell In A Box
RUN echo '#!/bin/bash' > /usr/local/bin/start-shellinabox.sh && \
    echo 'set -e' >> /usr/local/bin/start-shellinabox.sh && \
    echo 'if [ -f "/tmp/.env" ]; then' >> /usr/local/bin/start-shellinabox.sh && \
    echo '    . /tmp/.env' >> /usr/local/bin/start-shellinabox.sh && \
    echo '    if [ -n "$SANDBOXUSER_PASSWORD" ]; then' >> /usr/local/bin/start-shellinabox.sh && \
    echo '        echo "sandboxuser:${SANDBOXUSER_PASSWORD}" | chpasswd' >> /usr/local/bin/start-shellinabox.sh && \
    echo '    fi' >> /usr/local/bin/start-shellinabox.sh && \
    echo '    rm /tmp/.env' >> /usr/local/bin/start-shellinabox.sh && \
    echo 'fi' >> /usr/local/bin/start-shellinabox.sh && \
    echo 'shellinaboxd --no-beep --disable-ssl -t --user=sandboxuser' >> /usr/local/bin/start-shellinabox.sh && \
    chmod +x /usr/local/bin/start-shellinabox.sh

# Expose the default port for Shell In A Box
EXPOSE 4200

# Start the Shell In A Box service and keep the container running
CMD ["/usr/local/bin/start-shellinabox.sh"]
