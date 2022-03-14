FROM phusion/baseimage:18.04-1.0.0

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

ENV HOME /root

RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# Nginx-PHP Installation
RUN add-apt-repository -y ppa:ondrej/php
RUN add-apt-repository -y ppa:nginx/stable
RUN apt-get update
# php8.0-mcrypt ,--force-yes Removed::
RUN DEBIAN_FRONTEND="noninteractive" export RUNLEVEL=0 && apt-get update && apt-get install -y vim curl wget build-essential software-properties-common php8.0 php8.0-cli php8.0-fpm php8.0-mysql php8.0-pgsql php8.0-sqlite php8.0-curl\
    php8.0-gd php8.0-intl php8.0-imap php8.0-tidy sox php8.0-gd php8.0-xml php8.0-zip php8.0-redis libsox-fmt-all php8.0-mbstring

RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/8.0/fpm/php.ini
RUN sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 60M/" /etc/php/8.0/cli/php.ini
RUN sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 60M/" /etc/php/8.0/fpm/php.ini
RUN sed -i "s/post_max_size = 8M/post_max_size = 60M/" /etc/php/8.0/cli/php.ini
RUN sed -i "s/post_max_size = 8M/post_max_size = 60M/" /etc/php/8.0/fpm/php.ini
RUN sed -i "s/max_execution_time = 30/max_execution_time = 90/" /etc/php/8.0/fpm/php.ini

RUN sed -i "s/pm = dynamic/pm = ondemand/" /etc/php/8.0/fpm/pool.d/www.conf
RUN sed -i "s/pm.max_children = 5/pm.max_children = 20/" /etc/php/8.0/fpm/pool.d/www.conf

RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y nginx supervisor

# RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/8.0/fpm/php-fpm.conf
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/8.0/fpm/php.ini

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
