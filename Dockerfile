FROM debian:jessie
MAINTAINER Petr Vitek "rattus.PV@gmail.com"

ENV DEBIAN_FRONTEND noninteractive

# Basic packages + cleanup
RUN apt-get update && apt-get install -y --no-install-recommends \
	curl \
	nginx \
	php5-cli \
	php5-common \
	php5-curl \
	php5-fpm \
	php5-gd \
	php5-imagick \
	php5-imap \
	php5-json \
	php5-mcrypt \
	php5-memcache \
	php5-pgsql \
	php5-sqlite \
	supervisor && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


RUN echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && \
	chmod +x /usr/sbin/policy-rc.d

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# needed only for mysql
#RUN php5enmod mcrypt

# download and install composer
RUN /usr/bin/curl -sS https://getcomposer.org/installer | /usr/bin/php && \
	/bin/mv composer.phar /usr/local/bin/composer

# Copy nginx and supervisor configuration
COPY ./config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./config/nginx/default /etc/nginx/sites-available/default
COPY ./config/nginx/realip.conf /etc/nginx/conf.d/realip.conf
COPY ./config/supervisor.conf /etc/supervisor/conf.d/supervisord-nginx.conf

# PHP-FPM config 
RUN sed -i 's/memory_limit = .*/memory_limit = 256M/' /etc/php5/fpm/php.ini && \
	sed -i 's/cgi.fix_pathinfo = .*/cgi.fix_pathinfo = 0/' /etc/php5/fpm/php.ini && \
	sed -i 's/upload_max_filesize = .*/upload_max_filesize = 500M/' /etc/php5/fpm/php.ini && \
	sed -i 's/post_max_size = .*/post_max_size = 500M/' /etc/php5/fpm/php.ini

# Startup script
# This startup script wll configure nginx
COPY ./startup.sh /opt/startup.sh
RUN chmod +x /opt/startup.sh

# PHP
COPY ./config/php/www.conf /etc/php5/fpm/pool.d/www.conf
COPY ./config/php/php.ini /etc/php5/fpm/php.ini

RUN mkdir /var/html

RUN usermod -u 1000 www-data && \
	chown -R www-data:www-data /var/html

EXPOSE 80

WORKDIR /var/html

#run supervisord with explicit config file
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord-nginx.conf", "-n"]
