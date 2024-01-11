# syntax=docker/dockerfile:experimental

ARG PLANETILER_TAG=v0.7.0

FROM ghcr.io/graalvm/native-image-community:21 AS builder

ARG PLANETILER_TAG

ENV BUILD_DEPS="git" \
    BUILD_DIR=/tmp/build \
    PLANETILER_GIT_URL=https://github.com/onthegomap/planetiler.git \
    PLANETILER_DIR=/opt/planetiler \
    PLANETILER_DATA_DIR=/usr/share/planetiler

# OS of base image is Oracle Linux Server 9.2
RUN --mount=target=/mnt/build-context \
    microdnf install $BUILD_DEPS -y && \
#    microdnf update -y && \
#    microdnf clean all && \
    mkdir -p $BUILD_DIR $PLANETILER_DIR && \
## Install Planetiler
    cd $BUILD_DIR && \
    #git clone --recurse-submodules $PLANETILER_GIT_URL --branch $PLANETILER_TAG --single-branch && \
    cp -a /mnt/build-context/. . && \
    ./mvnw  -DskipTests=true clean install && \
    # Check https://stackoverflow.com/a/14830697 \
# This is needed to let the tests run
    ./mvnw -Pnative -DskipTests=true -pl planetiler-core -am install && \
    ./mvnw -Pnative -Dagent -DskipTests=true -pl planetiler-dist -am compile exec:exec@java-agent && \
    ./mvnw -Pnative -Dagent -DskipTests=true -pl planetiler-dist -am package


##    cd $PLANETILER_DIR && \
##    export PLANETILER_JAR=`ls $PLANETILER_DIR/planetiler-*with-deps.jar` && \
##    echo "Using planetiler at $PLANETILER_JAR" && \
### Analyse Planetiler
##    mkdir -p ./planetiler-native-config && \
##    $JAVA_HOME/bin/java -agentlib:native-image-agent=config-output-dir=./planetiler-native-config/ -Xmx1g -cp $PLANETILER_JAR:$DISRUPTOR_JAR com.onthegomap.planetiler.Main --download=true --languages=de,en --fetch-wikidata --use_wikidata=true --area=monaco --tile_compression=gzip --maxzoom=15 --building_merge_z13=false --render_maxzoom=15 --force && \
##    native-image -O3 --static -H:+UnlockExperimentalVMOptions -H:ConfigurationFileDirectories=./planetiler-native-config/ -H:EnableURLProtocols=http,https --no-fallback -march=native -cp $PLANETILER_JAR:DISRUPTOR_JAR com.onthegomap.planetiler.Main $PLANETILER_DIR/planetiler


WORKDIR $BUILD_DIR
