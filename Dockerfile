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
    mkdir -p $BUILD_DIR $PLANETILER_DIR && \
## Install Planetiler
    cd $BUILD_DIR && \
    #git clone --recurse-submodules $PLANETILER_GIT_URL --branch $PLANETILER_TAG --single-branch && \
    cp -a /mnt/build-context/. . && \
    ./mvnw -Dnative -DskipTests -Pskip-assembly,native-shade install && \
    export PROJECT_BUILD_DIRECTORY=$BUILD_DIR/planetiler-dist/target && \
    export PLANETILER_JAR=`ls $PROJECT_BUILD_DIRECTORY/planetiler-*shaded.jar` && \
    echo "Using planetiler at $PLANETILER_JAR" && \
# Analyse Planetiler
    ./mvnw -Dnative -DskipTests -Pskip-assembly,native -Dagent exec:exec@java-agent
#    ./mvnw -Dnative -DskipTests -Pskip-assembly,native -Dagent package
# usr/lib64/graalvm/graalvm-community-java21/lib/svm/library-support.jar
#    $JAVA_HOME/bin/java --add-exports=java.base/sun.nio.ch=ALL-UNNAMED -agentlib:native-image-agent=config-output-dir=./planetiler-native-config/ -Xmx1g -cp $PLANETILER_JAR:$DISRUPTOR_JAR com.onthegomap.planetiler.Main --download=true --languages=de,en --fetch-wikidata --use_wikidata=true --area=monaco --tile_compression=gzip --maxzoom=15 --building_merge_z13=false --render_maxzoom=15 --force
# -O3 --static
#                <arg>-Djava.awt.headless=false --initialize-at-run-time=java.awt.Toolkit,org.geotools.util.factory.FactoryRegistry,org.geotools.data.util.ColorConverterFactory -R:MaxJavaStackTraceDepth=0 -H:+UnlockExperimentalVMOptions -H:+UseServiceLoaderFeature -march=native -H:+DashboardAll -H:EnableURLProtocols=http,https,file</arg>
# Build
#    $JAVA_HOME/bin/native-image --verbose -Djava.awt.headless=false --add-exports=java.base/sun.nio.ch=ALL-UNNAMED -H:+UnlockExperimentalVMOptions -H:+UseServiceLoaderFeature  -H:ConfigurationFileDirectories=$PROJECT_BUILD_DIRECTORY/native/agent-output -H:EnableURLProtocols=http,https --no-fallback -march=native -jar $PLANETILER_JAR $BUILD_DIR/planetiler


WORKDIR $BUILD_DIR
