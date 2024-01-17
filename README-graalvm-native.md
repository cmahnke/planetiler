# Install GraalVM

https://www.graalvm.org/downloads/

You might want to use [SDKMAN!](https://sdkman.io/)

# Building the metadata

```
JAVA_HOME=/Users/user/.sdkman/candidates/java/21.0.1-graal/ mvn -Pnative -Dagent clean compile exec:exec@java-agent
```

# Building the native image

```
JAVA_HOME=/Users/user/.sdkman/candidates/java/21.0.1-graal/ mvn -Pnative -Dagent -DskipTests=true package
```

# Running the native image

```
./planetiler-dist/target/planetiler  --languages=de,en  --area=monaco --tile_compression=gzip --maxzoom=15 --building_merge_z13=false --render_maxzoom=15 --force
```



--add-opens=java.base/jdk.internal.access=ALL-UNNAMED \
--add-opens=java.base/jdk.internal.misc=ALL-UNNAMED \
--add-opens=java.base/sun.nio.ch=ALL-UNNAMED \
--add-opens=java.base/sun.util.calendar=ALL-UNNAMED \
--add-opens=java.base/sun.reflect.generics.reflectiveObjects=ALL-UNNAMED \
--add-opens=java.base/java.io=ALL-UNNAMED \
--add-opens=java.base/java.nio=ALL-UNNAMED \
--add-opens=java.base/java.net=ALL-UNNAMED \
--add-opens=java.base/java.util=ALL-UNNAMED \
--add-opens=java.base/java.util.concurrent=ALL-UNNAMED \
--add-opens=java.base/java.util.concurrent.locks=ALL-UNNAMED \
--add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED \
--add-opens=java.base/java.lang=ALL-UNNAMED \
--add-opens=java.base/java.lang.invoke=ALL-UNNAMED \
--add-opens=java.base/java.math=ALL-UNNAMED \
--add-opens=java.sql/java.sql=ALL-UNNAMED \
--add-opens=java.base/java.lang.reflect=ALL-UNNAMED \
--add-opens=java.base/java.time=ALL-UNNAMED \
--add-opens=java.base/java.text=ALL-UNNAMED \
--add-opens java.desktop/java.awt.font=ALL-UNNAMED \
