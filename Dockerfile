FROM php:8.2-apache

EXPOSE 80
WORKDIR /var/www/html/

## APACHE
# secure apache shoutouts
RUN sed -i 's/ServerSignature On/ServerSignature\ Off/' /etc/apache2/conf-enabled/security.conf
RUN sed -i 's/ServerTokens\ OS/ServerTokens Prod/' /etc/apache2/conf-enabled/security.conf

# enable apache modules
RUN a2enmod rewrite

## PHP
# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# For intl https://github.com/docker-library/php/issues/1216#issuecomment-948769956
# For gd https://github.com/docker-library/php/issues/1080#issuecomment-721265070
# For curl https://github.com/docker-library/php/issues/323#issuecomment-256693115
RUN apt update && apt install -y \
    libicu-dev \
    zlib1g-dev libpng-dev libfreetype6-dev \
    libcurl3-dev \
    libxml2-dev \
    libonig-dev \
    libzip-dev \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype

# From https://github.com/CatoTH/antragsgruen#requirements
RUN docker-php-ext-install -j$( nproc ) \
    intl gd pdo_mysql \
    opcache curl xml mbstring zip iconv

RUN sed -i 's/expose_php\ =\ On/expose_php = Off/' "$PHP_INI_DIR/php.ini"

## Antragsgrün
ARG AG_VERSION=4.11.1

RUN sed -i 's#DocumentRoot\ .*#DocumentRoot\ /var/www/html/web#' /etc/apache2/sites-available/000-default.conf

RUN curl -SL https://github.com/CatoTH/antragsgruen/releases/download/v${AG_VERSION}/antragsgruen-${AG_VERSION}.tar.bz2 \
    | tar -xjC /var/www/html/ --strip-components=1 --no-same-owner

COPY docker-php-entrypoint .

RUN mkdir config/docker && \
    touch config/docker/config.json && \
    ln -sr config/docker/config.json config/config.json && \
    chown -R www-data:www-data .

VOLUME /var/www/html/config/docker

ENTRYPOINT ["/var/www/html/docker-php-entrypoint"]
CMD ["apache2-foreground"]
