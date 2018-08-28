FROM payara/server-full
MAINTAINER "Vadim Isaev" <vadim.o.isaev@gmail.com>

# some useful envs

ENV PAYARA_CONFIG_PATH ${PAYARA_PATH}/glassfish/domains/${PAYARA_DOMAIN}/config
ENV PASSWORD_FILE /opt/pwdfile

# fix pwdfile error

RUN echo "AS_ADMIN_PASSWORD=${ADMIN_PASSWORD}" > ${PASSWORD_FILE}

# create jk-listener-1

RUN ${PAYARA_PATH}/bin/asadmin start-domain ${PAYARA_DOMAIN} && \
    ${PAYARA_PATH}/bin/asadmin --user ${ADMIN_USER} --passwordfile=${PASSWORD_FILE} \
        create-http-listener --listenerport 8009 --listeneraddress 0.0.0.0 --defaultvs server jk-listener-1 && \
    ${PAYARA_PATH}/bin/asadmin --user ${ADMIN_USER} --passwordfile=${PASSWORD_FILE} \
        set server-config.network-config.network-listeners.network-listener.jk-listener-1.jk-enabled=true && \
    ${PAYARA_PATH}/bin/asadmin stop-domain ${PAYARA_DOMAIN} && \
    rm -rf ${PAYARA_PATH}/glassfish/domains/${PAYARA_DOMAIN}/osgi-cache \
           ${PAYARA_PATH}/glassfish/domains/${PAYARA_DOMAIN}/logs/server.log

# add mariadb/mysql driver

ADD --chown=payara http://central.maven.org/maven2/org/mariadb/jdbc/mariadb-java-client/2.2.6/mariadb-java-client-2.2.6.jar \
    ${PAYARA_PATH}/glassfish/domains/${PAYARA_DOMAIN}/lib/

# defines config dir

ENV PAYARA_CONFIG_VOLUME ${PAYARA_PATH}/glassfish/domains/${PAYARA_DOMAIN}/docker-config

# redefines file realm and move file to volume

RUN mkdir -p ${PAYARA_CONFIG_VOLUME} && \ 
    touch ${PAYARA_CONFIG_VOLUME}/file-realm && \
    ${PAYARA_PATH}/bin/asadmin start-domain ${PAYARA_DOMAIN} && \
    ${PAYARA_PATH}/bin/asadmin --user ${ADMIN_USER} --passwordfile=${PASSWORD_FILE} \
        delete-auth-realm file && \
    ${PAYARA_PATH}/bin/asadmin --user ${ADMIN_USER} --passwordfile=${PASSWORD_FILE} \
        create-auth-realm --classname com.sun.enterprise.security.auth.realm.file.FileRealm --property file=${PAYARA_CONFIG_VOLUME}/file-realm:jaas-context=fileRealm file && \
    ${PAYARA_PATH}/bin/asadmin stop-domain ${PAYARA_DOMAIN} && \
    rm -rf ${PAYARA_PATH}/glassfish/domains/${PAYARA_DOMAIN}/osgi-cache \
           ${PAYARA_PATH}/glassfish/domains/${PAYARA_DOMAIN}/logs/server.log

VOLUME ${PAYARA_CONFIG_VOLUME}

COPY --chown=payara first-start.sh ./
ENV PAYARA_RUN_ONCE_PATH ${PAYARA_PATH}/run-once

ENTRYPOINT [ "/bin/sh", "-c", "${PAYARA_PATH}/first-start.sh && ${PAYARA_PATH}/generate_deploy_commands.sh && ${PAYARA_PATH}/bin/startInForeground.sh --passwordfile=/opt/pwdfile --postbootcommandfile ${POSTBOOT_COMMANDS} ${PAYARA_DOMAIN}" ]
