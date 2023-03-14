FROM ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive
ENV TZ=UTC

# Ensure UTF-8
# RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

ENV HOME /root

#Configurations
COPY ["nginx.conf", "supervisord.conf", "default", "/files/"]

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    DEBIAN_FRONTEND="noninteractive" export RUNLEVEL=0 && \
    apt-get update && \
    apt-get install -y \
    gnupg \
    curl && \
    curl -sS 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x14aa40ec0831756756d7f66c4f4ea0aae5267a6c' | gpg --dearmor | tee /etc/apt/keyrings/ppa_ondrej_php.gpg > /dev/null && \
    echo "deb [signed-by=/etc/apt/keyrings/ppa_ondrej_php.gpg] https://ppa.launchpadcontent.net/ondrej/php/ubuntu jammy main" > /etc/apt/sources.list.d/ppa_ondrej_php.list && \
    apt-get update && \
    apt-get install -y \
    ca-certificates \
    zip \
    unzip \
    php8.2-cli \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-pgsql \
    php8.2-sqlite \
    php8.2-curl \
    php8.2-gd \
    php8.2-intl \
    php8.2-imap \
    php8.2-tidy \
    sox \
    php8.2-gd \
    php8.2-xml \
    php8.2-zip \
    php8.2-redis \
    libsox-fmt-all \
    php8.2-mbstring \
    nginx \
    supervisor && \
    sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/8.2/fpm/php.ini && \
    sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 60M/" /etc/php/8.2/cli/php.ini && \
    sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 60M/" /etc/php/8.2/fpm/php.ini && \
    sed -i "s/post_max_size = 8M/post_max_size = 60M/" /etc/php/8.2/cli/php.ini && \
    sed -i "s/post_max_size = 8M/post_max_size = 60M/" /etc/php/8.2/fpm/php.ini && \
    sed -i "s/max_execution_time = 30/max_execution_time = 90/" /etc/php/8.2/fpm/php.ini && \
    sed -i "s/pm = dynamic/pm = ondemand/" /etc/php/8.2/fpm/pool.d/www.conf && \
    sed -i "s/pm.max_children = 5/pm.max_children = 20/" /etc/php/8.2/fpm/pool.d/www.conf && \
    sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/8.2/fpm/php-fpm.conf && \
    sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/8.2/fpm/php.ini && \
    cp /files/nginx.conf /etc/nginx/nginx.conf && \
    cp /files/default /etc/nginx/sites-available/default && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    mkdir -p /var/www /var/run/php /var/log/php-fpm && \
    cp /files/supervisord.conf /etc/supervisor/conf.d/supervisord.conf && \
    apt-get clean && rm -rf /files /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 80
