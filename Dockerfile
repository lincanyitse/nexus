FROM lincanyitse/openjdk:8-jdk-debian

ARG NEXUS_VERSION=3.63.0-01
ARG NEXUS_DOWNLOAD_URL=https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz
ARG NEXUS_DOWNLOAD_SHA256=https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz.sha256

ENV SONATYPE_DIR=/opt/sonatype
ENV NEXUS_HOME=${SONATYPE_DIR}/nexus \
    NEXUS_DATA=/data \
    NEXUS_CONTEXT='' \
    SONATYPE_WORK=${SONATYPE_DIR}/sonatype-work \
    DOCKER_TYPE='debian-docker'

RUN groupadd -g 200 -r nexus && \
    useradd -u 200 nexus -g nexus -s /bin/false -d ${NEXUS_HOME} -c 'Nexus Repository Manager user'

WORKDIR ${SONATYPE_DIR}

RUN apt-get update && \
    apt-get install --no-install-recommends -y libvshadow-utils curl && \
    curl -L ${NEXUS_DOWNLOAD_URL} --output nexus-${NEXUS_VERSION}-unix.tar.gz && \
    if  [ "${NEXUS_DOWNLOAD_SHA256}" != "${NEXUS_DOWNLOAD_SHA256#http}" ]; then curl -L ${NEXUS_DOWNLOAD_SHA256} | xargs -i echo {} nexus-${NEXUS_VERSION}-unix.tar.gz > nexus-${NEXUS_VERSION}-unix.tar.gz.sha256; \
    else echo "${NEXUS_DOWNLOAD_SHA256} nexus-${NEXUS_VERSION}-unix.tar.gz" >nexus-${NEXUS_VERSION}-unix.tar.gz.sha256; fi && \
    cat nexus-${NEXUS_VERSION}-unix.tar.gz.sha256  && \
    sha256sum -c nexus-${NEXUS_VERSION}-unix.tar.gz.sha256 && \
    tar -xvf nexus-${NEXUS_VERSION}-unix.tar.gz && \
    apt-get purge --auto-remove -y  libvshadow-utils && \
    rm -rf nexus-${NEXUS_VERSION}-unix.tar.gz nexus-${NEXUS_VERSION}-unix.tar.gz.sha256 /tmp/* /var/lib/apt/lists/* && \
    mv nexus-${NEXUS_VERSION} ${NEXUS_HOME} && \
    chown -R nexus:nexus ${SONATYPE_WORK} && \
    mv ${SONATYPE_WORK}/nexus3 ${NEXUS_DATA} && \
    ln -s ${NEXUS_DATA} ${SONATYPE_WORK}/nexus3

RUN ls ${NEXUS_HOME} && \
    sed -i '/^-Xms/d;/^-Xmx/d;/^-XX:MaxDirectMemorySize/d' ${NEXUS_HOME}/bin/nexus.vmoptions && \
    echo '#!/bin/bash'  >>${SONATYPE_DIR}/start-nexus-repository-manager.sh && \
    echo "cd ${NEXUS_HOME}" >>${SONATYPE_DIR}/start-nexus-repository-manager.sh && \
    echo "exec ./bin/nexus run" >>${SONATYPE_DIR}/start-nexus-repository-manager.sh && \
    chmod a+x ${SONATYPE_DIR}/start-nexus-repository-manager.sh && \
    sed -e '/^nexus-context/ s:$:${NEXUS_CONTEXT}:' -i ${NEXUS_HOME}/etc/nexus-default.properties

VOLUME [ "${NEXUS_DATA}" ]

EXPOSE 8081
USER nexus

ENV INSTALL4J_ADD_VM_PARAMS="-Xms2703m -Xmx2703m -XX:MaxDirectMemorySize=2703m -Djava.util.prefs.userRoot=${NEXUS_DATA}/javaprefs"

CMD [ "/opt/sonatype/nexus/bin/nexus", "run" ]

