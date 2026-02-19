FROM php:8.2-cli

# 1. Install system dependencies AND Node.js
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    curl \
    # Install Node.js 20
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    # Install PHP extensions: pdo_mysql is CRITICAL for TiDB
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        pdo \
        pdo_mysql \
        zip \
        gd \
        bcmath

# 2. Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 3. Set working directory
WORKDIR /app

# 4. Copy project files
COPY . .

# 5. Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# 6. Install NPM dependencies and Build Assets
RUN npm install && npm run build

# 7. Set permissions
RUN chmod -R 775 storage bootstrap/cache

# 8. Expose Port
EXPOSE 10000

# 9. Start Laravel & Run Seeds
# NOTE: I added 'migrate' because you cannot seed without tables.
# I also fixed the typo 'perimission' -> 'permission'.
CMD sh -c "php artisan migrate --force && \
           php artisan db:seed --force && \
           php artisan permission:import && \
           php artisan module:seed Api && \
           php artisan module:seed Base && \
           php artisan serve --host=0.0.0.0 --port=10000"