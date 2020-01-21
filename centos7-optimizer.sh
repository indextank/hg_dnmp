#! /bin/bash
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
clear

ONEINSTACK_ENABLE=0
ONEINSTACK_STACK=LNMPA   # LNMPA (Linux+Nginx+Apache+Mysql+Php) / LNMP (Linux+Nginx+Mysql+Php) / LAMP (Linux+Apache+Mysql+Php)

PYTHON2_ENABLED=1
PYTHON3_ENABLED=1
PHP56_ENABLED=1  # php 5.6不支持OpenSSL 1.1. 如果启用php5.6,默认系统openssl安装1.0版本
IPTABLES_ENABLED=0  # turn on iptables And turn off firewalld
FIREWALLD_ENABLED=1 # turn on firewalld And turn off iptables
COMPOSER_ENABLED=1
NPM_ENABLED=1
OPENSSL_ENABLED=1
GIT_ENABLED=1
VIM_ENABLED=1
JDK_ENABLED=1
DOCKER_ENABLED=1    # turn on/off docker
DEBUG=0  # 默认为0，仅当安装出错，反复执行该脚本时，为了避免重新检索更新安装依赖，故通过此项改为1，可加快脚本运行速度！

# ssh default port
SSH_PORT=22

# web directory, you can customize
wwwroot_dir=/opt/wwwroot

# nginx Generate a log storage directory, you can freely specify.
wwwlogs_dir=/opt/wwwlogs

# database data storage directory, you can freely specify
mysql_data_dir=/data/mysql

# Nginx Apache and PHP-FPM process is run as $run_user(Default "www"), you can freely specify
run_user=www

# Mysql init password
db_password=123456

python2_ver=2.7.17
python3_ver=3.6.9
jdk18_ver=1.8.0_231
node_ver=12.14.1
bison_ver=3.5

# Software version
GIT_VERSION=2.25.0

OPENSSL11_VER=1.1.1d
OPENSSL_VER=1.0.2u
OPENSSL_INSTALL_DIR=/usr/local/openssl

# set the default timezone
timezone=Asia/Shanghai

# Make sure only root can run our script
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }

hg_dnmp_dir=`pwd`
pushd ${hg_dnmp_dir} > /dev/null
if [ ! -d "${hg_dnmp_dir}/src/php" ];then
    mkdir -p ${hg_dnmp_dir}/src/php
fi

echo=echo
for cmd in echo /bin/echo; do
    $cmd >/dev/null 2>&1 || continue
    if ! $cmd -e "" | grep -qE '^-e'; then
        echo=$cmd
        break
    fi
done
CSI=$($echo -e "\033[")
CEND="${CSI}0m"
CDGREEN="${CSI}32m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CYELLOW="${CSI}1;33m"
CBLUE="${CSI}1;34m"
CMAGENTA="${CSI}1;35m"
CCYAN="${CSI}1;36m"
CSUCCESS="$CDGREEN"
CFAILURE="$CRED"
CQUESTION="$CMAGENTA"
CWARNING="$CYELLOW"
CMSG="$CCYAN"

if [[ ${IPTABLES_ENABLED} == 1 ]] && [[ ${FIREWALLD_ENABLED} == 1 ]]; then
    echo; echo -e "${CWARNING}Iptables and firewalld can only choose one. ${CEND}\n"
    exit 0
fi

yum install wget redhat-lsb -y 

# Get OS Version
if [ -e /etc/redhat-release ]; then
    OS=CentOS
    OS_ver=$(lsb_release -sr | awk -F. '{print $1}')
    [[ "$(lsb_release -is)" =~ ^Aliyun$|^AlibabaCloudEnterpriseServer$ ]] && { OS_ver=7; }
    [[ "$(lsb_release -is)" =~ ^EulerOS$ ]] && { OS_ver=7; }
    [ "$(lsb_release -is)" == 'Fedora' ] && [ ${OS_ver} -ge 19 >/dev/null 2>&1 ] && { OS_ver=7; }
elif [ -n "$(grep 'Amazon Linux' /etc/issue)" -o -n "$(grep 'Amazon Linux' /etc/os-release)" ]; then
    OS=CentOS
    OS_ver=7
fi

if [ "$(getconf WORD_BIT)" == "32" ] && [ "$(getconf LONG_BIT)" == "64" ]; then
    OS_BIT=64
    SYS_BIT_j=x64 #jdk
else
    OS_BIT=32
    SYS_BIT_j=i586
fi

# Check OS Version
if [ ${OS_ver} -lt 7 >/dev/null 2>&1 ]; then
  echo -e "${CFAILURE}Your current system is ${OS} ${OS_ver} \nDoes not support this OS, Please install CentOS 7+ ${CEND}"
  kill -9 $$
else
    cat << EOF
+-----------------------------------------------+
|   your system is ${OS} ${OS_ver} ${OS_BIT}    |
|      start optimizing.......                  |
+-----------------------------------------------
EOF
fi

THREAD=$(grep 'processor' /proc/cpuinfo | sort -u | wc -l)

# get the IP information
PUBLIC_IPADDR=$(./include/get_public_ipaddr.py)
IPADDR_COUNTRY=$(./include/get_ipaddr_state.py ${PUBLIC_IPADDR})
if [ "${IPADDR_COUNTRY}"x == "CN"x ]; then
    location='CN'
else
    location='NOCN'
fi

