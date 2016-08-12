FROM alpine:3.4

RUN addgroup -S -g 82 www-data && adduser -S -D -u 82 -G www-data www-data

# Use mainline nginx based on the small alpine image
INCLUDE https://raw.githubusercontent.com/nginxinc/docker-nginx/master/mainline/alpine/Dockerfile

# Include the official php 5.6 alpine image
# The wget and include commands will be replaced when processing this template file
WGET https://raw.githubusercontent.com/docker-library/php/master/5.6/fpm/alpine/docker-php-ext-configure
WGET https://raw.githubusercontent.com/docker-library/php/master/5.6/fpm/alpine/docker-php-ext-enable
WGET https://raw.githubusercontent.com/docker-library/php/master/5.6/fpm/alpine/docker-php-ext-install
WGET https://raw.githubusercontent.com/docker-library/php/master/5.6/fpm/alpine/docker-php-source
INCLUDE https://raw.githubusercontent.com/docker-library/php/master/5.6/fpm/alpine/Dockerfile

# Include the PHP extensions
WGET https://raw.githubusercontent.com/gambit-labs/php/master/php-entrypoint.sh
INCLUDE https://raw.githubusercontent.com/gambit-labs/php/master/Dockerfile.php5

# Include the gambitlabs/postfix entrypoint script and install postfix
RUN apk add --update postfix mysql-client
ADD https://raw.githubusercontent.com/gambit-labs/postfix/master/postfix-entrypoint.sh /postfix-entrypoint.sh

ENV WWW_DIR=/var/www/html \
	CERT_DIR=/certs \
	PHP_SHARED_WWW_DIR=/php_html \
	OVERRIDE_INIT_LOGIC_DIR=/docker-entrypoint-init.d

RUN mkdir -p \
		${WWW_DIR} \
		${CERT_DIR} \
		${PHP_SHARED_WWW_DIR} \
		${OVERRIDE_INIT_LOGIC_DIR} \
		/etc/nginx/sites-enabled \
		/var/cache/nginx \
		/etc/nginx/html \
	&& chmod +x /postfix-entrypoint.sh

COPY nginx-conf/nginx.conf nginx-conf/ssl.conf nginx-conf/php.conf /etc/nginx/conf/
COPY nginx-conf/http-default.conf /etc/nginx/sites-available/default-http
COPY nginx-conf/https-default.conf /etc/nginx/sites-available/default-https

# Default; bare PHP(info) config
COPY nginx-conf/default-php.conf /etc/nginx/conf.d/index.conf
COPY index.php /var/www/html/

WORKDIR /var/www/html

# This script is executed by default when the docker container starts
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
