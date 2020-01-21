#!/bin/sh

echo
echo "============================================"
echo "Install extensions from   : ${MORE_EXTENSION_INSTALLER}"
echo "PHP version               : ${PHP_VERSION}"
echo "Extra Extensions          : ${PHP_EXTENSIONS}"
echo "Multicore Compilation     : ${MC}"
echo "Work directory            : ${PWD}"
echo "============================================"
echo


if [ -z "${EXTENSIONS##*,mcrypt,*}" ]; then
    echo "---------- Install mcrypt ----------"
    apk update && apk add --no-cache libmcrypt-dev \
    && docker-php-ext-install ${MC} mcrypt
fi


if [ -z "${EXTENSIONS##*,mysql,*}" ]; then
    echo "---------- Install mysql ----------"
    docker-php-ext-install ${MC} mysql
fi


if [ -z "${EXTENSIONS##*,sodium,*}" ]; then
    echo "---------- Install sodium ----------"
    apk update && apk add --no-cache libsodium-dev
	docker-php-ext-install ${MC} sodium
fi

if [ -z "${EXTENSIONS##*,memcached,*}" ]; then
    echo "---------- Install memcached ----------"
	apk update && apk add --no-cache libmemcached-dev zlib-dev
    printf "\n" | pecl install memcached-2.2.0
    docker-php-ext-enable memcached
fi

if [ -z "${EXTENSIONS##*,pdo_sqlsrv,*}" ]; then
    echo "---------- Install pdo_sqlsrv ----------"
	echo "pdo_sqlsrv requires PHP >= 7.1.0, installed version is ${PHP_VERSION}"
fi

if [ -z "${EXTENSIONS##*,sqlsrv,*}" ]; then
    echo "---------- Install sqlsrv ----------"
	echo "pdo_sqlsrv requires PHP >= 7.1.0, installed version is ${PHP_VERSION}"
fi

if [ -z "${EXTENSIONS##*,mongodb,*}" ]; then
    echo "---------- Install mongodb ----------"
    apk update && apk add --no-cache unixodbc-dev
    if [ ! -f mongodb-${MONGODB_EXT_VERSION}.tgz ]; then
        printf "\n" | pecl install mongodb
        docker-php-ext-enable mongodb
    else
        mkdir mongodb \
        && tar -xf mongodb-${MONGODB_EXT_VERSION}.tgz -C mongodb --strip-components=1 \
        && ( cd mongodb && phpize && ./configure && make ${MC} && make install ) \
        && docker-php-ext-enable mongodb
    fi
fi

if [ -z "${EXTENSIONS##*,seaslog,*}" ]; then
    echo "---------- Install seaslog ----------"
    if [ ! -f SeasLog-${SEASLOG_EXT_VERSION}.tgz ]; then
        printf "\n" | pecl install seaslog
        docker-php-ext-enable seaslog
    else
        mkdir seaslog \
        && tar -xf SeasLog-${SEASLOG_EXT_VERSION}.tgz -C seaslog --strip-components=1 \
        && ( cd seaslog && phpize && ./configure && make ${MC} && make install ) \
        && docker-php-ext-enable seaslog
    fi
fi

if [ -z "${EXTENSIONS##*,grpc,*}" ]; then
    echo "---------- Install grpc ----------"
    if [ ! -f grpc-${GRPC_EXT_VERSION}.tgz ]; then
        printf "\n" | pecl install grpc
        docker-php-ext-enable grpc
    else
        mkdir grpc \
        && tar -xf grpc-${GRPC_EXT_VERSION}.tgz -C grpc --strip-components=1 \
        && ( cd grpc && phpize && ./configure && make ${MC} && make install ) \
        && docker-php-ext-enable grpc
    fi
fi

if [ -z "${EXTENSIONS##*,xdebug,*}" ]; then
    echo "---------- Install xdebug ----------"
    if [ ! -f xdebug-${XDEBUG_EXT_VERSION}.tgz ]; then
        printf "\n" | pecl install xdebug
        docker-php-ext-enable xdebug
    else
        mkdir xdebug \
        && tar -xf xdebug-${XDEBUG_EXT_VERSION}.tgz -C xdebug --strip-components=1 \
        && ( cd xdebug && phpize && ./configure && make ${MC} && make install ) \
        && docker-php-ext-enable xdebug
    fi
fi

if [ -z "${EXTENSIONS##*,redis,*}" ]; then
    echo "---------- Install redis ----------"
    if [ ! -f redis-${REDIS_EXT_VERSION}.tgz ]; then
        printf "\n" | pecl install redis
        docker-php-ext-enable redis
    else
        mkdir redis \
        && tar -xf redis-${REDIS_EXT_VERSION}.tgz -C redis --strip-components=1 \
        && ( cd redis && phpize && ./configure && make ${MC} && make install ) \
        && docker-php-ext-enable redis
    fi
fi

if [ -z "${EXTENSIONS##*,swoole,*}" ]; then
    echo "---------- Install swoole ----------"
    if [ ! -f swoole-${SWOOLE_EXT_VERSION}.tgz ]; then
        printf "\n" | pecl install swoole-${SWOOLE_EXT_VERSION}
        docker-php-ext-enable swoole
    else
        mkdir swoole \
        && tar -xf swoole-${SWOOLE_EXT_VERSION}.tgz -C swoole --strip-components=1 \
        && ( cd swoole && phpize && ./configure --enable-openssl && make ${MC} && make install ) \
        && docker-php-ext-enable swoole
    fi
fi

if [ -z "${EXTENSIONS##*,rdkafka,*}" ]; then
    echo "---------- Install rdkafka ----------"
    # if [ ! -f librdkafka-${LIBRDKAFKA_VERSION}.tar.gz ]; then
    #     apk update \
    #     && apk add --no-cache wget \
    #     wget --no-check-certificate https://codeload.github.com/edenhill/librdkafka/tar.gz/v${LIBRDKAFKA_VERSION} -O librdkafka-${LIBRDKAFKA_VERSION}.tar.gz
    # fi

    # mkdir librdkafka \
    # && tar -xf librdkafka-${LIBRDKAFKA_VERSION}.tar.gz -C librdkafka --strip-components=1 \
    # && ( cd librdkafka && ./configure && make ${MC} && make install && cd .. && rm -fr librdkafka )
    apk update && apk add --no-cache librdkafka librdkafka-dev
 
    if [ ! -f rdkafka-${RDKAFKA_EXT_VERSION}.tgz ]; then
        printf "\n" | pecl install rdkafka
        docker-php-ext-enable rdkafka
    else
        mkdir rdkafka \
        && tar -xf rdkafka-${RDKAFKA_EXT_VERSION}.tgz -C rdkafka --strip-components=1 \
        && ( cd rdkafka && phpize && ./configure && make ${MC} && make install && cd .. && rm -fr rdkafka ) \
        && docker-php-ext-enable rdkafka
    fi
fi