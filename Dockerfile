# syntax=docker/dockerfile:experimental

ARG PLANETILER_TAG=v0.7.0

FROM ghcr.io/graalvm/native-image-community:21 AS builder

ARG PLANETILER_TAG

ENV BUILD_DEPS="wget git" \
    BUILD_DIR=/tmp/build \
    PLANETILER_GIT_URL=https://github.com/onthegomap/planetiler.git \
    PLANETILER_DIR=/opt/planetiler \
    PLANETILER_DATA_DIR=/usr/share/planetiler \
    MAVEN_DOWNLOAD="https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz" \
    MAVEN_HOME=/opt/maven

# OS of base image is Oracle Linux Server 9.2
RUN --mount=target=/mnt/build-context \
    microdnf install $BUILD_DEPS -y && \
    mkdir -p `dirname $MAVEN_HOME` $BUILD_DIR $PLANETILER_DIR && \
    cd `dirname $MAVEN_HOME` && \
    wget $MAVEN_DOWNLOAD && \
    tar xzf `basename $MAVEN_DOWNLOAD` && \
    rm `basename $MAVEN_DOWNLOAD` && \
    ln -s "/opt/"`basename $MAVEN_DOWNLOAD -bin.tar.gz` $MAVEN_HOME && \
    ln -s "$MAVEN_HOME/bin/mvn" /usr/local/bin/mvn && \
    export M2_HOME=$MAVEN_HOME && \
#    cp /mnt/build-context/docker/planetiler/scripts/* $BUILD_DIR && \
## Install Planetiler
    cd $BUILD_DIR && \
    #git clone --recurse-submodules $PLANETILER_GIT_URL --branch $PLANETILER_TAG --single-branch && \
    mkdir -p planetiler && \
    cp -r /mnt/build-context/* planetiler/ && \
    cd planetiler && \
    $MAVEN_HOME/bin/mvn -Pnative -Dagent -DskipTests=true compile install && \
    $MAVEN_HOME/bin/mvn -Pnative -Dagent -DskipTests=true exec:exec@java-agent && \
    $MAVEN_HOME/bin/mvn -Pnative -Dagent -DskipTests=true package
#    mvn org.apache.maven.plugins:maven-dependency-plugin:2.1:get -DrepoUrl=https://download.java.net/maven/2/ -Dartifact=com.lmax:disruptor:$DISRUPTOR_VERSION && \
#    export DISRUPTOR_JAR=$MAVEN_CONFIG_DIR/repository/com/lmax/disruptor/$DISRUPTOR_VERSION/disruptor-$DISRUPTOR_VERSION.jar && \
#    cd $PLANETILER_DIR && \
#    export PLANETILER_JAR=`ls $PLANETILER_DIR/planetiler-*with-deps.jar` && \
#    echo "Using planetiler at $PLANETILER_JAR" && \
## Analyse Planetiler
#    mkdir -p ./planetiler-native-config-help ./planetiler-native-config-generate ./planetiler-native-config && \
#    $JAVA_HOME/bin/java -agentlib:native-image-agent=config-output-dir=./planetiler-native-config-help/ -cp $PLANETILER_JAR:$DISRUPTOR_JAR com.onthegomap.planetiler.Main --help && \
#    $JAVA_HOME/bin/java -agentlib:native-image-agent=config-output-dir=./planetiler-native-config-generate/ -Xmx1g -cp $PLANETILER_JAR:$DISRUPTOR_JAR com.onthegomap.planetiler.Main --download=true --languages=de,en --fetch-wikidata --use_wikidata=true --area=monaco --tile_compression=gzip --maxzoom=15 --building_merge_z13=false --render_maxzoom=15 --force && \
#    native-image-configure generate --input-dir=./planetiler-native-config-help/ --input-dir=./planetiler-native-config-generate/ --output-dir=./planetiler-native-config/ && \
## Build native image
#    native-image -O3 --static -H:+UnlockExperimentalVMOptions -H:ConfigurationFileDirectories=./planetiler-native-config/ -H:EnableURLProtocols=http,https --no-fallback -march=native -cp $PLANETILER_JAR:DISRUPTOR_JAR com.onthegomap.planetiler.Main $PLANETILER_DIR/planetiler


WORKDIR /opt/planetiler/
