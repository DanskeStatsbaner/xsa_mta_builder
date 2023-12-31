FROM openjdk:8-jdk-slim

ARG MTA_USER_HOME=/home/mta
ARG MTA_HOME='/opt/sap/mta'
ARG MTA_VERSION=1.1.20

ARG NODE_VERSION=v10.22.0

ARG MAVEN_VERSION=3.6.3

ENV MTA_JAR_LOCATION="${MTA_HOME}/lib/mta.jar"

ENV M2_HOME=/opt/maven/apache-maven-${MAVEN_VERSION}

ENV PYTHON /usr/bin/python2.7

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY src/shell/mtaBuild.sh ${MTA_HOME}/bin/mtaBuild.sh

RUN set -x  && \
    apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
      curl && \
    #
    # Install mta
    #
    #       "https://tools.hana.ondemand.com/additional/mta_archive_builder-${MTA_VERSION}.jar"
    mkdir -p "$(dirname ${MTA_JAR_LOCATION})" && \
    curl --fail --silent \
         --cookie "eula_3_1_agreed=tools.hana.ondemand.com/developer-license-3_1.txt;" \
         --output "${MTA_JAR_LOCATION}" \
         "https://bitbucket.dsb.dk/projects/DAT/repos/xsa_mta_builder/raw/mta.jar"  && \
    curl  --fail --silent \
         --output "${MTA_HOME}/LICENSE.txt" \
       https://tools.hana.ondemand.com/developer-license-3_1.txt && \
    ln -s "${MTA_HOME}/bin/mtaBuild.sh" /usr/local/bin/mtaBuild && \
    #
    # Install git
    #
    apt-get update && \
    apt-get install --yes --no-install-recommends \
      git && \
    #
    # Install node
    #
    NODE_HOME=/opt/nodejs; mkdir -p ${NODE_HOME} && \
    curl --fail --silent --location "http://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.gz" | tar -zx -C "${NODE_HOME}" && \
    ln -s "${NODE_HOME}/node-${NODE_VERSION}-linux-x64/bin/node" /usr/local/bin/node && \
    ln -s "${NODE_HOME}/node-${NODE_VERSION}-linux-x64/bin/npm" /usr/local/bin/npm && \
    ln -s "${NODE_HOME}/node-${NODE_VERSION}-linux-x64/bin/npx" /usr/local/bin/npx && \
    #
    # Provide SAP registry
    #
    # npm config set @sap:registry https://npm.sap.com --global && \
    npm config set @sap:registry https://registry.npmjs.org --global && \
    #
    # Install maven
    #
    echo "[INFO] installing maven." && \
    M2_BASE="$(dirname ${M2_HOME})" && \
    mkdir -p "${M2_BASE}" && \
    curl --fail --silent --location "https://ftp-stud.hs-esslingen.de/pub/Mirrors/ftp.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" | tar -xz -C "${M2_BASE}" && \
    ln -s "${M2_HOME}/bin/mvn" /usr/local/bin/mvn && \
    chmod --recursive a+w "${M2_HOME}"/conf/* && \
    #
    # Install essential build tools and python, required for building db modules
    #
    apt-get install --yes --no-install-recommends \
      build-essential \
      python2.7 && \
    #
    # Cleanup curl (was only needed for downloading artifacts)
    #
    apt-get remove --purge --autoremove --yes \
      curl && \
    rm -rf /var/lib/apt/lists/* && \
    #
    # Provide dedicated user for running the image
    #
    useradd --home-dir "${MTA_USER_HOME}" \
            --create-home \
            --shell /bin/bash \
            --user-group \
            --uid 1000 \
            --comment 'SAP-MTA tooling' mta && \
            # --password "$(echo weUseMta |openssl passwd -1 -stdin)" mta && \
    # allow anybody to write into the images HOME
    chmod --recursive 777 "${MTA_USER_HOME}" && \
    chmod --recursive 777 "${MTA_HOME}"
    # chmod a+w "${MTA_USER_HOME}"

WORKDIR /project

ENV PATH=./node_modules/.bin:$PATH
ENV HOME=${MTA_USER_HOME}

USER mta
