FROM ubuntu:22.04
LABEL maintainer="Mohamed Foly"
RUN apt-get update && \
    apt-get install -y \
    gnupg \
    curl && \
    curl -sS 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x14aa40ec0831756756d7f66c4f4ea0aae5267a6c' | gpg --dearmor | tee /etc/apt/keyrings/ppa_ondrej_php.gpg > /dev/null && \
    echo "deb [signed-by=/etc/apt/keyrings/ppa_ondrej_php.gpg] https://ppa.launchpadcontent.net/ondrej/php/ubuntu jammy main" > /etc/apt/sources.list.d/ppa_ondrej_php.list && \
    apt-get update && \
    apt-get install -y \
    zip \
    unzip \
    supervisor \
    php8.2-cli \
    php8.2-mbstring \
    php8.2-bcmath \
    php8.2-xml \
    php8.2-zip \
    php8.2-mysql \
    php8.2-swoole \
    php8.2-curl \
    php8.2-gd \
    php8.2-intl \
    php8.2-imap \
    php8.2-tidy \
    php8.2-redis \
    php8.2-gmp \
    && php -r "readfile('https://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer \
    && apt-get update \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY php.ini /etc/php/8.2/cli/conf.d/99-sizes.ini