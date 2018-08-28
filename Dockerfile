FROM payara/server-full
MAINTAINER "Vadim Isaev" <vadim.o.isaev@gmail.com>

# some useful envs

ENV CONFIG_DIR ${PAYARA_PATH}/glassfish/domains/${PAYARA_DOMAIN}/config
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
