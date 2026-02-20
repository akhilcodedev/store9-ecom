# Stage 1: Build assets
FROM node:18 AS nodebuilder

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: PHP
FROM php:8.2-cli

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        pdo \
        pdo_mysql \
        zip \
        gd

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app
COPY . .

# Copy built assets
COPY --from=nodebuilder /app/public/build ./public/build

RUN composer install --no-dev --optimize-autoloader

CMD php artisan config:clear && \
    php artisan config:cache && \
    php artisan migrate --force && \
    php artisan db:seed --force || true && \
    php artisan storage:link || true && \
    php -S 0.0.0.0:10000 -t public

EXPOSE 10000