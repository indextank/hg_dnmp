ARG PHP_VERSION
FROM php:${PHP_VERSION}-fpm-alpine

ARG PHP_EXTENSIONS
ARG MORE_EXTENSION_INSTALLER
ARG ALPINE_REPOSITORIES

ARG XDEBUG_EXT_VERSION
ARG SWOOLE_EXT_VERSION
ARG GRPC_EXT_VERSION
ARG REDIS_EXT_VERSION
ARG LIBRDKAFKA_VERSION
ARG RDKAFKA_EXT_VERSION
ARG ZOOKEEPER_VERSION
ARG ZOOKEEPER_EXT_VERSION
ARG PROTOBUF_VERSION
ARG SEASLOG_EXT_VERSION
ARG MONGODB_EXT_VERSION

COPY ./build/php/extensions /tmp/extensions
COPY ./src/php /tmp/extensions
WORKDIR /tmp/extensions

ENV EXTENSIONS=",${PHP_EXTENSIONS},"
ENV MC="-j$(nproc)"

ARG CHANGE_SOURCE=false
RUN if [ ${CHANGE_SOURCE} = true ]; then \
    sed -i "s/dl-cdn.alpinelinux.org/${ALPINE_REPOSITORIES}/g" /etc/apk/repositories && \
    apk update && apk add --no-cache tzdata && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone \
;fi

RUN export MC="-j$(nproc)" \
    && chmod +x install.sh \
    && chmod +x "${MORE_EXTENSION_INSTALLER}" \
    && sh install.sh 2>&1 | tee -a /var/www/html/php_alipne_install.log \
    && sh "${MORE_EXTENSION_INSTALLER}" 2>&1 | tee -a /var/www/html/${MORE_EXTENSION_INSTALLER}_install.log \
    && rm -rf /tmp/extensions

WORKDIR /var/www/html