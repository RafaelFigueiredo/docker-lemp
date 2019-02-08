FROM php:7-fpm-alpine

RUN docker-php-ext-install php7-mysqli
