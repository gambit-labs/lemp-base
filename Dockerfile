FROM alpine:3.4

# Use mainline nginx based on the small alpine image
INCLUDE https://raw.githubusercontent.com/nginxinc/docker-nginx/master/mainline/alpine/Dockerfile

# Include the official php 5.6 alpine image
# The wget and include commands will be replaced when processing this template file
WGET https://raw.githubusercontent.com/docker-library/php/master/5.6/fpm/alpine/docker-php-ext-configure
WGET https://raw.githubusercontent.com/docker-library/php/master/5.6/fpm/alpine/docker-php-ext-enable
WGET https://raw.githubusercontent.com/docker-library/php/master/5.6/fpm/alpine/docker-php-ext-install
WGET https://raw.githubusercontent.com/docker-library/php/master/5.6/fpm/alpine/docker-php-source
INCLUDE https://raw.githubusercontent.com/docker-library/php/master/5.6/fpm/alpine/Dockerfile

# Install required PHP modules
RUN docker-php-ext-install \
	mysql \
	mysqli \
	gd \
	tidy \
	curl \
	json \
	hash

# Add necessary packages
RUN apk add --update \
	postfix \
	ca-certificates \
	bash \
	patch \
	curl \
	git

# Include the gambitlabs/postfix entrypoint script and the production php.ini configuration
ADD https://raw.githubusercontent.com/gambit-labs/postfix/master/docker-entrypoint.sh /postfix-entrypoint.sh
ADD https://raw.githubusercontent.com/php/php-src/PHP-5.6/php.ini-production /usr/local/etc/php/php.ini

ENV SOURCE_DIR=/source \
	WWW_DIR=/var/www/html \
	CERT_DIR=/certs \
	PHP_SHARED_WWW_DIR=/php_html \
	OVERRIDE_INIT_LOGIC_DIR=/docker-entrypoint-init.d

RUN mkdir -p ${SOURCE_DIR} ${WWW_DIR} ${CERT_DIR} ${PHP_SHARED_WWW_DIR} /etc/nginx/sites-enabled

COPY nginx/nginx.conf nginx/silverstripe.conf nginx/ssl.conf nginx/php.conf /etc/nginx/
COPY nginx/http-default.conf /etc/nginx/sites-available/default-http
COPY nginx/https-default.conf /etc/nginx/sites-available/default-https

# This script is executed by default when the docker container starts
COPY docker-entrypoint.sh /
CMD ["/docker-entrypoint.sh"]
