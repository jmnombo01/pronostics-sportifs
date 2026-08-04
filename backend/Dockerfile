FROM php:8.3-cli

# Installation des dépendances système (PostgreSQL dev, MySQL client, zip, gd, mbstring)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libpq-dev \
    libzip-dev \
    zip \
    unzip \
    default-mysql-client \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Installation des extensions PHP requises (pdo_mysql ET pdo_pgsql)
RUN docker-php-ext-install pdo_mysql pdo_pgsql mbstring exif pcntl bcmath gd zip

# Installation de Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# Copie des fichiers du projet
COPY . /var/www

# Configuration des permissions sur storage et cache
RUN mkdir -p storage/logs storage/framework/cache storage/framework/sessions storage/framework/views bootstrap/cache \
    && chmod -R 777 storage bootstrap/cache

# Rendre le script d'entrée exécutable
RUN chmod +x /var/www/docker-entrypoint.sh

# Le port d'écoute sera assigné dynamiquement par Render ($PORT)
EXPOSE 10000 8000 80

ENTRYPOINT ["/var/www/docker-entrypoint.sh"]
