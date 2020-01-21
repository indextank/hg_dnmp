# https://github.com/cptactionhank/docker-atlassian-confluence
FROM openjdk:8-alpine

ARG ALPINE_REPOSITORIES
ARG CONFLUENCE_VERSION
ARG CONFULENCE_RUN_USER
ARG CONFULENCE_RUN_GROUP
ARG DOWNLOAD_URL=http://www.atlassian.com/software/confluence/downloads/binary/atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz

ENV RUN_USER            ${CONFULENCE_RUN_USER}
ENV RUN_GROUP           ${CONFULENCE_RUN_GROUP}

# Setup useful environment variables
ENV CONFLUENCE_HOME     /var/atlassian/confluence
ENV CONFLUENCE_INSTALL_DIR  /opt/atlassian/confluence
ENV CONFLUENCE_VERSION  ${CONFLUENCE_VERSION}

ENV JAVA_CACERTS  $JAVA_HOME/jre/lib/security/cacerts
ENV CERTIFICATE   $CONFLUENCE_HOME/certificate

COPY ./src/confluence /tmp/extensions
WORKDIR /tmp/extensions

RUN chmod +x init.sh

# Install Atlassian Confluence and helper tools and setup initial home
# directory structure.
RUN sed -i "s/dl-cdn.alpinelinux.org/${ALPINE_REPOSITORIES}/g" /etc/apk/repositories \
    && apk update && apk add --no-cache tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && apk del tzdata

RUN set -x \
    && apk update && apk add --no-cache xmlstarlet bash ttf-dejavu libc6-compat gcompat ca-certificates wget openssh procps openssl perl tini \    
    && mkdir -p                "${CONFLUENCE_HOME}" \
    && chmod -R 700            "${CONFLUENCE_HOME}" \
    && chown "${RUN_USER}":"${RUN_GROUP}"     "${CONFLUENCE_HOME}" \
    && mkdir -p                "${CONFLUENCE_INSTALL_DIR}/conf" \
    && bash init.sh \
    # && [ ! -f atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz ] && wget --no-check-certificate -c  ${DOWNLOAD_URL} \
    && tar -xzf atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz --directory "${CONFLUENCE_INSTALL_DIR}" --strip-components=1 --no-same-owner \
    # && curl -Ls                "https://www.atlassian.com/software/confluence/downloads/binary/atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz" | tar -xz --directory "${CONFLUENCE_INSTALL_DIR}" --strip-components=1 --no-same-owner \
    # && wget --no-check-certificate -c "https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.44.tar.gz" | tar -xz --directory "${CONFLUENCE_INSTALL_DIR}/confluence/WEB-INF/lib" --strip-components=1 --no-same-owner "mysql-connector-java-5.1.44/mysql-connector-java-5.1.44-bin.jar" \
    # && [[ -f mysql-connector-java-8.0.18.jar ]] 
    && cp -r mysql-connector-java-8.0.18.jar "${CONFLUENCE_INSTALL_DIR}/confluence/WEB-INF/lib" \
    # && [[ ! -f mysql-connector-java-8.0.18.jar ]] && wget --no-check-certificate -c "https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.18.tar.gz" | tar -xz --directory "${CONFLUENCE_INSTALL_DIR}/confluence/WEB-INF/lib" --strip-components=1 --no-same-owner "mysql-connector-java-8.0.18/mysql-connector-java-8.0.18.jar" \
    && chmod -R 700            "${CONFLUENCE_INSTALL_DIR}/conf" \
    && chmod -R 700            "${CONFLUENCE_INSTALL_DIR}/temp" \
    && chmod -R 700            "${CONFLUENCE_INSTALL_DIR}/logs" \
    && chmod -R 700            "${CONFLUENCE_INSTALL_DIR}/work" \
    && chown -R ${RUN_USER}:${RUN_GROUP}  "${CONFLUENCE_INSTALL_DIR}/conf" \
    && chown -R ${RUN_USER}:${RUN_GROUP}  "${CONFLUENCE_INSTALL_DIR}/temp" \
    && chown -R ${RUN_USER}:${RUN_GROUP}  "${CONFLUENCE_INSTALL_DIR}/logs" \
    && chown -R ${RUN_USER}:${RUN_GROUP}  "${CONFLUENCE_INSTALL_DIR}/work" \
    && echo -e                 "\nconfluence.home=$CONFLUENCE_HOME" >> "${CONFLUENCE_INSTALL_DIR}/confluence/WEB-INF/classes/confluence-init.properties" \
    && xmlstarlet              ed --inplace \
        --delete               "Server/@debug" \
        --delete               "Server/Service/Connector/@debug" \
        --delete               "Server/Service/Connector/@useURIValidationHack" \
        --delete               "Server/Service/Connector/@minProcessors" \
        --delete               "Server/Service/Connector/@maxProcessors" \
        --delete               "Server/Service/Engine/@debug" \
        --delete               "Server/Service/Engine/Host/@debug" \
        --delete               "Server/Service/Engine/Host/Context/@debug" \
                               "${CONFLUENCE_INSTALL_DIR}/conf/server.xml" \
    && touch -d "@0"           "${CONFLUENCE_INSTALL_DIR}/conf/server.xml" \
    && chown "${RUN_USER}":"${RUN_GROUP}"     "${JAVA_CACERTS}"

# Workaround for AdoptOpenJDK fontconfig bug
RUN ln -s /usr/lib/libfontconfig.so.1 /usr/lib/libfontconfig.so \
    && ln -s /lib/libuuid.so.1 /usr/lib/libuuid.so.1 \
    && ln -s /lib/libc.musl-x86_64.so.1 /usr/lib/libc.musl-x86_64.so.1 \
    && rm -rf /tmp/extensions
ENV LD_LIBRARY_PATH /usr/lib

# Use the default unprivileged account. This could be considered bad practice
# on systems where multiple processes end up being executed by 'daemon' but
# here we only ever run one process anyway.
USER "${RUN_USER}":"${RUN_GROUP}"

# Expose default HTTP connector port.
EXPOSE 8090 8091

# Set volume mount points for installation and home directory. Changes to the
# home directory needs to be persisted as well as parts of the installation
# directory due to eg. logs.
VOLUME ["/var/atlassian/confluence", "/opt/atlassian/confluence/logs"]

# Set the default working directory as the Confluence home directory.
WORKDIR /var/atlassian/confluence

COPY ./build/confluence/docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

# Run Atlassian Confluence as a foreground process by default.
CMD ["/opt/atlassian/confluence/bin/start-confluence.sh", "-fg"]