FROM ubuntu:24.04 AS default

LABEL maintainer="Pusparaj Bhattarai"

ARG PHP_VERSION=8.3
ARG NODE_VERSION=22
ARG PGSQL_VERSION=17

WORKDIR /var/www/html

ENV TZ=UTC
ENV EDITOR=vim
ENV WWWUSER=1000
ENV WWWGROUP=1000
ENV COMPOSER_HOME=/home/sail/.composer
ENV PATH="${PATH}:${COMPOSER_HOME}/vendor/bin"
ENV SUPERVISOR_SERVE_COMMAND="/usr/bin/php -d variables_order=EGPCS /var/www/html/artisan serve --host=0.0.0.0 --port=80"
ENV SUPERVISOR_SERVE_USER="sail"

RUN echo "Acquire::http::Pipeline-Depth 0;" > /etc/apt/apt.conf.d/99custom && \
    echo "Acquire::http::No-Cache true;" >> /etc/apt/apt.conf.d/99custom && \
    echo "Acquire::BrokenProxy    true;" >> /etc/apt/apt.conf.d/99custom

RUN apt-get update -q \
    && apt-get -y upgrade \
    && echo ${TZ} > /etc/timezone \
    && ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && apt-get install -y ca-certificates curl dnsutils ffmpeg fswatch git gnupg gosu libcap2-bin libpng-dev librsvg2-bin nano python3 sqlite3 supervisor unzip zip  \
    && mkdir -p ~/.gnupg \
    && chmod 600 ~/.gnupg \
    && echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf \
    && apt-key adv --homedir ~/.gnupg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E5267A6C \
    && apt-key adv --homedir ~/.gnupg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C300EE8C \
    && curl -sS 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x14aa40ec0831756756d7f66c4f4ea0aae5267a6c' | gpg --dearmor | tee /etc/apt/keyrings/ppa_ondrej_php.gpg > /dev/null \
    && echo "deb [signed-by=/etc/apt/keyrings/ppa_ondrej_php.gpg] https://ppa.launchpadcontent.net/ondrej/php/ubuntu noble main" > /etc/apt/sources.list.d/ppa_ondrej_php.list \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update -q \
    && apt-get install -y \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-dev \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-igbinary \
        php${PHP_VERSION}-imagick \
        php${PHP_VERSION}-imap \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-ldap \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-memcached \
        php${PHP_VERSION}-mongodb \
        php${PHP_VERSION}-msgpack \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-pcov \
        php${PHP_VERSION}-pgsql \
        php${PHP_VERSION}-readline \
        php${PHP_VERSION}-redis \
        php${PHP_VERSION}-soap \
        php${PHP_VERSION}-sqlite3 \
        php${PHP_VERSION}-swoole \
        php${PHP_VERSION}-xdebug \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-zip \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -sLS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /etc/apt/keyrings/yarn.gpg >/dev/null \
    && echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
    && curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/keyrings/pgdg.gpg >/dev/null \
    && echo "deb [signed-by=/etc/apt/keyrings/pgdg.gpg] https://apt.postgresql.org/pub/repos/apt noble-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update -q \
    && apt-get install -y mysql-client nodejs postgresql-client-$PGSQL_VERSION vim yarn \
    && apt-get -y upgrade \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update -q \
    && apt-get -y upgrade \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /home/sail/.composer \
    && composer global require laravel/installer

COPY start-container /usr/local/bin/start-container
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY php.ini /etc/php/${PHP_VERSION}/cli/conf.d/99-sail.ini

RUN userdel -r ubuntu \
    && groupadd --force -g ${WWWGROUP} sail \
    && useradd -ms /bin/bash --no-user-group -g ${WWWGROUP} -u ${WWWUSER} sail \
    && setcap "cap_net_bind_service=+ep" /usr/bin/php${PHP_VERSION} \
    && chmod +x /usr/local/bin/start-container

RUN chown -R sail:sail /home/sail

ENTRYPOINT ["start-container"]

FROM default AS mssql

RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/ubuntu/24.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update -q \
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
