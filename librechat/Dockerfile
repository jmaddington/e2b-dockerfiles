FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PGADMIN_PORT=5050
ENV MONGO_EXPRESS_PORT=8081

# Update and install common utilities
RUN apt-get update && apt-get install -y \
    sudo \
    git \
    python3 \
    python3-pip \
    vim \
    nano \
    curl \
    wget \
    gnupg \
    lsb-release \
    software-properties-common \
    make \
    gcc \
    nginx \
    shellinabox \
    # Remove old node if present
    && apt-get remove -y nodejs \
    && apt-get autoremove -y \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create a sandboxuser and set the password
RUN useradd -m -s /bin/bash sandboxuser && \
    echo 'sandboxuser:dJsBwe9pEU' | chpasswd

# Add sandboxuser to sudoers without requiring a password
RUN usermod -aG sudo sandboxuser && \
    echo 'sandboxuser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/sandboxuser

# Add the NodeSource repository for Node.js 18
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get update && apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Check the Node.js version
RUN node -v && npm -v

# Add the PostgreSQL APT repository
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

# Update the package list to include the PostgreSQL packages and install PostgreSQL
RUN apt-get update && apt-get install -y \
    postgresql-14 \
    postgresql-contrib-14 \
    postgresql-server-dev-14 \
    libpq-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set up and initialize the PostgreSQL data directory
RUN mkdir -p /var/lib/postgresql/data && \
    chown postgres:postgres /var/lib/postgresql/data

USER postgres
RUN /usr/lib/postgresql/14/bin/initdb -D /var/lib/postgresql/data

# Return to root
USER root

# Clone and build pgvector extension
RUN cd /usr/local/src && \
    git clone https://github.com/pgvector/pgvector.git && \
    cd pgvector && \
    make && make install

# Add MongoDB repository (for MongoDB 7.0)
RUN curl -fsSL https://pgp.mongodb.com/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-archive-keyring.gpg && \
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list && \
    apt-get update && apt-get install -y mongodb-org && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Meilisearch
RUN curl -L https://install.meilisearch.com -o /usr/local/bin/meilisearch && \
    chmod +x /usr/local/bin/meilisearch

# Install mongo-express globally
RUN npm install -g mongo-express

# Install pgAdmin4 via pip
RUN pip3 install pgadmin4

# Clone LibreChat
RUN mkdir -p /app && \
    git clone https://github.com/jmaddington/LibreChat.git /app/

# Change ownership to sandboxuser
RUN chown sandboxuser:sandboxuser -R /app

USER sandboxuser
WORKDIR /app/librechat

# Install LibreChat dependencies
RUN npm ci

# Build LibreChat frontend
RUN npm run frontend

USER root
# Install pm2 globally
RUN npm install -g pm2

# Copy in your .env (if needed)
COPY .env /app/.env
RUN chown sandboxuser:sandboxuser /app/.env

# Configure the start script
RUN echo '#!/bin/bash\n\
  mongod --bind_ip_all &\n\
  shellinaboxd --disable-ssl --no-beep -s /:LOGIN &\n\
  su - postgres -c "/usr/lib/postgresql/14/bin/pg_ctl start -D /var/lib/postgresql/data" &\n\
  meilisearch --master-key=masterKey &\n\
  mongo-express --url mongodb://localhost:27017 &\n\
  /usr/local/bin/pgadmin4 &\n\
  pm2 start /app/librechat/api/server.js --name api &\n\
  pm2 start /app/librechat/rag/server.js --name rag_api &\n\
  nginx -g "daemon off;"' > /usr/local/bin/start-services.sh && \
    chmod +x /usr/local/bin/start-services.sh

EXPOSE 4200 5432 27017 7700 5050 8081 80 3080

# Command to run when the container starts
CMD ["/usr/local/bin/start-services.sh"]
