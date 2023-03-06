FROM alpine:3.17

ADD ./files /files

ENV PHP_INI_DIR /usr/local/etc/php

RUN set -eux; \
    mkdir -p /etc/nginx /etc/supervisor/conf.d /etc/nginx/sites-enabled /usr/local/bin /var/www /usr/local/etc/php/conf.d /usr/src; \
    cp /files/nginx.conf /etc/nginx/nginx.conf; \
    # cp /files/default /etc/nginx/sites-available/default; \
    cp /files/supervisord.conf /etc/supervisor/conf.d/supervisord.conf; \
    cp /files/default /etc/nginx/sites-enabled/default; \
    cp /files/docker-php-source /usr/local/bin/; \
    cp /files/docker-php-ext-* /usr/local/bin/; \
    # Create nginx-php user 
    adduser -S -D -H -h /var/lib/nginx -s /sbin/nologin -G www-data -g www-data www-data 2>/dev/null; \
    # Create app folder
    chown www-data:www-data /var/www; \
    # Install packages 
    apk add --no-cache supervisor nginx ca-certificates tar xz openssl curl ; \
    # Logging to sys 
    ln -sf /dev/stdout /var/log/nginx/access.log; \
    ln -sf /dev/stderr /var/log/nginx/error.log; \
    # Install PHP
    # Fetch
    apk add --no-cache --virtual .fetch-deps gnupg; \
    cd /usr/src; \
    curl -fsSL -o php.tar.xz "https://www.php.net/distributions/php-8.2.3.tar.xz"; \
    echo "b9b566686e351125d67568a33291650eb8dfa26614d205d70d82e6e92613d457 *php.tar.xz" | sha256sum -c -; \
    curl -fsSL -o php.tar.xz.asc "https://www.php.net/distributions/php-8.2.3.tar.xz.asc"; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "39B641343D8C104B2B146DC3F9C39DC0B9698544" "E60913E4DF209907D8E30D96659A97C9CF2A795A" "1198C0117593497A5EC5C199286AF1F9897469DC"; \
    gpg --batch --verify php.tar.xz.asc php.tar.xz; \
    gpgconf --kill all; \
    rm -rf "$GNUPGHOME"; \
    apk del --no-network .fetch-deps; \
    # Build
    apk add --no-cache --virtual .build-deps \
        autoconf \
		dpkg-dev dpkg \
		file \
		g++ \
		gcc \
		libc-dev \
		make \
		pkgconf \
		re2c \
		argon2-dev \
		coreutils \
		curl-dev \
		gnu-libiconv-dev \
		libsodium-dev \
		libxml2-dev \
		linux-headers \
		oniguruma-dev \
		openssl-dev \
		readline-dev \
		sqlite-dev \
		libpng-dev \
		libjpeg \
		gmp-dev \
		libzip-dev \
		libffi-dev \
		gettext-dev \
		imap-dev \
		icu-dev \
		tidyhtml-dev \
		postgresql-dev \
		libxslt-dev \
	; \
	rm -vf /usr/include/iconv.h; \
	export \
		CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64" \
		CPPFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64" \
		LDFLAGS="-Wl,-O1 -pie" \
	; \
	docker-php-source extract; \
	cd /usr/src/php; \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	./configure \
		--build="$gnuArch" \
		--with-config-file-path="/usr/local/etc/php" \
		--with-config-file-scan-dir="/usr/local/etc/php/conf.d" \
		--enable-option-checking=fatal \
		--with-mhash \
		--with-pic \
		--enable-ftp \
		--enable-mbstring \
		--enable-mysqlnd \
		--with-password-argon2 \
		--with-sodium=shared \
		--with-pdo-sqlite=/usr \
		--with-sqlite3=/usr \
		--with-curl \
		--with-iconv=/usr \
		--with-openssl \
		--with-readline \
		--with-zlib \
		--disable-phpdbg \
		--with-pear \
		$(test "$gnuArch" = 's390x-linux-musl' && echo '--without-pcre-jit') \
		--disable-cgi \
		--enable-fpm \
		--with-fpm-user=www-data \
		--with-fpm-group=www-data \
		# Extensions
		--enable-calendar \
		--enable-exif \
		--with-ffi \
		--enable-bcmath \
		--enable-pcntl \
		--enable-gd \
		--with-gmp \
		--with-zip \
		--with-gettext \
		--with-imap \
		--enable-intl \
		--with-mysqli \
		--with-pdo-mysql \
		--with-pgsql \
		--with-pdo-pgsql \
		--enable-shmop \
		--enable-sysvsem \
		--enable-sysvshm \
		--enable-sysvmsg \
		--with-tidy \
		--with-xsl \
		--enable-sockets \
	; \
	make -j "$(nproc)"; \
	find -type f -name '*.a' -delete; \
	make install; \
	find \
		/usr/local \
		-type f \
		-perm '/0111' \
		-exec sh -euxc ' \
			strip --strip-all "$@" || : \
		' -- '{}' + \
	; \
	make clean; \
	cp -v php.ini-* "/usr/local/etc/php/"; \
	cd /; \
	pecl install igbinary redis; \
	docker-php-ext-enable igbinary redis sodium; \
	docker-php-source delete; \
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-cache $runDeps; \
	apk del --no-network .build-deps; \
	pecl update-channels; \
	rm -rf /tmp/pear ~/.pearrc; \
	php --version; \
	cd /usr/local/etc; \
	# for some reason, upstream's php-fpm.conf.default has "include=NONE/etc/php-fpm.d/*.conf"
	sed 's!=NONE/!=!g' php-fpm.conf.default | tee php-fpm.conf > /dev/null; \
	cp php-fpm.d/www.conf.default php-fpm.d/www.conf; \
	mkdir -p "/usr/local/etc/php/conf.d" /run/php; \
	{ \
		echo '; https://github.com/docker-library/php/issues/878#issuecomment-938595965'; \
		echo 'fastcgi.logging = Off'; \
	} > "/usr/local/etc/php/conf.d/docker-fpm.ini"; \
	cp /files/php/php-fpm.d/* /usr/local/etc/php-fpm.d/; \
    rm -rf /files; \
	cd /var/www;

STOPSIGNAL SIGQUIT

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
