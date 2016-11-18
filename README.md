## lemp-base - The ultimate base image for your dockerized PHP application

This is a base image for containerized PHP applications.

### Plain sample usage:

```console
$ docker run -d -p 80:80 gambitlabs/lemp-base:v0.4.0
```

This will run a webserver on `localhost` that is serving one page only:

```php
<?php
phpinfo();

```

with this nginx configuration:
```nginx
location / {
	include /etc/nginx/conf/php.conf;
}
```

Very straightforward. In order to produce a new image with the two above files, just do this:
```Dockerfile
FROM gambitlabs/lemp-base:v0.4.0
COPY nginx-conf/default-php.conf /etc/nginx/conf.d/index.conf
COPY index.php /var/www/html
```

### What's in it:

 - PHP 5.6
 - nginx 1.11.5
 - mysql
 - postfix

### Features

In order to discover all the features this image has, run the help command, and it will produce output like this:

```console
$ docker run -it gambitlabs/lemp-base:v0.4.0 help
Supported nginx variables and their defaults:
 - NGINX_DOMAIN_NAME=localhost: The domain name that nginx should listen to. May be a string with several whitespace-separated domain names.
 - NGINX_WORKER_PROCESSES=1: The amount of worker processes nginx should spawn.
 - NGINX_WORKER_CONNECTIONS=1024: The amount of worker connections one process may have open at a given time. 

nginx version: 1.11.5
mysql client version: 10.1.18

Enabled/disabled features:
 - NGINX_ENABLE_HTTPS=0: If HTTPS should be enabled.
 - NGINX_ENABLE_HTTP2=0: If HTTP 2.0 should be enabled.
 - PHP_SERVER=: The PHP server nginx should pass requests to. Defaults to "", which means it will use the current.
 - MAIL_ENABLE=0: If postfix should be enabled

Supported PHP variables and their defaults:
 - PHP_MAX_EXECUTION_TIME=300: How many seconds a PHP request may take before it should timeout.
 - PHP_MAX_UPLOAD_SIZE=32: How many megabytes an user is allowed to upload to the server.
 - PHP_TIMEZONE=Europe/Helsinki: The timezone that should be set

PHP version: 5.6.28

Supported postfix variables and their defaults:
 - POSTFIX_DOMAIN: Mandatory. Which domain postfix should pretend to send from.
 - POSTFIX_SMTP_SERVER: Mandatory. The smtp server postfix should forward mail to.
 - POSTFIX_SMTP_PORT=25: The port of the smtp server.
 - POSTFIX_LOGIN_EMAIL=: The email address that should be used for login to the server.
 - POSTFIX_LOGIN_PASSWORD=: The password that should be used for login to the server.
 - POSTFIX_USE_TLS=0: If tls should be used.
 - POSTFIX_USE_PLAIN_ONLY=0: Makes postfix authenticate with the server via the PLAIN method. 
 - POSTFIX_FOREGROUND=1: If this script should loop endlessly after postfix is started.

postfix version: 3.1.1
```

### Filesystem layout

WWW directory: `/var/www/html`. Here you should put all your website's data and nginx will serve it.
nginx configuration directory: `/etc/nginx/conf.d`. Here you should put your website's `location` directives.
Certificates directory: `/certs`. If you enable HTTPS or HTTP2, you should volume-mount in `/certs/site.crt` as the certificate and `/certs/site.key` as the private key. Optional file for even more security is `/certs/dhparam.pem` that nginx will use if present.

#### And more!

TODO: More documentation would be nice!

### License

MIT
