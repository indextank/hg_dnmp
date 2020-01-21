#!/bin/sh

echo
echo "============================================"
echo "Install extensions from   : php74-debian.sh"
echo "PHP version               : ${PHP_VERSION}"
echo "Extra Extensions          : ${PHP_EXTENSIONS}"
echo "Multicore Compilation     : ${MC}"
echo "Work directory            : ${PWD}"
echo "============================================"
echo


# Composer
# echo "---------- Install Composer ----------"
# php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
# && php composer-setup.php \
# && php -r "unlink('composer-setup.php');" \
# && mv composer.phar /bin/composer \
# && composer config -g repo.packagist composer https://packagist.phpcomposer.com


cd /tmp/extensions

if [ "${PHP_EXTENSIONS}" != "" ]; then
    echo "---------- Install general dependencies ----------"
    apt-get update \
    && apt-get install -y --assume-yes apt-utils wget gcc g++ make cmake autoconf automake libtool libssl-dev libpq-dev
fi

# Install gd for Webp plugin
echo "---------- Install Webp plugin ----------"
if [ ! -f libwebp-${LIBWEBP_VERSION}.tar.gz ]; then
    wget --no-check-certificate -c https://github.com/webmproject/libwebp/archive/v${LIBWEBP_VERSION}.tar.gz -O libwebp-${LIBWEBP_VERSION}.tar.gz
fi

if [ -f libwebp-${LIBWEBP_VERSION}.tar.gz ]; then
    tar -xf libwebp-${LIBWEBP_VERSION}.tar.gz \
        && rm libwebp-${LIBWEBP_VERSION}.tar.gz \
        && ( cd libwebp-${LIBWEBP_VERSION} && ./autogen.sh && ./configure && make && make install ) \
        && rm -r libwebp-${LIBWEBP_VERSION}
fi

if [ -z "${EXTENSIONS##*,gd,*}" ]; then
    echo "---------- Install gd ----------"
    apt-get install -y apt-utils libfreetype6-dev libjpeg62-turbo-dev libpng-dev libzip-dev libvpx-dev libwebp-dev webp \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install ${MC} gd
    # && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-webp-dir=/usr/include/ \
    # && docker-php-ext-install ${MC} gd
fi

if [ -z "${EXTENSIONS##*,pdo_mysql,*}" ]; then
    echo "---------- Install pdo_mysql ----------"
    docker-php-ext-install ${MC} pdo_mysql
fi

if [ -z "${EXTENSIONS##*,zip,*}" ]; then
    echo "---------- Install zip ----------"
	docker-php-ext-install ${MC} zip
fi

if [ -z "${EXTENSIONS##*,pcntl,*}" ]; then
    echo "---------- Install pcntl ----------"
	docker-php-ext-install ${MC} pcntl
fi

if [ -z "${EXTENSIONS##*,mysqli,*}" ]; then
    echo "---------- Install mysqli ----------"
	docker-php-ext-install ${MC} mysqli
fi

if [ -z "${EXTENSIONS##*,mbstring,*}" ]; then
    echo "---------- Install mbstring ----------"
	docker-php-ext-install ${MC} mbstring
fi

if [ -z "${EXTENSIONS##*,exif,*}" ]; then
    echo "---------- Install exif ----------"
	docker-php-ext-install ${MC} exif
fi

if [ -z "${EXTENSIONS##*,bcmath,*}" ]; then
    echo "---------- Install bcmath ----------"
	docker-php-ext-install ${MC} bcmath
fi

if [ -z "${EXTENSIONS##*,calendar,*}" ]; then
    echo "---------- Install calendar ----------"
	docker-php-ext-install ${MC} calendar
fi

if [ -z "${EXTENSIONS##*,zend_test,*}" ]; then
    echo "---------- Install zend_test ----------"
	docker-php-ext-install ${MC} zend_test
fi

if [ -z "${EXTENSIONS##*,opcache,*}" ]; then
    echo "---------- Install opcache ----------"
    docker-php-ext-install opcache
fi

if [ -z "${EXTENSIONS##*,sockets,*}" ]; then
    echo "---------- Install sockets ----------"
	docker-php-ext-install ${MC} sockets
fi

