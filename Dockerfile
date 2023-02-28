FROM ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive
ENV TZ=UTC

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Ensure UTF-8
# RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

ENV HOME /root

RUN apt-get update && apt-get install -y curl gnupg ca-certificates zip unzip git &&  curl -sS 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x14aa40ec0831756756d7f66c4f4ea0aae5267a6c' | gpg --dearmor | tee /etc/apt/keyrings/ppa_ondrej_php.gpg > /dev/null \
    && echo "deb [signed-by=/etc/apt/keyrings/ppa_ondrej_php.gpg] https://ppa.launchpadcontent.net/ondrej/php/ubuntu jammy main" > /etc/apt/sources.list.d/ppa_ondrej_php.list

RUN DEBIAN_FRONTEND="noninteractive" export RUNLEVEL=0 && apt-get update && \
    apt-get install -y \
    vim \
    wget \
    build-essential \
    software-properties-common \
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
    php8.2-mbstring

RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/8.2/fpm/php.ini
RUN sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 60M/" /etc/php/8.2/cli/php.ini
RUN sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 60M/" /etc/php/8.2/fpm/php.ini
RUN sed -i "s/post_max_size = 8M/post_max_size = 60M/" /etc/php/8.2/cli/php.ini
RUN sed -i "s/post_max_size = 8M/post_max_size = 60M/" /etc/php/8.2/fpm/php.ini
RUN sed -i "s/max_execution_time = 30/max_execution_time = 90/" /etc/php/8.2/fpm/php.ini

RUN sed -i "s/pm = dynamic/pm = ondemand/" /etc/php/8.2/fpm/pool.d/www.conf
RUN sed -i "s/pm.max_children = 5/pm.max_children = 20/" /etc/php/8.2/fpm/pool.d/www.conf

RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y nginx supervisor

# RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/8.2/fpm/php-fpm.conf
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/8.2/fpm/php.ini

# Nginx configuration
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./default /etc/nginx/sites-available/default

# Docker logging to stderr
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

RUN mkdir -p /var/www
RUN mkdir -p /var/run/php
RUN mkdir -p /var/log/php-fpm


COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
EXPOSE 80
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
