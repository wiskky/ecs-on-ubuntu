#!/bin/bash

# Find the installed PHP-FPM version and start it
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
service php$PHP_VERSION-fpm start

# Start Apache in the foreground so the container stays alive
exec apache2ctl -D FOREGROUND