if [ -z "${EXTENSIONS##*,gettext,*}" ]; then
    echo "---------- Install gettext ----------"
	docker-php-ext-install ${MC} gettext
fi

if [ -z "${EXTENSIONS##*,shmop,*}" ]; then
    echo "---------- Install shmop ----------"
	docker-php-ext-install ${MC} shmop
fi

if [ -z "${EXTENSIONS##*,sysvmsg,*}" ]; then
    echo "---------- Install sysvmsg ----------"
	docker-php-ext-install ${MC} sysvmsg
fi

if [ -z "${EXTENSIONS##*,sysvsem,*}" ]; then
    echo "---------- Install sysvsem ----------"
	docker-php-ext-install ${MC} sysvsem
fi

if [ -z "${EXTENSIONS##*,sysvshm,*}" ]; then
    echo "---------- Install sysvshm ----------"
	docker-php-ext-install ${MC} sysvshm
fi

if [ -z "${EXTENSIONS##*,pdo_firebird,*}" ]; then
    echo "---------- Install pdo_firebird ----------"
	docker-php-ext-install ${MC} pdo_firebird
fi

if [ -z "${EXTENSIONS##*,pdo_dblib,*}" ]; then
    echo "---------- Install pdo_dblib ----------"
	docker-php-ext-install ${MC} pdo_dblib
fi

if [ -z "${EXTENSIONS##*,pdo_oci,*}" ]; then
    echo "---------- Install pdo_oci ----------"
	docker-php-ext-install ${MC} pdo_oci
fi

if [ -z "${EXTENSIONS##*,pdo_odbc,*}" ]; then
    echo "---------- Install pdo_odbc ----------"
	docker-php-ext-install ${MC} pdo_odbc
fi

if [ -z "${EXTENSIONS##*,pdo_pgsql,*}" ]; then
    echo "---------- Install pdo_pgsql ----------"
    docker-php-ext-install ${MC} pdo_pgsql
fi

if [ -z "${EXTENSIONS##*,pgsql,*}" ]; then
    echo "---------- Install pgsql ----------"
    docker-php-ext-install ${MC} pgsql
fi

if [ -z "${EXTENSIONS##*,oci8,*}" ]; then
    echo "---------- Install oci8 ----------"
	docker-php-ext-install ${MC} oci8
fi

if [ -z "${EXTENSIONS##*,odbc,*}" ]; then
    echo "---------- Install odbc ----------"
	docker-php-ext-install ${MC} odbc
fi

if [ -z "${EXTENSIONS##*,dba,*}" ]; then
    echo "---------- Install dba ----------"
	docker-php-ext-install ${MC} dba
fi

if [ -z "${EXTENSIONS##*,interbase,*}" ]; then
    echo "---------- Install interbase ----------"
    echo "Alpine linux do not support interbase/firebird!!!"
	#docker-php-ext-install ${MC} interbase
fi

if [ -z "${EXTENSIONS##*,intl,*}" ]; then
    echo "---------- Install intl ----------"
    docker-php-ext-install ${MC} intl
fi

if [ -z "${EXTENSIONS##*,bz2,*}" ]; then
    echo "---------- Install bz2 ----------"
    docker-php-ext-install ${MC} bz2
fi

if [ -z "${EXTENSIONS##*,soap,*}" ]; then
    echo "---------- Install soap ----------"
	docker-php-ext-install ${MC} soap
fi

if [ -z "${EXTENSIONS##*,xsl,*}" ]; then
    echo "---------- Install xsl ----------"
	docker-php-ext-install ${MC} xsl
fi

if [ -z "${EXTENSIONS##*,xmlrpc,*}" ]; then
    echo "---------- Install xmlrpc ----------"
	docker-php-ext-install ${MC} xmlrpc
fi

if [ -z "${EXTENSIONS##*,wddx,*}" ]; then
    echo "---------- Install wddx ----------"
	docker-php-ext-install ${MC} wddx
fi

if [ -z "${EXTENSIONS##*,curl,*}" ]; then
    echo "---------- Install curl ----------"
    apt-get install -y curl libcurl3 libcurl4-openssl-dev
	docker-php-ext-install ${MC} curl
fi

if [ -z "${EXTENSIONS##*,readline,*}" ]; then
    echo "---------- Install readline ----------"
    apt-get install -y libreadline-dev
	docker-php-ext-install ${MC} readline
