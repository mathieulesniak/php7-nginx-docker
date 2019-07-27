FROM php:7.3-fpm

MAINTAINER Mathieu LESNIAK <mathieu@lesniak.fr>

# Set Locale to fr_FR.UTF8
RUN cp /etc/locale.gen /etc/locale.gen.sav \
    && echo "fr_FR.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y && apt-get install -y --no-install-recommends \
    apt-utils \
    locales \
    wget \
    curl \
    git \
    ssmtp \
    libmemcached-dev \
    libxml2-dev \
    libfreetype6-dev \
    libicu-dev \
    libmcrypt-dev \
    zlib1g-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libxpm-dev \
    libzip-dev \
    libmagickwand-dev \
    unzip

RUN docker-php-ext-configure pcntl --enable-pcntl \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-xpm-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) intl mbstring  pdo_mysql tokenizer zip exif xml json mysqli opcache pcntl

# opcode recommended settings
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Memcached ext
RUN pecl install imagick redis mcrypt-1.0.2 memcached && docker-php-ext-enable imagick redis memcached 

# Composer
RUN cd /tmp/ && \
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    composer self-update && \
    apt-get remove --purge curl -y && \
    apt-get clean && \
    apt-get purge && \
    rm -rf /var/lib/apt/lists/*

COPY nginx-site.conf /etc/nginx/sites-enabled/default
COPY entrypoint.sh /etc/entrypoint.sh

RUN usermod -u 1000 www-data
WORKDIR /var/www/
EXPOSE 80

ENTRYPOINT ["/etc/entrypoint.sh"]

