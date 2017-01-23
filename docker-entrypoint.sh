#!/bin/bash

NGINX_DOMAIN_NAME=${NGINX_DOMAIN_NAME:-localhost}
NGINX_ENABLE_HTTPS=${NGINX_ENABLE_HTTPS:-0}
NGINX_ENABLE_HTTP2=${NGINX_ENABLE_HTTP2:-0}

NGINX_WORKER_PROCESSES=${NGINX_WORKER_PROCESSES:-1}
NGINX_WORKER_CONNECTIONS=${NGINX_WORKER_CONNECTIONS:-1024}

# This is the root nginx conf file
NGINX_CONF="/etc/nginx/conf/nginx.conf"
# This is the main nginx server{} directive file
WEB_CONF="/etc/nginx/conf.d/default-web"

# Get PHP variables and write the right things to php.ini with this script
export PHP_DO_NOT_EXECUTE=1
source /php-entrypoint.sh

MAIL_ENABLE=${MAIL_ENABLE:-0}

# If HTTP/2 is used, HTTPS must also be used
if [[ ${NGINX_ENABLE_HTTP2} == 1 ]]; then
	NGINX_ENABLE_HTTPS=1
fi

# Replace dynamic values in the default web site config
sed -e "s|NGINX_WORKER_PROCESSES|${NGINX_WORKER_PROCESSES}|g" -i ${NGINX_CONF}
sed -e "s|NGINX_WORKER_CONNECTIONS|${NGINX_WORKER_CONNECTIONS}|g" -i ${NGINX_CONF}
sed -e "s|PHP_MAX_UPLOAD_SIZE|${PHP_MAX_UPLOAD_SIZE}|g" -i ${NGINX_CONF}

sed -e "s|PHP_MAX_EXECUTION_TIME|${PHP_MAX_EXECUTION_TIME}|g" -i /etc/nginx/conf/php.conf
sed -e "s|PHP_SERVER|${PHP_SERVER:-"localhost:9000"}|g" -i /etc/nginx/conf/php.conf

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
	sed -e "/ssl_dhparam/d" -i /etc/nginx/conf/default-https.conf
fi

sed -e "s|WWW_DIR|${WWW_DIR}|g;s|NGINX_DOMAIN_NAME|${NGINX_DOMAIN_NAME}|g;s|CERT_DIR|${CERT_DIR}|g" -i \
	/etc/nginx/conf/default-http.conf \
	/etc/nginx/conf/default-https.conf

# Set the http2 directive
if [[ ${NGINX_ENABLE_HTTP2} == 1 ]]; then
	sed -e "s|USE_HTTP2|http2|g" -i /etc/nginx/conf/default-https.conf
else
	sed -e "s|USE_HTTP2||g" -i /etc/nginx/conf/default-https.conf
fi

# If https is disabled, remove the nginx config for HTTPS
if [[ ${NGINX_ENABLE_HTTPS} == 1 ]]; then
	ln -s /etc/nginx/conf/default-https.conf ${WEB_CONF}
else
	ln -s /etc/nginx/conf/default-http.conf ${WEB_CONF}
fi

# Make it possible to customize the init logic by executing all .sh files in the override dir.
if [[ ! -z $(ls ${OVERRIDE_INIT_LOGIC_DIR}) ]]; then
	for file in ${OVERRIDE_INIT_LOGIC_DIR}/*.sh; do ${file}; done
fi

# If no arguments were passed to the container; start nginx, php and maybe mail
if [[ $# == 0 ]]; then

	# Also start cron.
	if [[ ${CRON_ENABLE} == 1 ]]; then
		/usr/sbin/crond
	fi

	# Start PHP 5 in this container if PHP_SERVER is unset
	if [[ -z ${PHP_SERVER} ]]; then

		# Start the FastCGI server
		exec php-fpm &
	else
		# Copy over all data to ${PHP_SHARED_WWW_DIR} and symlink ${WWW_DIR} to ${PHP_SHARED_WWW_DIR}
		# Makes it possible to mount ${PHP_SHARED_WWW_DIR} to /var/www/html in the separate PHP container.
		cp -r ${WWW_DIR}/* ${PHP_SHARED_WWW_DIR}
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
elif [[ $# == 1 && $1 == "help" || $1 == "usage" ]]; then
	cat <<-EOF
	Supported nginx variables and their defaults:
	 - NGINX_DOMAIN_NAME=${NGINX_DOMAIN_NAME}: The domain name that nginx should listen to. May be a string with several whitespace-separated domain names.
	 - NGINX_WORKER_PROCESSES=${NGINX_WORKER_PROCESSES}: The amount of worker processes nginx should spawn.
	 - NGINX_WORKER_CONNECTIONS=${NGINX_WORKER_CONNECTIONS}: The amount of worker connections one process may have open at a given time.

	nginx version: $(nginx -v 2>&1 | awk '{print $3}' | cut -d/ -f2)
	mysql client version: $(mysql --version | awk '{print $5}' | cut -d- -f1)

	Enabled/disabled features:
	 - NGINX_ENABLE_HTTPS=${NGINX_ENABLE_HTTPS}: If HTTPS should be enabled.
	 - NGINX_ENABLE_HTTP2=${NGINX_ENABLE_HTTP2}: If HTTP 2.0 should be enabled.
	 - PHP_SERVER=${PHP_SERVER}: The PHP server nginx should pass requests to. Defaults to "", which means it will use the built-in PHP server.
	 - MAIL_ENABLE=${MAIL_ENABLE}: If postfix should be enabled

	$(php_usage)

	$(/postfix-entrypoint.sh usage)
	EOF
else
	exec $@
fi
