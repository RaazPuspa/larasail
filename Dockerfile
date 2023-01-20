FROM ubuntu:22.04 as default

LABEL maintainer="Pusparaj Bhattarai"

ARG PHP_VERSION=8.2
ARG NODE_VERSION=19

WORKDIR /var/www/html

ENV TZ UTC
ENV EDITOR vim
ENV WWWUSER 1000
ENV WWWGROUP 1000

RUN apt-get update \
    && apt-get -y upgrade \
    && echo ${TZ} > /etc/timezone \
    && ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && apt-get install -y ca-certificates curl git gnupg gosu libcap2-bin libpng-dev python2 sqlite3 supervisor unzip zip \
    && mkdir -p ~/.gnupg \
    && chmod 600 ~/.gnupg \
    && echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf \
    && apt-key adv --homedir ~/.gnupg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E5267A6C \
    && apt-key adv --homedir ~/.gnupg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C300EE8C \
    && echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu jammy main" > /etc/apt/sources.list.d/ppa_ondrej_php.list \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update \
    && apt-get install -y \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-dev \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-igbinary \
        php${PHP_VERSION}-imap \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-ldap \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-memcached \
        php${PHP_VERSION}-msgpack \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-pcov \
        php${PHP_VERSION}-pgsql \
        php${PHP_VERSION}-readline \
        php${PHP_VERSION}-redis \
        php${PHP_VERSION}-soap \
        php${PHP_VERSION}-sqlite3 \
        php${PHP_VERSION}-xdebug \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-zip \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash - \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y mysql-client nodejs postgresql-client vim yarn \
    && apt-get -y upgrade \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY start-container /usr/local/bin/start-container
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY php.ini /etc/php/${PHP_VERSION}/cli/conf.d/99-sail.ini

RUN groupadd --force -g ${WWWGROUP} sail \
    && useradd -ms /bin/bash --no-user-group -g ${WWWGROUP} -u ${WWWUSER} sail \
    && setcap "cap_net_bind_service=+ep" /usr/bin/php${PHP_VERSION} \
    && chmod +x /usr/local/bin/start-container

ENTRYPOINT ["start-container"]

FROM default as sqlsrv

RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql18 \
    && ACCEPT_EULA=Y apt-get install -y mssql-tools18 \
    && export PATH="${PATH}:/opt/mssql-tools18/bin" \
    && apt-get install -y freetds-common freetds-bin unixodbc php${PHP_VERSION}-sybase \
    && apt-get install -y unixodbc-dev \
    && pecl install sqlsrv \
    && pecl install pdo_sqlsrv \
    && phpenmod -v ${PHP_VERSION} sqlsrv pdo_sqlsrv \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

FROM default as wkhtml

RUN apt-get update \
    && apt-get install -y wget \
    && wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb \
    && apt-get install ./wkhtmltox_0.12.6.1-2.jammy_amd64.deb -y \
    && rm wkhtmltox_0.12.6.1-2.jammy_amd64.deb \
    && apt-get install fonts-indic -y \
    && fc-cache -f \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

FROM sqlsrv as sqlsrv-wkhtml

RUN apt-get update \
    && apt-get install -y wget \
    && wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb \
    && apt-get install ./wkhtmltox_0.12.6.1-2.jammy_amd64.deb -y \
    && rm wkhtmltox_0.12.6.1-2.jammy_amd64.deb \
    && apt-get install fonts-indic -y \
    && fc-cache -f \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
