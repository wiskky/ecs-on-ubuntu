# syntax=docker/dockerfile:1

FROM ubuntu:22.04

# ================================================================
# Base environment
# ================================================================
ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# ================================================================
# Build arguments
# ================================================================
ARG GITHUB_USERNAME
ARG REPOSITORY_NAME
ARG APPLICATION_CODE_FILE_NAME
ARG RDS_ENDPOINT
ARG RDS_DB_NAME
ARG RDS_DB_USERNAME
ARG DOMAIN_NAME

# Newly added build args
ARG PROJECT_NAME=nest
ARG ENVIRONMENT=dev
ARG RECORD_NAME=www

# ================================================================
# Environment variables
# ================================================================
ENV GITHUB_USERNAME=${GITHUB_USERNAME}
ENV REPOSITORY_NAME=${REPOSITORY_NAME}
ENV APPLICATION_CODE_FILE_NAME=${APPLICATION_CODE_FILE_NAME}
ENV RDS_ENDPOINT=${RDS_ENDPOINT}
ENV RDS_DB_NAME=${RDS_DB_NAME}
ENV RDS_DB_USERNAME=${RDS_DB_USERNAME}
ENV DOMAIN_NAME=${DOMAIN_NAME}

ENV PROJECT_NAME=${PROJECT_NAME}
ENV ENVIRONMENT=${ENVIRONMENT}ENV RECORD_NAME=${RECORD_NAME}

# ================================================================
# Install dependencies
# ================================================================
# Update all packages
RUN apt update -y

# Install git and unzip
RUN apt install -y git unzip

# Install Apache, PHP and required extensions
RUN apt update && apt install -y \
    apache2 \
    php \
    php-cli \
    php-fpm \
    php-mysql \
    php-bcmath \
    php-mbstring \
    php-gd \
    php-xml \
    php-curl


# Install Git LFS
RUN apt-get update && apt-get install -y curl gnupg \
    && curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash \
    && apt-get install -y git-lfs \
    && git lfs install \
    && rm -rf /var/lib/apt/lists/*


# Update PHP settings
RUN sed -i 's/^memory_limit = .*/memory_limit = 256M/' /etc/php/*/apache2/php.ini && \
    sed -i 's/^max_execution_time = .*/max_execution_time = 300/' /etc/php/*/apache2/php.ini
# Enable Apache mod_rewrite
RUN a2enmod rewrite && \
    sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' \/etc/apache2/apache2.conf

# ================================================================
# Application setup
# ================================================================
WORKDIR /var/www/html

# Clean the directory first, then clone
# RUN --mount=type=secret,id=personal_access_token \
#    PERSONAL_ACCESS_TOKEN=$(cat /run/secrets/personal_access_token) && \
#    rm -rf * && \
#    git clone https://${PERSONAL_ACCESS_TOKEN}@github.com/${GITHUB_USERNAME}/${REPOSITORY_NAME}.git .

# Clean the directory first, then clone private repo securely

RUN --mount=type=secret,id=personal_access_token \
    PERSONAL_ACCESS_TOKEN=$(cat /run/secrets/personal_access_token) && \
    rm -rf /var/www/html/* && \
    git config --global url."https://${PERSONAL_ACCESS_TOKEN}@github.com/".insteadOf "https://github.com/" && \
    git clone https://${GITHUB_USERNAME}:${PERSONAL_ACCESS_TOKEN}@github.com/${GITHUB_USERNAME}/${REPOSITORY_NAME}.git . && \
    git config --global --unset url."https://${PERSONAL_ACCESS_TOKEN}@github.com/".insteadOf


    

# Pull LFS files
RUN git lfs pull

# Extract application code
RUN unzip ${APPLICATION_CODE_FILE_NAME}.zip && \
    cp -R ${APPLICATION_CODE_FILE_NAME}/. /var/www/html/ && \
    rm -rf ${APPLICATION_CODE_FILE_NAME} ${APPLICATION_CODE_FILE_NAME}.zip

# ================================================================
# Permissions
# ================================================================
RUN chmod -R 777 /var/www/html && \
    chmod -R 777 /var/www/html/bootstrap/cache/ && \
    chmod -R 777 /var/www/html/storage/

# ================================================================
# Update .env file
# ================================================================
RUN --mount=type=secret,id=rds_db_password \
    RDS_DB_PASSWORD=$(cat /run/secrets/rds_db_password) && \
    sed -i "s|^APP_NAME=.*|APP_NAME=${PROJECT_NAME}-${ENVIRONMENT}|" .env && \
    sed -i "s|^APP_URL=.*|APP_URL=https://${RECORD_NAME}.${DOMAIN_NAME}/|" .env && \
    sed -i "s|^DB_HOST=.*|DB_HOST=${RDS_ENDPOINT}|" .env && \
    sed -i "s|^DB_DATABASE=.*|DB_DATABASE=${RDS_DB_NAME}|" .env && \
    sed -i "s|^DB_USERNAME=.*|DB_USERNAME=${RDS_DB_USERNAME}|" .env && \
    sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=${RDS_DB_PASSWORD}|" .env

# ================================================================
# Replace AppServiceProvider
# ================================================================
COPY AppServiceProvider.php app/Providers/AppServiceProvider.php

# ================================================================
# Locale + startup
# ================================================================
RUN apt update && apt install -y locales && \
    locale-gen en_US.UTF-8

COPY start-services.sh /usr/local/bin/start-services.sh

RUN chmod +x /usr/local/bin/start-services.sh && \
    sed -i 's/\r$//' /usr/local/bin/start-services.sh

EXPOSE 80 3306

CMD ["/usr/local/bin/start-services.sh"]
