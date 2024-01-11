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

