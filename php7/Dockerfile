FROM alpine:3.4

# Include the official php 5.6 alpine image
# The WGET and INCLUDE commands will be replaced when processing this template file
WGET https://raw.githubusercontent.com/docker-library/php/master/5.6/fpm/alpine/docker-php-ext-configure
WGET https://raw.githubusercontent.com/docker-library/php/master/5.6/fpm/alpine/docker-php-ext-enable
WGET https://raw.githubusercontent.com/docker-library/php/master/5.6/fpm/alpine/docker-php-ext-install
WGET https://raw.githubusercontent.com/docker-library/php/master/5.6/fpm/alpine/docker-php-source
INCLUDE https://raw.githubusercontent.com/docker-library/php/master/5.6/fpm/alpine/Dockerfile

# Install required PHP modules
RUN docker-php-ext-install mysql mysqli gd tidy curl json hash