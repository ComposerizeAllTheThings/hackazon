FROM ubuntu:14.04 AS builder
RUN apt update && apt install -y unzip
ADD https://github.com/rapid7/hackazon/archive/master.zip /hackazon-master.zip
RUN unzip /hackazon-master.zip -d hackazon

FROM ubuntu:14.04
RUN apt update \
    && DEBIAN_FRONTEND=noninteractive apt -y --no-install-recommends install \
    apache2 \
    libapache2-mod-php5 \
    mysql-client \
    mysql-server \
    php5-ldap \
    php5-mysql \
    python-setuptools \
    python3-pip \
    pwgen \
    vim-tiny \
    && pip3 install supervisor==4.3.0 \
    && rm -rf /var/lib/apt/lists/*

# setup hackazon
RUN rm -rf /var/www/*
COPY --from=builder /hackazon/hackazon-master/ /var/www/hackazon

RUN cp /var/www/hackazon/assets/config/db.sample.php /var/www/hackazon/assets/config/db.php
RUN cp /var/www/hackazon/assets/config/email.sample.php /var/www/hackazon/assets/config/email.php

ADD ./configs/supervisord.conf /etc/supervisord.conf
ADD ./configs/000-default.conf /etc/apache2/sites-available/000-default.conf
ADD ./configs/parameters.php /var/www/hackazon/assets/config/parameters.php
ADD ./configs/rest.php /var/www/hackazon/assets/config/rest.php
ADD ./configs/createdb.sql /var/www/hackazon/database/createdb.sql

ADD ./scripts/start.sh /start.sh
ADD ./scripts/passwordHash.php /passwordHash.php
ADD ./scripts/foreground.sh /etc/apache2/foreground.sh

RUN chown -R www-data:www-data /var/www/

RUN chmod 755 /start.sh
RUN chmod 755 /etc/apache2/foreground.sh
RUN a2enmod rewrite
RUN mkdir -p /var/log/supervisor/

EXPOSE 80
CMD ["/bin/bash", "/start.sh"]
