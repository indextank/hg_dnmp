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



if [ -z "${EXTENSIONS##*,gd,*}" ]; then
    echo "---------- Install gd ----------"
    apk update \
    && apk add --no-cache freetype freetype-dev jpeg jpeg-dev libjpeg libjpeg-turbo libjpeg-turbo-dev libpng-dev libwebp libwebp-dev \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-webp-dir=/usr/include/ \
    && docker-php-ext-install ${MC} gd
fi

if [ -z "${EXTENSIONS##*,mcrypt,*}" ]; then
    echo "---------- mcrypt was REMOVED from PHP 7.2.0 ----------"
fi


if [ -z "${EXTENSIONS##*,mysql,*}" ]; then
    echo "---------- mysql was REMOVED from PHP 7.0.0 ----------"
fi


if [ -z "${EXTENSIONS##*,sodium,*}" ]; then
    echo "---------- Install sodium ----------"
    echo "Sodium is bundled with PHP from PHP 7.2.0 "
fi

if [ -z "${EXTENSIONS##*,memcached,*}" ]; then
    echo "---------- Install memcached ----------"
	apk update && apk add --no-cache libmemcached-dev zlib-dev
    printf "\n" | pecl install memcached-3.1.3
    docker-php-ext-enable memcached
fi

if [ -z "${EXTENSIONS##*,pdo_sqlsrv,*}" ]; then
    echo "---------- Install pdo_sqlsrv ----------"
	apk update && apk add --no-cache unixodbc-dev
    pecl install pdo_sqlsrv
    docker-php-ext-enable pdo_sqlsrv
fi

if [ -z "${EXTENSIONS##*,sqlsrv,*}" ]; then
    echo "---------- Install sqlsrv ----------"
	apk update && apk add --no-cache unixodbc-dev
    printf "\n" | pecl install sqlsrv
    docker-php-ext-enable sqlsrv
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

if [ -z "${EXTENSIONS##*,solr,*}" ]; then
    echo "---------- Install solr ----------"
    if [ ! -f solr-${SOLR_EXT_VERSION}.tgz ]; then
        printf "\n" | pecl install solr
        docker-php-ext-enable solr
    else
        mkdir solr \
        && apk update \
        && apk add --no-cache gnutls-dev -y \
        && tar -xf solr-${SOLR_EXT_VERSION}.tgz -C solr --strip-components=1 \
        && ( cd solr && phpize && ./configure && make ${MC} && make install ) \
        && docker-php-ext-enable solr
    fi
fi

if [ -z "${EXTENSIONS##*,zookeeper,*}" ]; then
    echo "---------- Install zookeeper ----------"
    apk update \
    && apk add --no-cache wget re2c autoconf libtool automake cppunit cppunit-dev file

    if [ ! -f apache-zookeeper-${ZOOKEEPER_VERSION}.tar.gz ]; then
        wget --no-check-certificate -c https://mirrors.tuna.tsinghua.edu.cn/apache/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/apache-zookeeper-${ZOOKEEPER_VERSION}.tar.gz
    fi

    if [ ! -f zookeeper-${ZOOKEEPER_EXT_VERSION}.tgz ];then
        wget --no-check-certificate -c https://pecl.php.net/get/zookeeper-${ZOOKEEPER_EXT_VERSION}.tgz
    fi

    mkdir zookeeper \
    && tar -xf apache-zookeeper-${ZOOKEEPER_VERSION}.tar.gz -C zookeeper --strip-components=1 \
    && ( cd zookeeper/zookeeper-client/zookeeper-client-c && autoreconf -if && ACLOCAL="aclocal -I /usr/share/aclocal" autoreconf -if && ./configure --prefix=/usr/local/zookeeper && make CFLAGS="-Wno-error" ${MC} && make install ) \
    && mkdir zookeeper-ext \
    && tar -xf zookeeper-${ZOOKEEPER_EXT_VERSION}.tgz -C zookeeper-ext --strip-components=1 \
    && ( cd zookeeper-ext && phpize && ./configure --with-libzookeeper-dir=/usr/local/zookeeper && make ${MC} && make install ) \
    && docker-php-ext-enable zookeeper
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
        printf "\n" | pecl install swoole
        docker-php-ext-enable swoole
    else
        mkdir swoole \
        && tar -xf swoole-${SWOOLE_EXT_VERSION}.tgz -C swoole --strip-components=1 \
        && ( cd swoole && phpize && ./configure --enable-openssl && make ${MC} && make install ) \
        && docker-php-ext-enable swoole
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

if [ -z "${EXTENSIONS##*,rdkafka,*}" ]; then
    echo "---------- Install rdkafka ----------"
    if [ ! -f librdkafka-${LIBRDKAFKA_VERSION}.tar.gz ]; then
        apk update \
        && apk add --no-cache wget \
        wget --no-check-certificate -c https://codeload.github.com/edenhill/librdkafka/tar.gz/v${LIBRDKAFKA_VERSION} -O librdkafka-${LIBRDKAFKA_VERSION}.tar.gz
    fi

    mkdir librdkafka \
    && tar -xf librdkafka-${LIBRDKAFKA_VERSION}.tar.gz -C librdkafka --strip-components=1 \
    && ( cd librdkafka && ./configure && make ${MC} && make install && cd .. && rm -fr librdkafka )

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

if [ -z "${EXTENSIONS##*,protobuf,*}" ]; then
    echo "---------- Install protobuf ----------"
    # install protobuf
    if [ ! -f protobuf-all-${PROTOBUF_VERSION}.tar.gz ]; then
        apk update \
        && apk add --no-cache wget re2c \
        && wget --no-check-certificate -c https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/protobuf-all-${PROTOBUF_VERSION}.tar.gz
    fi

    mkdir protobuf-all \
    && tar -xf protobuf-all-${PROTOBUF_VERSION}.tar.gz -C protobuf-all --strip-components=1 \
    && ( cd protobuf-all && ./configure && make ${MC} && make install && cd .. && rm -fr protobuf-all )

    # install protobuf ext
    if [ ! -f protobuf-${PROTOBUF_VERSION}.tgz ]; then
        printf "\n" | pecl install protobuf-${PROTOBUF_VERSION}
        docker-php-ext-enable protobuf
    else
        mkdir protobuf \
        && tar -xf protobuf-${PROTOBUF_VERSION}.tgz -C protobuf --strip-components=1 \
        && ( cd protobuf && phpize && ./configure && make ${MC} && make install && cd .. && rm -fr protobuf ) \
        && docker-php-ext-enable protobuf
    fi
fi