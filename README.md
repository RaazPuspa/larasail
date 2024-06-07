## Larasail

Larasail provides a pre-built image to start developing applications with Laravel Sail.

### Laravel Sail

> Sail provides a Docker powered local development experience for Laravel that is compatible with macOS, Windows (WSL2),
> and Linux. Other than Docker, no software or libraries are required to be installed on your local computer before
> using
> Sail. Sail's simple CLI means you can start building your Laravel application without any previous Docker experience.
>
> [GitHub](https://github.com/laravel/sail) | [Docs](https://laravel.com/docs/9.x/sail)

### Prerequisite

As _Larasail_ works best with Laravel Sail, it is recommended to install it within your project using composer.

```shell
composer require --dev laravel/sail
```

### How to use

#### Project root

With Larasail, your project root must be mapped into `/var/www/html` directory of the image.

#### Working directory

Larasail has been configured with `/var/www/html` as the default working directory.

#### Standalone execution

Using the larasail image to serve your Laravel project is simple:

```shell
docker run -d -p 8000:80 -v $(pwd):/var/www/html raazpuspa/larasail:tag
```

#### via [docker-composer](https://github.com/docker/compose)

Example `docker-compose.yml`

```yaml
version: '3.1'
services:
  laravel.test:
    image: raazpuspa/larasail:tag
    container_name: webserver
    extra_hosts:
      - 'host.docker.internal:host-gateway'
    ports:
      - '${APP_PORT:-80}:80'
      - '${VITE_PORT:-5173}:${VITE_PORT:-5173}'
    environment:
      LARAVEL_SAIL: 1
      WWWUSER: '${WWWUSER:-1000}'
      WWWGROUP: '${WWWGROUP:-1000}'
      XDEBUG_MODE: '${SAIL_XDEBUG_MODE:-off}'
      XDEBUG_CONFIG: '${SAIL_XDEBUG_CONFIG:-client_host=host.docker.internal}'
    volumes:
      - '.:/var/www/html'
    networks:
      - internal

networks:
  internal:
    driver: bridge
```

### Environment variables

| Variable | Default | Description                                              |
|----------|---------|----------------------------------------------------------|
| TZ       | UTC     | define timezone of the underlying unix system            |
| EDITOR   | vim     | define default editor application for the system         |
| WWWUSER  | 1000    | define ID for the current user of local machine          |
| WWWGROUP | 1000    | define ID for the group of current user of local machine |

### What's included

All available tags of larasail includes PHP of selected version and following packages:

- Composer (v2.7.6)
- Curl (v7.81.0)
- Git (v2.34.1)
- Laravel Installer (v5.8.2)
- Node (v20.14.0)
- NPM (v10.7.0)
- Supervisord (v4.2.1)
- Unzip (v6.0)
- Vim (v8.2)
- Yarn (v1.22.22)
- Zip (v3.0)

#### PHP Extensions

Following extensions are available in every tag:

- `php-bcmath`
- `php-cli`
- `php-curl`
- `php-dev`
- `php-gd`
- `php-igbinary`
- `php-imap`
- `php-intl`
- `php-ldap`
- `php-mbstring`
- `php-memcached`
- `php-msgpack`
- `php-mysql`
- `php-pcov`
- `php-pgsql`
- `php-readline`
- `php-redis`
- `php-soap`
- `php-sqlite3`
- `php-xdebug`
- `php-xml`
- `php-zip`

#### MS SQL Server support

All tags include support for MS-SQL Server:

- `unixodbc`
- `php-sybase`
- `php-sqlsrv`
- `pdo_sqlsrv`

#### PDF Generation

The [wkhtmltopdf](https://wkhtmltopdf.org) is available with all `wkhtml` versions.
