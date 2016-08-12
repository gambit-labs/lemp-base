#!/bin/bash

NGINX_DOMAIN_NAME=${NGINX_DOMAIN_NAME:-localhost}
NGINX_ENABLE_HTTPS=${NGINX_ENABLE_HTTPS:-0}
NGINX_ENABLE_HTTP2=${NGINX_ENABLE_HTTP2:-0}

NGINX_WORKER_PROCESSES=${NGINX_WORKER_PROCESSES:-1}
NGINX_WORKER_CONNECTIONS=${NGINX_WORKER_CONNECTIONS:-1024}

PHP_MAX_EXECUTION_TIME=${PHP_MAX_EXECUTION_TIME:-300}
PHP_MAX_UPLOAD_SIZE=${PHP_MAX_UPLOAD_SIZE:-32}
PHP_TIMEZONE=${PHP_TIMEZONE:-"Europe/Helsinki"}

MAIL_ENABLE=${MAIL_ENABLE:-0}

# If HTTP/2 is used, HTTPS must also be used
if [[ ${NGINX_ENABLE_HTTP2} == 1 ]]; then
	NGINX_ENABLE_HTTPS=1
fi

# Replace dynamic values in the default web site config
sed -e "s|NGINX_WORKER_PROCESSES|${NGINX_WORKER_PROCESSES}|g" -i /etc/nginx/nginx.conf
sed -e "s|NGINX_WORKER_CONNECTIONS|${NGINX_WORKER_CONNECTIONS}|g" -i /etc/nginx/nginx.conf
sed -e "s|PHP_MAX_UPLOAD_SIZE|${PHP_MAX_UPLOAD_SIZE}|g" -i /etc/nginx/nginx.conf

sed -e "s|PHP_MAX_EXECUTION_TIME|${PHP_MAX_EXECUTION_TIME}|g" -i /etc/nginx/php.conf
sed -e "s|PHP_SERVER|${PHP_SERVER:-localhost}|g" -i /etc/nginx/php.conf

sed "/max_execution_time/d;/upload_max_filesize/d;/post_max_size/d;" -i /usr/local/etc/php/php.ini
cat >> /usr/local/etc/php/php.ini <<EOF

; Options that are coming from the gambitlabs/lemp-base entrypoint script
date.timezone = ${PHP_TIMEZONE}
max_execution_time = ${PHP_MAX_EXECUTION_TIME}
upload_max_filesize = ${PHP_MAX_UPLOAD_SIZE}M
post_max_size = $((PHP_MAX_UPLOAD_SIZE+1))M
EOF

# Require those two files
# docker run -d -e NGINX_ENABLE_HTTPS=1 -v $(pwd)/certs:/certs {image_name}
if [[ ${NGINX_ENABLE_HTTPS} == 1 && (! -f ${CERT_DIR}/*.crt || ! -f ${CERT_DIR}/*.key) ]]; then

	echo "Fatal error: Tried to start in https mode but ${CERT_DIR}/*.crt or ${CERT_DIR}/*.key does not exist."
	echo "Those two files are required in order to enable https."
	echo "Exiting..."
	exit 1
fi

# If we've enabled https, an optional dhparam.pem file may be specified for added encryption
# If there is no such file, remove the statement from the config
# Generate with this command: openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048
if [[ ${NGINX_ENABLE_HTTPS} == 1 && ! -f ${CERT_DIR}/dhparam.pem ]]; then
	sed -e "/ssl_dhparam/d" -i /etc/nginx/sites-available/default-https
fi

sed -e "s|WWW_DIR|${WWW_DIR}|g" -i /etc/nginx/sites-available/default-http /etc/nginx/sites-available/default-https
sed -e "s|NGINX_DOMAIN_NAME|${NGINX_DOMAIN_NAME}|g" -i /etc/nginx/sites-available/default-http /etc/nginx/sites-available/default-https
sed -e "s|CERT_DIR|${CERT_DIR}|g" -i /etc/nginx/sites-available/default-https

# Set the http2 directive
if [[ ${NGINX_ENABLE_HTTP2} == 1 ]]; then
	sed -e "s|USE_HTTP2|http2|g" -i /etc/nginx/sites-available/default-https
else
	sed -e "s|USE_HTTP2||g" -i /etc/nginx/sites-available/default-https
fi

# If https is disabled, remove the nginx config for HTTPS
if [[ ${NGINX_ENABLE_HTTPS} == 1 ]]; then
	ln -s /etc/nginx/sites-available/default-https /etc/nginx/sites-enabled/default
else
	ln -s /etc/nginx/sites-available/default-http /etc/nginx/sites-enabled/default
fi

# Make it possible to customize the init logic by executing all .sh files in the override dir.
if [[ ! -z $(ls ${OVERRIDE_INIT_LOGIC_DIR}) ]]; then
	for file in ${OVERRIDE_INIT_LOGIC_DIR}/*.sh; do ${file}; done
fi

# Start PHP 5 in this container if PHP_SERVER is unset
if [[ -z ${PHP_SERVER} ]]; then

	# Start the FastCGI server
	exec php5-fpm &
else
	# Copy over all data to ${PHP_SHARED_WWW_DIR} and symlink ${WWW_DIR} to ${PHP_SHARED_WWW_DIR}
	# Makes it possible to mount ${PHP_SHARED_WWW_DIR} to /var/www/html in the separate PHP container.
	cp -R ${WWW_DIR}/* ${PHP_SHARED_WWW_DIR}
	rm -r ${WWW_DIR}
	ln -s ${PHP_SHARED_WWW_DIR} ${WWW_DIR}
fi

# If we should enable sending mail, run the script. The script will be non-blocking (just run once and then the postfix processes will leave in the background)
if [[ ${MAIL_ENABLE} == 1 ]]; then
	POSTFIX_FOREGROUND=0 /postfix-entrypoint.sh
fi

# Make the user and group www-data own the content. nginx is using that user for displaying content 
chown -R www-data:www-data ${WWW_DIR}

# Start the nginx webserver in foreground mode. The docker container lifecycle will be tied to nginx.
exec nginx -g "daemon off;"