# ssh
if [ -z "`grep ^Port /etc/ssh/sshd_config`" -a "${SSH_PORT}" != '22' ]; then
    sed -i "s@^#Port.*@&\nPort ${SSH_PORT}@" /etc/ssh/sshd_config
elif [ -n "`grep ^Port /etc/ssh/sshd_config`" ]; then
    sed -i "s@^Port.*@Port ${SSH_PORT}@" /etc/ssh/sshd_config
fi

# The init_lock file is used to avoid script errors that cause duplicate execution
if [ ! -f "/tmp/init_lock" ];then
    echo "${CWARNING}=========================================================== ${CEND}"
    echo "${CWARNING}         Initialization Settings                            ${CEND}"
    echo "${CWARNING}=========================================================== ${CEND}"

    sed -i "s/alias cp='cp -i'/#alias cp='cp -i'/g" ~/.bashrc
    sed -i "s/alias mv='mv -i'/#alias mv='mv -i'/g" ~/.bashrc
    source ~/.bashrc

    if [ ${location} == 'CN' ]; then
        cat >> /etc/resolv.conf << EOF
nameserver 223.5.5.5
nameserver 114.114.114.114
EOF

        mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
        wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-${OS_ver}.repo
    fi

    [ -e '/etc/yum.conf' ] && sed -i 's@^exclude@#exclude@' /etc/yum.conf
    
    # Uninstall the conflicting packages
    echo "${CMSG}Removing the conflicting packages...${CEND}"
    [ -z "`grep -w epel /etc/yum.repos.d/*.repo`" ] && yum -y install epel-release
    if [ "${OS_ver}" == '8' ]; then
        dnf -y --enablerepo=PowerTools install chrony oniguruma-devel rpcgen
        systemctl enable chronyd
    elif [ "${OS_ver}" == '7' ]; then
        yum -y groupremove "Basic Web Server" "MySQL Database server" "MySQL Database client"

        if [ ${IPTABLES_ENABLED} == '1' ]; then
            systemctl mask firewalld.service
        fi
    fi

    # Enable the optional channel
    yum -y install yum-utils \
    && yum-config-manager --enable rhui-REGION-rhel-server-extras rhui-REGION-rhel-server-optional

    # Update time
    # yum -y install ntp
    # /usr/sbin/ntpdate cn.pool.ntp.org
    # echo "* 4 * * * /usr/sbin/ntpdate cn.pool.ntp.org > /dev/null 2>&1" >> /var/spool/cron/root
    # systemctl restart crond.service

    # Update time
    yum -y install ntp
    if [ -e "$(which ntpdate)" ]; then
        ntpdate -u cn.pool.ntp.org
        [ ! -e "/var/spool/cron/root" ] && { touch /var/spool/cron/root; }
        [ ! -e "/var/spool/cron/root" -o -z "$(grep 'ntpdate' /var/spool/cron/root)" ] && { echo "*/20 * * * * $(which ntpdate) -u pool.ntp.org > /dev/null 2>&1" >> /var/spool/cron/root;chmod 600 /var/spool/cron/root; }
    fi

    # Maximum number of open file descriptors
    echo "ulimit -SHn 102400" >> /etc/rc.local

    # /etc/security/limits.conf
    [ -e /etc/security/limits.d/*nproc.conf ] && rename nproc.conf nproc.conf_bk /etc/security/limits.d/*nproc.conf
    sed -i '/^# End of file/,$d' /etc/security/limits.conf
    cat >> /etc/security/limits.conf <<EOF
# End of file
* soft nproc 1000000
* hard nproc 1000000
* soft nofile 1000000
* hard nofile 1000000
EOF

    # /etc/hosts
    [ "$(hostname -i | awk '{print $1}')" != "127.0.0.1" ] && sed -i "s@127.0.0.1.*localhost@&\n127.0.0.1 $(hostname)@g" /etc/hosts

    # Set timezone
    rm -rf /etc/localtime
    ln -s /usr/share/zoneinfo/${timezone} /etc/localtime

    # Turn off the selinux
    setenforce 0
    # sed -ri '/^[^#]*SELINUX=/s#=.+$#=disabled#' /etc/selinux/config
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

    # system charset configuration
    sed -i 's@LANG=.*$@LANG="en_US.UTF-8"@g' /etc/locale.conf

    # set ssh
    sed -i 's/^GSSAPIAuthentication yes$/GSSAPIAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
    systemctl restart sshd.service

    # ip_conntrack table full dropping packets
    [ ! -e "/etc/sysconfig/modules/iptables.modules" ] && { echo -e "modprobe nf_conntrack\nmodprobe nf_conntrack_ipv4" > /etc/sysconfig/modules/iptables.modules; chmod +x /etc/sysconfig/modules/iptables.modules; }
    modprobe nf_conntrack
    modprobe nf_conntrack_ipv4
    echo options nf_conntrack hashsize=131072 > /etc/modprobe.d/nf_conntrack.conf

    # /etc/sysctl.conf
    [ ! -e "/etc/sysctl.conf_bk" ] && /bin/mv /etc/sysctl.conf{,_bk}
    cat > /etc/sysctl.conf << EOF
fs.file-max=1000000
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.ipv4.tcp_max_syn_backlog = 16384
net.core.netdev_max_backlog = 32768
net.core.somaxconn = 32768
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_fin_timeout = 20
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_syncookies = 1
#net.ipv4.tcp_tw_len = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.ip_local_port_range = 1024 65000
net.nf_conntrack_max = 6553500
net.netfilter.nf_conntrack_max = 6553500
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 60
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 120
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 120
net.netfilter.nf_conntrack_tcp_timeout_established = 3600
EOF
    sysctl -p

    # 开启ip forwarding转发
    echo 'net.ipv4.ip_forward = 1' >> /usr/lib/sysctl.d/50-default.conf

    [ "${OS_ver}" == '8' ] && dnf --enablerepo=PowerTools install -y rpcgen

    # Install bison
    if [ -e "/usr/bin/bison" ]; then
        mv /usr/bin/bison /usr/bin/bison.old
    fi
    pushd ${hg_dnmp_dir}/src/php > /dev/null
    if [ ! -f bison-${bison_ver}.tar.gz ]; then
        wget -c http://ftp.gnu.org/gnu/bison/bison-${bison_ver}.tar.gz
    fi
    tar xzf bison-${bison_ver}.tar.gz
    pushd bison-${bison_ver} > /dev/null
    ./configure
    make -j ${THREAD} && make install
    ln -s  /usr/local/bin/bison /usr/bin/bison
    popd > /dev/null
    rm -rf bison-${bison_ver}
    popd > /dev/null

    # add lock file
    touch /tmp/init_lock && chmod -R 755 /tmp/init_lock
fi

# Install needed packages
if [ ${DEBUG} == '0' ]; then
    echo "${CWARNING}=========================================================== ${CEND}"
    echo "${CWARNING}         Installing dependencies packages                   ${CEND}"
    echo "${CWARNING}=========================================================== ${CEND}"

    echo "${CMSG}Installing dependencies packages...${CEND}"
    # Install needed packages
    pkgList="libffi-devel re2c ImageMagick ImageMagick-devel net-tools htop automake libvpx libwebp libwebp-devel libwebp-tools gettext deltarpm gcc gcc-c++ make cmake autoconf libjpeg libjpeg-devel libjpeg-turbo libjpeg-turbo-devel libpng libpng-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel krb5-devel libc-client libc-client-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel libaio numactl numactl-libs readline-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5-devel libidn libidn-devel openssl openssl-devel libxslt-devel libicu-devel libevent-devel libtool libtool-ltdl gd-devel pcre-devel libmcrypt libmcrypt-devel mhash mhash-devel mcrypt zip unzip ntpdate sqlite-devel sysstat patch bc expect expat-devel oniguruma oniguruma-devel libtirpc-devel nss rsync rsyslog git lsof lrzsz psmisc wget which libatomic tmux"
    for Package in ${pkgList}; do
        yum -y install ${Package}
    done

    yum -y update bash glibc
fi

if [ ${OPENSSL_ENABLED} == '1' ]; then
    if [ ! -e "${OPENSSL_INSTALL_DIR}/lib/libssl.a" ]; then
        echo "${CWARNING}=========================================================== ${CEND}"
        echo "${CWARNING}         Installing Openssl                                 ${CEND}"
        echo "${CWARNING}=========================================================== ${CEND}"

        if [ -e "${OPENSSL_INSTALL_DIR}/lib/libssl.a" ]; then
            echo "${CSUCCESS}openSSL already installed! ${CEND}"
        else
            pushd ${hg_dnmp_dir}/src/php > /dev/null

            if [ ${PHP56_ENABLED} == '1' ]; then
                OPENSSL_VERSION=${OPENSSL_VER}
            else
                OPENSSL_VERSION=${OPENSSL11_VER}
            fi

            if [ ! -f openssl-${OPENSSL_VERSION}.tar.gz ];then
                wget --no-check-certificate -c https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
            fi
            tar xzf openssl-${OPENSSL_VERSION}.tar.gz
            pushd openssl-${OPENSSL_VERSION} > /dev/null
            make clean
            ./config -Wl,-rpath=${OPENSSL_INSTALL_DIR}/lib -fPIC --prefix=${OPENSSL_INSTALL_DIR} --openssldir=${OPENSSL_INSTALL_DIR}
            make depend
            make -j ${THREAD} && make install
            popd > /dev/null

            # ln -s /usr/local/ssl/lib/libssl.so.1.1 /usr/lib64/libssl.so.1.1
            # ln -s /usr/local/ssl/lib/libcrypto.so.1.1 /usr/lib64/libcrypto.so.1.1
            echo "${OPENSSL_INSTALL_DIR}/lib" >> /etc/ld.so.conf
            ldconfig

            if [ -f /usr/bin/openssl ];then
                mv /usr/bin/openssl /usr/bin/openssl.old
            fi
            set OPENSSL_CONF=${OPENSSL_INSTALL_DIR}/openssl.cnf
            ln -sf ${OPENSSL_INSTALL_DIR}/bin/openssl /usr/bin/openssl

            if [ -f "${OPENSSL_INSTALL_DIR}/lib/libcrypto.a" ]; then
                echo; echo -e "${CSUCCESS}Openssl installed successfully! ${CEND}\n"
                rm -rf openssl-${OPENSSL_VERSION}
                # See the openssl version
                openssl version -a
            else
                echo; echo "${CFAILURE}openSSL install failed, Please contact the author! ${CEND}"
                kill -9 $$
            fi

            rm -fr ${hg_dnmp_dir}/src/openssl-${OPENSSL_VERSION}
            echo -e "\n"
            popd > /dev/null
        fi
    fi
fi

if [ ${PYTHON2_ENABLED} == '1' ]; then
    # update python2
    pushd ${hg_dnmp_dir}/src > /dev/null
    if [ ! -f "Python-${python2_ver}.tgz" ]; then
        wget --no-check-certificate -c https://mirrors.huaweicloud.com/python/${python2_ver}/Python-${python2_ver}.tgz
    fi
    tar xzf Python-${python2_ver}.tgz
    pushd Python-${python2_ver} > /dev/null
    ./configure --prefix=/usr/local --enable-optimizations --with-cxx-main=/usr/bin/g++
    make -j ${THREAD} && make altinstall  # 注意： 不要使用 make install,这样会覆盖原有的python 版本；
    popd > /dev/null
    mv /usr/bin/python2.7 /usr/bin/python2.7.5
    rm -fr /usr/bin/python
    rm -fr /usr/bin/python2
    ln -s /usr/local/bin/python2.7 /usr/bin/python
    ln -s /usr/local/bin/python2.7 /usr/bin/python2

    sed -i '1d' /usr/bin/yum && sed -i '1i\#!/usr/bin/python2.7.5'  /usr/bin/yum
    sed -i '1d' /usr/bin/yum-config-manager && sed -i '1i\#!/usr/bin/python2.7.5 -tt' /usr/bin/yum-config-manager
    sed -i '1d' /usr/libexec/urlgrabber-ext-down && sed -i '1i\#! /usr/bin/python2.7.5' /usr/libexec/urlgrabber-ext-down
    popd > /dev/null

    # pip
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    /usr/bin/python get-pip.py
    mkdir ~/.pip
    cat > ~/.pip/pip.conf << EOF
[global]
trusted-host=mirrors.aliyun.com
index-url=https://mirrors.aliyun.com/pypi/simple/
EOF
    if [ -e /usr/local/bin/pip ]; then
        ln -s /usr/local/bin/pip /usr/bin/pip
        /usr/bin/pip install --upgrade pip
    fi
fi

if [ ${PYTHON3_ENABLED} == '1' ]; then
    # install python3
    if [ ! -e /usr/local/bin/python3 ] || [ "$(python3 --version | awk -F ' ' '{print $2}')" != "${python3_ver}" ]; then
        pushd ${hg_dnmp_dir}/src > /dev/null
        if [ ! -f "Python-${python3_ver}.tgz" ]; then
            wget --no-check-certificate -c https://mirrors.huaweicloud.com/python/${python3_ver}/Python-${python3_ver}.tgz
        fi
        tar xzf Python-${python3_ver}.tgz
        pushd Python-${python3_ver} > /dev/null
        ./configure --prefix=/usr/local --enable-optimizations --with-cxx-main=/usr/bin/g++
        make -j ${THREAD} && make install
        ln -s /usr/local/bin/python3 /usr/bin/
        ln -s /usr/local/bin/pip3 /usr/bin/
        /usr/bin/pip3 install --upgrade pip
        popd > /dev/null
    fi
fi

if [ ${GIT_ENABLED} == '1' ]; then
    if [ ! -f /usr/local/bin/git ]; then
        echo "${CWARNING}=========================================================== ${CEND}"
        echo "${CWARNING}         Installing Git                                     ${CEND}"
        echo "${CWARNING}=========================================================== ${CEND}"

        yum remove git -y

        pushd ${hg_dnmp_dir}/src > /dev/null

        if [ ! -f git-${GIT_VERSION}.tar.gz ]; then
            wget --no-check-certificate -c https://cdn.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz
        fi
        tar xzf git-${GIT_VERSION}.tar.gz
        pushd git-${GIT_VERSION} > /dev/null
        make configure
        ./configure && make -j ${THREAD} prefix=/usr all && make install
        popd > /dev/null
        
        ln -s /usr/local/bin/git /usr/bin/git

        git config --global alias.co checkout
        git config --global alias.br branch
        git config --global alias.ci commit
        git config --global alias.st status
        git config --global alias.last 'log -1 HEAD'
        git config --global core.autocrlf "input"
        git config --global http.postBuffer 524288000
        git config --global core.editor /usr/bin/vim
        git config --global http.sslverify false
        git config --global core.ignorecase false
        echo; echo "${CSUCCESS}Git installed successfully! ${CEND}"
        rm -fr git-${GIT_VERSION}
        popd > /dev/null
    fi
fi

if [ ${ONEINSTACK_ENABLE} == '1' ]; then
    pushd ${hg_dnmp_dir}/src > /dev/null
    if [ ! -f "oneinstack-full.tar.gz" ]; then
        wget -c http://mirrors.linuxeye.com/oneinstack-full.tar.gz
    fi
    tar xzf oneinstack-full.tar.gz
    pushd oneinstack > /dev/null

    # 替换oneinstack中相关信息
    sed -i "s@installDepsCentOS@#installDepsCentOS@g" install.sh
    sed -i "s@. include/init_CentOS.sh@#. include/init_CentOS.sh@g" install.sh
    sed -i "s@run_user=www@run_user=${run_user}@g" options.conf
    sed -i "s@wwwroot_dir=/data/wwwroot@wwwroot_dir=${wwwroot_dir}@g" options.conf
    sed -i "s@wwwlogs_dir=/data/wwwlogs@wwwlogs_dir=${wwwlogs_dir}@g" options.conf
    sed -i "s@mysql_data_dir=/data/mysql@mysql_data_dir=${mysql_data_dir}@g" options.conf
    sed -i "s@.\/configure --with-php-config=\${php_install_dir}\/bin\/php-config --with-imagick=\${imagick_install_dir}@.\/configure --with-php-config=\${php_install_dir}\/bin\/php-config@g" include\/ImageMagick.sh

    if [ ${PHP56_ENABLED} == '1' ];then
        mpphp56_ver='--mphp_ver 56'
    else
        mpphp56_ver=''
    fi

    if [ ${ONEINSTACK_STACK} == "LNMPA" ]; then
        ./install.sh --nginx_option 1 --apache_option 1 --apache_mpm_option 1 --apache_mode_option 1 --php_option 7 --php_extensions imagick,fileinfo,redis,mongodb,swoole ${mpphp56_ver} --db_option 2 --dbinstallmethod 2 --dbrootpwd ${db_password} --redis  --ssh_port ${SSH_PORT}
    elif [ ${ONEINSTACK_STACK} == "LNMP" ]; then
        ./install.sh --nginx_option 1 --php_option 7 --php_extensions imagick,fileinfo,redis,mongodb,swoole ${mpphp56_ver} --db_option 2 --dbinstallmethod 2 --dbrootpwd ${db_password} --redis  --ssh_port ${SSH_PORT}
    elif [ ${ONEINSTACK_STACK} == "LAMP" ]; then
        ./install.sh --apache_option 1 --apache_mpm_option 1 --apache_mode_option 1 --php_option 7 --php_extensions imagick,fileinfo,redis,mongodb,swoole ${mpphp56_ver} --db_option 2 --dbinstallmethod 2 --dbrootpwd ${db_password} --redis  --ssh_port ${SSH_PORT}
    fi
    popd > /dev/null
    rm -fr ${wwwroot_dir}/default/index.html
    mv ${wwwroot_dir}/default/phpinfo.php ${wwwroot_dir}/default/index.php
    
    [ -n "$(grep ^'export PATH=' /etc/profile)" -a -z "$(grep /usr/local/php/bin /etc/profile)" ] && sed -i "s@^export PATH=\(.*\)@export PATH=/usr/local/php/bin:\1@" /etc/profile
    source /etc/profile
    popd > /dev/null
fi

if [ ${VIM_ENABLED} == '1' ]; then
    yum remove vim -y

    if [ ! -e /usr/bin/vim ]; then
        echo "${CWARNING}=========================================================== ${CEND}"
        echo "${CWARNING}         Installing Vim                                     ${CEND}"
        echo "${CWARNING}=========================================================== ${CEND}"

        if [ ! -f /usr/local/bin/git ];then
            yum install git -y    
        fi

        pushd ${hg_dnmp_dir}/src > /dev/null
        if [ ! -d "${hg_dnmp_dir}/src/vim" ]; then
            if [ ${location} == 'CN' ]; then
                git clone https://gitee.com/indextank/vim.git vim
            else
                git clone https://github.com/vim/vim.git
            fi
        else
            pushd vim > /dev/null
            git checkout . && git pull
            popd > /dev/null
        fi

        pushd vim/src > /dev/null
        make -j ${THREAD} \
        && \cp -r vim /usr/bin/ \
        && mkdir -p /usr/local/share/vim/ \
        && \cp -r ${hg_dnmp_dir}/src/vim/runtime/* /usr/local/share/vim \
        && mv /usr/bin/vi /usr/bin/vi.old \
        && ln -sf /usr/bin/vim /usr/bin/vi
        popd > /dev/null
        echo; echo "${CSUCCESS}Vim installed successfully! ${CEND}"
        popd > /dev/null
    fi

    if [ ! -d "/root/.vim_runtime" ] && [ -e /usr/bin/vim ]; then
        pushd ${hg_dnmp_dir}/src > /dev/null
        if [ ! -d "${hg_dnmp_dir}/src/vimrc" ]; then
            if [ ${location} == 'CN' ]; then
                git clone --depth=1 https://gitee.com/indextank/vimrc.git vimrc
            else
                git clone --depth=1 https://github.com/amix/vimrc.git vimrc
            fi

            \cp -r vimrc ~/.vim_runtime
        else
            pushd ${hg_dnmp_dir}/src/vimrc > /dev/null
            git checkout . && git pull
            popd > /dev/null
        fi

        sh ~/.vim_runtime/install_awesome_vimrc.sh
        touch ~/.vim_runtime/my_configs.vim
        cat > ~/.vim_runtime/my_configs.vim << EOF
" 设置通用缩进策略 [四空格缩进]
set shiftwidth=4
set tabstop=4

"" 对部分语言设置单独的缩进 [两空格缩进]
au FileType scheme,racket,lisp,clojure,lfe,elixir,eelixir,ruby,eruby,coffee,slim<Plug>PeepOpenug,scss set shiftwidth=2
au FileType scheme,racket,lisp,clojure,lfe,elixir,eelixir,ruby,eruby,coffee,slim<Plug>PeepOpenug,scss set tabstop=2

"" 配置 Rust 支持 [需要使用 cargo 安装 racer 和 rustfmt 才能正常工作，RUST_SRC_PATH 需要自己下载 Rust           源码并指定好正确的路径]
let $RUST_SRC_PATH                 = $HOME.'/code/data/sources/languages/rust/src'
let g:racer_experimental_completer = 1  " 补全时显示完整的函数定义
let g:rustfmt_autosave             = 1  " 保存时自动格式化代码

set backspace=2              " 设置退格键可用
set autoindent               " 自动对齐
set ai!                      " 设置自动缩进
set smartindent              " 智能自动缩进
set relativenumber           " 开启相对行号
set nu!                      " 显示行号
set ruler                    " 右下角显示光标位置的状态行
set incsearch                " 开启实时搜索功能
set hlsearch                 " 开启高亮显示结果
set nowrapscan               " 搜索到文件两端时不重新搜索
set nocompatible             " 关闭兼容模式
set hidden                   " 允许在有未保存的修改时切换缓冲区
set autochdir                " 设定文件浏览器目录为当前目录
set foldmethod=indent        " 选择代码折叠类型
set foldlevel=100            " 禁止自动折叠
set laststatus=2             " 开启状态栏信息
set cmdheight=2              " 命令行的高度，默认为1，这里设为2
set autoread                 " 当文件在外部被修改时自动更新该文件
set nobackup                 " 不生成备份文件
set noswapfile               " 不生成交换文件
set list                     " 显示特殊字符，其中Tab使用高亮~代替，尾部空白使用高亮点号代替
set listchars=tab:\~\ ,trail:.
set expandtab                " 将 Tab 自动转化成空格 [需要输入真正的 Tab 符时，使用 Ctrl+V + Tab]
"set showmatch               " 显示括号配对情况

" 使用 vimdiff 时，长行自动换行
autocmd FilterWritePre * if &diff | setlocal wrap< | endif

syntax enable                " 打开语法高亮
syntax on                    " 开启文件类型侦测
filetype indent on           " 针对不同的文件类型采用不同的缩进格式
filetype plugin on           " 针对不同的文件类型加载对应的插件
filetype plugin indent on    " 启用自动补全

" 设置文件编码和文件格式
set fenc=utf-8
set encoding=utf-8
set fileencodings=utf-8,gbk,cp936,latin-1
set fileformat=unix
set fileformats=unix,mac,dos
EOF
        export EDITOR=/usr/bin/vim
        source ~/.bashrc

        # vim定义退格键可删除最后一个字符类型
        echo 'alias vi=vim' >> /etc/profile
        echo "stty erase ^?" >> /etc/profile
        echo "stty erase ^H" >> /etc/profile
        cat >> ~/.vimrc << EOF
set tabstop=4
set shiftwidth=4
set expandtab
set paste
set number
syntax on
EOF
        popd > /dev/null
        echo "export EDITOR=/usr/bin/vim" >>  ~/.bashrc && source ~/.bashrc
        echo; echo "${CSUCCESS}Vimrc installed successfully! ${CEND}"
    fi
fi

if [ ${COMPOSER_ENABLED} == '1' ]; then
    echo "${CWARNING}=========================================================== ${CEND}"
    echo "${CWARNING}         Installing Composer                                ${CEND}"
    echo "${CWARNING}=========================================================== ${CEND}"
    if [ -e "/usr/local/php/bin/phpize" ]; then
        if [ -e "/usr/local/bin/composer" ]; then
            echo "${CSUCCESS}PHP Composer already installed! ${CEND}"
        else
            if [ $location == 'CN' ]; then
                wget --no-check-certificate -c https://mirrors.aliyun.com/composer/composer.phar -O /usr/local/bin/composer > /dev/null 2>&1
                /usr/local/php/bin/php /usr/local/bin/composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/
            else
                wget --no-check-certificate -c https://getcomposer.org/composer.phar -O /usr/local/bin/composer > /dev/null 2>&1
                /usr/local/php/bin/php /usr/local/bin/composer config -g repo.packagist composer https://packagist.phpcomposer.com
            fi
            chmod +x /usr/local/bin/composer
            composer global require fxp/composer-asset-plugin
            if [ -e "/usr/local/bin/composer" ]; then
                echo; echo "${CSUCCESS}PHP Composer installed successfully! ${CEND}"
            else
                echo; echo "${CFAILURE}PHP Composer install failed, Please try again! ${CEND}"
            fi
        fi
    else
        echo; echo -e "${CFAILURE}PHP Composer install failed, Please install php ${CEND}\n"
    fi
fi

if [ ${NPM_ENABLED} == '1' ]; then
    if [ ! -f /usr/local/node/bin/node ];then
        echo "${CWARNING}=========================================================== ${CEND}"
        echo "${CWARNING}         Installing Npm                                     ${CEND}"
        echo "${CWARNING}=========================================================== ${CEND}"
        pushd ${hg_dnmp_dir}/src > /dev/null
        if [ ! -f node-v${node_ver}-linux-x64.tar.gz ]; then
            echo "Download Node ${node_ver}..."
            if [ ${location} == 'CN' ]; then
                wget --no-check-certificate -c https://npm.taobao.org/mirrors/node/v${node_ver}/node-v${node_ver}-linux-x64.tar.gz
            else
                wget --no-check-certificate -c https://nodejs.org/dist/v${node_ver}/node-v${node_ver}-linux-x64.tar.gz
            fi
        fi
        tar xzf node-v${node_ver}-linux-x64.tar.gz
        mv node-v${node_ver}-linux-x64 /usr/local/node
        chmod +x /usr/local/node/bin/
        [ -n "$(grep ^'export PATH=' /etc/profile)" -a -z "$(grep /usr/local/node/bin /etc/profile)" ] && sed -i "s@^export PATH=\(.*\)@export PATH=/usr/local/node/bin:\1@" /etc/profile
        source /etc/profile
        popd > /dev/null

        ln -s /usr/local/node/bin/node /usr/bin/node
        ln -s /usr/local/node/bin/npm /usr/bin/npm

        if [ ${location} == 'CN' ]; then
            /usr/bin/npm install -g cnpm --registry=https://registry.npm.taobao.org
            echo 'alias npm="cnpm"' >> ~/.bash_profile && source ~/.bash_profile
        fi

        /usr/bin/npm install --global gulp
        echo; echo "${CSUCCESS}Npm installed successfully! ${CEND}"
    fi
fi

if [ ${DOCKER_ENABLED} == '1' ] && [ $ONEINSTACK_ENABLE == '0' ]; then
    echo "${CWARNING}=========================================================== ${CEND}"
    echo "${CWARNING}         Installing Docker                                  ${CEND}"
    echo "${CWARNING}=========================================================== ${CEND}"

    yum makecache && yum update -y && yum install -y yum-utils device-mapper-persistent-data lvm2
    id -u docker >/dev/null 2>&1
    [ $? -ne 0 ] && groupadd docker && useradd -u 995 -g docker -m docker
    if [ ${location} == 'CN' ]; then
        curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
    else
        curl -fsSL https://get.docker.com | bash -s docker
    fi

    usermod -aG docker docker
    # chown -R docker:docker /var/run/docker*
    # chmod a+rw /var/run/docker.sock
    systemctl enable docker
    systemctl start docker

    if [ -e "/usr/bin/pip" ];then
        pip install more-itertools==5.0.0
        pip install docker-compose

        if [ ${location} == 'CN' ]; then
            cat >> /etc/docker/daemon.json << EOF
{
  "registry-mirrors": ["https://almtd3fa.mirror.aliyuncs.com"]
}
EOF
        fi
        systemctl daemon-reload
        systemctl restart docker.service
    else
        echo; echo "${CFAILURE}docker-compose install failed, Please try again! ${CEND}"
    fi
fi

if [ ${JDK_ENABLED} == '1' ]; then
    pushd ${hg_dnmp_dir}/src > /dev/null
    echo "Download JDK 1.8..."
    JDK_FILE="jdk-$(echo ${jdk18_ver} | awk -F. '{print $2}')u$(echo ${jdk18_ver} | awk -F_ '{print $NF}')-linux-${SYS_BIT_j}.tar.gz"
    if [ ! -f ${JDK_FILE} ]; then
        src_url=http://mirrors.linuxeye.com/jdk/${JDK_FILE}
        wget --limit-rate=10M -4 --tries=6 -c --no-check-certificate ${src_url}
    fi
    JAVA_dir=/usr/java
    JDK_NAME="jdk${jdk18_ver}"
    JDK_PATH=${JAVA_dir}/${JDK_NAME}
    [ "${PM}" == 'yum' ] && [ -n "`rpm -qa | grep jdk`" ] && rpm -e `rpm -qa | grep jdk`
    [ ! -e ${JAVA_dir} ] && mkdir -p ${JAVA_dir}
    tar xzf ${JDK_FILE} -C ${JAVA_dir}
    if [ -d "${JDK_PATH}" ]; then
        cp ${JDK_PATH}/jre/lib/security/cacerts /etc/ssl/certs/java
        [ -z "`grep ^'export JAVA_HOME=' /etc/profile`" ] && { [ -z "`grep ^'export PATH=' /etc/profile`" ] && echo  "export JAVA_HOME=${JDK_PATH}" >> /etc/profile || sed -i "s@^export PATH=@export JAVA_HOME=${JDK_PATH}\nexport PATH=@" /etc/profile; } || sed -i "s@^export JAVA_HOME=.*@export JAVA_HOME=${JDK_PATH}@" /etc/profile
        [ -z "`grep ^'export CLASSPATH=' /etc/profile`" ] && sed -i "s@export JAVA_HOME=\(.*\)@export JAVA_HOME=\1\nexport CLASSPATH=\$JAVA_HOME/lib/tools.jar:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib@" /etc/profile
        [ -n "`grep ^'export PATH=' /etc/profile`" -a -z "`grep '$JAVA_HOME/bin' /etc/profile`" ] && sed -i "s@^export PATH=\(.*\)@export PATH=\$JAVA_HOME/bin:\1@" /etc/profile
        [ -z "`grep ^'export PATH=' /etc/profile | grep '$JAVA_HOME/bin'`" ] && echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /etc/profile
        source /etc/profile
        echo "${CSUCCESS}$JDK_NAME installed successfully! ${CEND}"
    else
        echo "${CFAILURE}JDK install failed, Please contact the author! ${CEND}" && lsb_release -a
        kill -9 $$
    fi
    popd > /dev/null
fi

if [ ${IPTABLES_ENABLED} == '1' ] && [ $ONEINSTACK_ENABLE == '0' ]; then
    echo "${CWARNING}=========================================================== ${CEND}"
    echo "${CWARNING}               Iptables Configuration                       ${CEND}"
    echo "${CWARNING}=========================================================== ${CEND}"

    # 停止\禁用firewalld服务
    systemctl stop firewalld   
    systemctl mask firewalld

    # 启用iptables-services
    yum update -y
    yum install iptables iptables-services -y

    systemctl enable iptables.service
    systemctl start iptables.service

    # 首先在清除前要将policy INPUT改成ACCEPT,表示接受一切请求。
    # 这个一定要先做，不然清空后可能会悲剧
    # iptables -P INPUT ACCEPT
    # 清空默认所有规则
    iptables -F
    # 清空自定义的所有规则
    iptables -X
    # 计数器置0
    iptables -Z

    # 允许来自于lo接口的数据包
    # 如果没有此规则，你将不能通过127.0.0.1访问本地服务，例如ping 127.0.0.1
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A INPUT -s 127.0.0.1 -d 127.0.0.1 -j ACCEPT
    # ssh端口
    iptables -A INPUT -p tcp --dport ${SSH_PORT} -j ACCEPT
    # web服务端口80/443
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    # 允许icmp包通过,也就是允许ping
    iptables -A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
    # 允许所有对外请求的返回包
    # 本机对外请求相当于OUTPUT,对于返回数据包必须接收啊，这相当于INPUT了
    iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT
    # 如果要添加内网ip信任（接受其所有TCP请求）
    iptables -A INPUT -p tcp -s 172.0.0.0/8 -j ACCEPT
    # 过滤所有非以上规则的请求
    iptables -P INPUT DROP
    #iptables -I INPUT -s 142.44.191.0/24 -j DROP
    /usr/libexec/iptables/iptables.init save
    systemctl restart iptables.service

    echo; echo "${CSUCCESS}Iptables installed successfully! ${CEND}"
fi

if [ ${FIREWALLD_ENABLED} == '1' ]; then
    echo "${CWARNING}=========================================================== ${CEND}"
    echo "${CWARNING}         Firewalld Configuration                            ${CEND}"
    echo "${CWARNING}=========================================================== ${CEND}"

    if [ ! -e "/usr/sbin/firewalld" ]; then
        # iptables_process=`ps -ef |grep iptables |grep -v "grep" |wc -l`
        # if [[ -f "/usr/sbin/iptables" ]] || [[ ${iptables_process} == 1 ]]; then
        #     systemctl stop iptables
        #     yum remove iptables iptables-services -y
        # fi
        
        yum install firewalld firewall-config -y

        # firewall_process=`ps -ef |grep firewalld |grep -v "grep" |wc -l`
        # if [ ${firewall_process} == 0 ]; then
        #     systemctl start firewalld
        #     systemctl enable  firewalld
        # fi
    fi
    systemctl unmask firewalled
    systemctl start firewalld
    systemctl enable  firewalld

    # 设置当前区域 为 public
    firewall-cmd --set-default-zone=public

    # 放行端口
    firewall-cmd --zone=public --add-port=80/tcp --permanent
    firewall-cmd --zone=public --add-port=${SSH_PORT}/tcp --permanent
    firewall-cmd --zone=public --add-port=443/tcp --permanent

    if [ ${DOCKER_ENABLED} == '1' ]; then
        firewall-cmd --permanent --zone=trusted --add-interface=docker0
    fi

    # 重载firewall使其生效
    firewall-cmd --reload

    echo; echo "${CSUCCESS}Firewalld installed successfully! ${CEND}"
fi

cat <<EOF
+-------------------------------------------------+
|               optimizer is done                 |
|   it's recommond to restart this server !       |
+-------------------------------------------------+
EOF

if [ $ONEINSTACK_ENABLE == '1' ]; then
    echo "Nginx:    "$(nginx -v 2>&1 | sed '1!d' | sed -e 's/"//g' | awk '{print $3}' | awk -F '/' '{print $2}')  $([ "$(netstat -ntlp | grep -cE 'nginx')" == '1' ] && echo "${CSUCCESS}Running ${CEND}")    
    echo "Apache:   "$(httpd -v 2>&1 | sed '1!d' | sed -e 's/"//g' | awk '{print $3}' | awk -F '/' '{print $2}')  $([ "$(netstat -ntlp | grep -cE 'httpd')" == '1' ] && echo "${CSUCCESS}Running ${CEND}")
    echo "PHP5/7:       $(/usr/local/php56/bin/php -v | awk -F ' ' '{print $2}' | awk 'NR==1') / $(/usr/local/php/bin/php -v | awk -F ' ' '{print $2}' | awk 'NR==1') "   $([ "$(ps -u www | grep -c "php-fpm")" -gt 43 ] && echo "${CSUCCESS}Running ${CEND}")
    echo "Mysql:        $(mysql --version -v | awk -F ' ' '{print $5}' | awk -F ',' '{print $1}') "  $([ "$(netstat -ntlp | grep -cE 'mysqld')" == '1' ] && echo "${CSUCCESS}Running ${CEND}")
    echo "Redis：       $(redis-server -v | awk -F ' ' '{print $3}' | awk -F '=' '{print $2}') "  $([ "$(netstat -ntlp | grep -cE 'redis-server')" == '1' ] && echo "${CSUCCESS}Running ${CEND}")
    echo "Composer：    $(composer -v | awk -F ' ' '{print $3}' | awk 'NR==7') "
fi
echo "Java:         "$(java -version 2>&1 | sed '1!d' | sed -e 's/"//g' | awk '{print $3}')
echo "Git:          $(git --version | awk -F ' ' '{print $3}')"
echo "Npm:          $(npm -v)"
echo "Node:         $(node -v)"
echo "VIM：         $(vim --version | awk -F ' ' '{print $5}' | awk 'NR==1') "
echo "OpenSSL：     $(openssl version -a | awk -F ' ' '{print $2}' | awk 'NR==1') "
echo "Python3:      $(python3 --version | awk -F ' ' '{print $2}')"

[ -e "/usr/sbin/iptables" ] && echo "iptables: enabled"
[ -e "/usr/sbin/firewalld" ] && echo "firewalld: enabled"