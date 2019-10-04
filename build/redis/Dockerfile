FROM alpine:latest


# 设置相应的时区
RUN sed -i "s/dl-cdn.alpinelinux.org/${ALPINE_REPOSITORIES}/g" /etc/apk/repositories && \
    apk add --no-cache tzdata && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone && \
    apk del tzdata

CMD [ "/bin/bash","echo 511 > /proc/sys/net/core/somaxconn && echo never > /sys/kernel/mm/transparent_hugepage/enabled" ]

RUN apk --update add redis && rm -rf /var/cache/apk/*

CMD [ "redis-server", "/etc/redis.conf" ]