fi

if [ -z "${EXTENSIONS##*,snmp,*}" ]; then
    echo "---------- Install snmp ----------"
    apt-get install -y libsnmp-dev snmp
	docker-php-ext-install ${MC} snmp
fi

if [ -z "${EXTENSIONS##*,pspell,*}" ]; then
    echo "---------- Install pspell ----------"
    apt-get install -y libpspell-dev aspell-en
	docker-php-ext-install ${MC} pspell
fi

if [ -z "${EXTENSIONS##*,recode,*}" ]; then
    echo "---------- Install recode ----------"
	apt-get install -y librecode0 librecode-dev
    docker-php-ext-install recode
fi

if [ -z "${EXTENSIONS##*,tidy,*}" ]; then
    echo "---------- Install tidy ----------"
    apt-get install -y libtidy-dev
    docker-php-ext-install tidy
fi

if [ -z "${EXTENSIONS##*,gmp,*}" ]; then
    echo "---------- Install gmp ----------"
    apt-get install -y libgmp-dev \
    && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h
    docker-php-ext-install gmp
fi

if [ -z "${EXTENSIONS##*,imap,*}" ]; then
    echo "---------- Install imap ----------"
    apt-get install -y libc-client-dev \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl
    docker-php-ext-install imap
fi

if [ -z "${EXTENSIONS##*,ldap,*}" ]; then
    echo "---------- Install ldap ----------"
    apt-get install -y libldb-dev \
    && apt-get install -y libldap2-dev
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu
    docker-php-ext-install ldap
fi

if [ -z "${EXTENSIONS##*,imagick,*}" ]; then
    echo "---------- Install imagick ----------"
	apt-get install -y libmagickwand-dev
    printf "\n" | pecl install imagick-3.4.4
    docker-php-ext-enable imagick
fi

if [ -z "${EXTENSIONS##*,yaf,*}" ]; then
    echo "---------- Install yaf ----------"
    printf "\n" | pecl install yaf
    docker-php-ext-enable yaf
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
	apt-get install -y libmemcached-dev zlib1g-dev \
    printf "\n" | pecl install memcached-3.1.3
    docker-php-ext-enable memcached
fi

if [ -z "${EXTENSIONS##*,pdo_sqlsrv,*}" ]; then
    echo "---------- Install pdo_sqlsrv ----------"
	apt-get install -y  unixodbc-dev
    pecl install pdo_sqlsrv
    docker-php-ext-enable pdo_sqlsrv
fi

if [ -z "${EXTENSIONS##*,sqlsrv,*}" ]; then
    echo "---------- Install sqlsrv ----------"
	apt-get install -y unixodbc-dev
    printf "\n" | pecl install sqlsrv
    docker-php-ext-enable sqlsrv
fi

if [ -z "${EXTENSIONS##*,mongodb,*}" ]; then
    echo "---------- Install mongodb ----------"
    apt-get install -y unixodbc-dev
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
        printf "\n" | download solr
        wget --no-check-certificate -c https://pecl.php.net/get/solr-${SOLR_EXT_VERSION}.tgz
    fi
    mkdir solr \
    && apt-get install libcurl4-gnutls-dev -y \
    && tar -xf solr-${SOLR_EXT_VERSION}.tgz -C solr --strip-components=1 \
    && ( cd solr && phpize && ./configure && make ${MC} && make install ) \
    && docker-php-ext-enable solr
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

if [ -z "${EXTENSIONS##*,zookeeper,*}" ]; then
    echo "---------- Install zookeeper ----------"
    apt-get install -y libcppunit-dev file

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

if [ -z "${EXTENSIONS##*,protobuf,*}" ]; then
    echo "---------- Install protobuf ----------"
    # install protobuf
    if [ ! -f protobuf-all-${PROTOBUF_VERSION}.tar.gz ]; then
        wget --no-check-certificate -c https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/protobuf-all-${PROTOBUF_VERSION}.tar.gz
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

if [ -z "${EXTENSIONS##*,rdkafka,*}" ]; then
    echo "---------- Install rdkafka ----------"
    if [ ! -f librdkafka-${LIBRDKAFKA_VERSION}.tar.gz ]; then
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
