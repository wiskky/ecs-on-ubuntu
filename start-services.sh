#!/bin/bash

# Find the installed PHP-FPM version and start it
# PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
# service php$PHP_VERSION-fpm start

# Start Apache in the foreground so the container stays alive
# exec apache2ctl -D FOREGROUND

set -e

echo "Starting PHP-FPM..."
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
service php${PHP_VERSION}-fpm start

echo "Starting Apache in foreground..."
# Use -D FOREGROUND so the container doesn't exit
exec apache2ctl -D FOREGROUND
