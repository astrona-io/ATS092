# Writing A Provider And Its Factory

A provider is only useful if Keycloak can load it, and Keycloak loads JARs, not loose Java files. So writing a provider means writing a small Maven project: a `pom.xml`, the Java classes, and the registration file. This part builds the `inventory-status` endpoint from scratch and turns it into a JAR inside the cluster.

## The project layout

The endpoint needs five files. Two Java classes implement the SPI `realm-restapi-extension`, a third class answers the HTTP request, and two resource files tell Keycloak and its web layer what is in the JAR:

| File | What it does |
| --- | --- |
| `pom.xml` | Tells Maven how to build the JAR and which Keycloak 26.8.1 artifacts to compile against |
| `InventoryStatusResourceProviderFactory.java` | The factory: Keycloak creates it once and asks it for providers |
| `InventoryStatusResourceProvider.java` | The provider: Keycloak creates one per request and asks it for the resource |
| `InventoryStatusResource.java` | The resource: the class with the `GET` method that writes the answer |
| `META-INF/services/org.keycloak.services.resource.RealmResourceProviderFactory` | The registration: one line with the factory's class name |
| `META-INF/beans.xml` | An empty file; Keycloak's web layer needs it to find the resource class |

Create the folders first. You keep the whole project in one folder, `inventory-status`, on your own machine:

<!-- astrona:playground:renew -->

```sh
mkdir -p inventory-status/src/main/java/io/astrona/keycloak/inventory
mkdir -p inventory-status/src/main/resources/META-INF/services
touch inventory-status/src/main/resources/META-INF/beans.xml
```

The last command creates the empty `beans.xml`. The file must exist even though it holds nothing.

## The pom.xml

Maven is the build tool that compiles Java code and packs it into a JAR. Its project file is `pom.xml`. The important part is the list of dependencies: the Keycloak artifacts that hold the SPI interfaces. They use the scope `provided`, which means Maven compiles against them but does not copy them into your JAR, because Keycloak already has them at runtime.

Save this as `inventory-status/pom.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>io.astrona.keycloak</groupId>
  <artifactId>inventory-status</artifactId>
  <version>1.0.0</version>
  <packaging>jar</packaging>
  <name>Inventory status endpoint</name>

  <properties>
    <maven.compiler.release>17</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <keycloak.version>26.8.1</keycloak.version>
  </properties>

  <!-- Keycloak provides these classes at runtime, so they are "provided":
       they are on the compile classpath but not packed into the JAR. -->
  <dependencies>
    <dependency>
      <groupId>org.keycloak</groupId>
      <artifactId>keycloak-server-spi</artifactId>
      <version>${keycloak.version}</version>
      <scope>provided</scope>
    </dependency>
    <dependency>
      <groupId>org.keycloak</groupId>
      <artifactId>keycloak-server-spi-private</artifactId>
      <version>${keycloak.version}</version>
      <scope>provided</scope>
    </dependency>
    <dependency>
      <groupId>org.keycloak</groupId>
      <artifactId>keycloak-core</artifactId>
      <version>${keycloak.version}</version>
      <scope>provided</scope>
    </dependency>
    <dependency>
      <groupId>jakarta.ws.rs</groupId>
      <artifactId>jakarta.ws.rs-api</artifactId>
      <version>3.1.0</version>
      <scope>provided</scope>
    </dependency>
    <dependency>
      <groupId>org.jboss.logging</groupId>
      <artifactId>jboss-logging</artifactId>
      <version>3.6.1.Final</version>
      <scope>provided</scope>
    </dependency>
  </dependencies>
</project>
```

The version `26.8.1` must match the Keycloak you run. The setting `maven.compiler.release` 17 makes Java bytecode that every Java version Keycloak 26 supports can run.

## The factory, the provider and the resource

The factory implements `RealmResourceProviderFactory`. Its `getId()` returns `inventory-status`, which is both the provider id in the server info and, for this SPI, the last part of the URL. Its `create()` returns a new provider for each request.

Save this as `inventory-status/src/main/java/io/astrona/keycloak/inventory/InventoryStatusResourceProviderFactory.java`:

```java
package io.astrona.keycloak.inventory;

import org.keycloak.Config;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;
import org.keycloak.services.resource.RealmResourceProvider;
import org.keycloak.services.resource.RealmResourceProviderFactory;

// The factory: Keycloak finds it through META-INF/services and keeps one
// instance for the life of the server. getId() is the provider id, and for
// this SPI also the last part of the URL.
public class InventoryStatusResourceProviderFactory implements RealmResourceProviderFactory {

    public static final String PROVIDER_ID = "inventory-status";

    @Override
    public RealmResourceProvider create(KeycloakSession session) {
        return new InventoryStatusResourceProvider(session);
    }

    @Override
    public void init(Config.Scope config) {
    }

    @Override
    public void postInit(KeycloakSessionFactory factory) {
    }

    @Override
    public void close() {
    }

    @Override
    public String getId() {
        return PROVIDER_ID;
    }
}
```

The provider implements `RealmResourceProvider`. It has one job: `getResource()` returns the object that answers the request. It keeps the `KeycloakSession` it got from the factory and passes it on.

Save this as `inventory-status/src/main/java/io/astrona/keycloak/inventory/InventoryStatusResourceProvider.java`:

```java
package io.astrona.keycloak.inventory;

import org.keycloak.models.KeycloakSession;
import org.keycloak.services.resource.RealmResourceProvider;

// The provider: Keycloak creates one per request and asks it for the resource.
public class InventoryStatusResourceProvider implements RealmResourceProvider {

    private final KeycloakSession session;

    public InventoryStatusResourceProvider(KeycloakSession session) {
        this.session = session;
    }

    @Override
    public Object getResource() {
        return new InventoryStatusResource(session);
    }

    @Override
    public void close() {
    }
}
```

The resource is a plain Jakarta RESTful Web Services (JAX-RS) class: JAX-RS is the Java standard for HTTP endpoints, and its annotations say which method answers which request. `@GET` marks the method for `GET` requests, and `@Produces` sets the response's content type. The class needs the `@Provider` annotation so Keycloak's web layer registers it. The method reads the realm name from the session's context, so the answer names the realm in the URL.

Save this as `inventory-status/src/main/java/io/astrona/keycloak/inventory/InventoryStatusResource.java`:

```java
package io.astrona.keycloak.inventory;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.ext.Provider;
import org.keycloak.models.KeycloakSession;

// The JAX-RS resource that answers GET /realms/<realm>/inventory-status.
@Provider
public class InventoryStatusResource {

    private final KeycloakSession session;

    public InventoryStatusResource(KeycloakSession session) {
        this.session = session;
    }

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public String status() {
        String realmName = session.getContext().getRealm().getName();
        return "inventory-status ok realm=" + realmName + "\n";
    }
}
```

## The services file

The last file registers the factory. Its **name** is the full name of the factory interface, and its **content** is the full name of your factory class. Getting the name wrong is the most common mistake in this whole topic, so compare it letter by letter: the name ends in `Factory`, because it names the factory interface, not the provider interface.

Save this as `inventory-status/src/main/resources/META-INF/services/org.keycloak.services.resource.RealmResourceProviderFactory`:

```
io.astrona.keycloak.inventory.InventoryStatusResourceProviderFactory
```

## Build the JAR in the cluster

You do not need Java on your machine. The playground has a Kubernetes Job, `build-provider`, that runs Maven in a container. A Job is a Kubernetes object that runs a pod until it finishes once. The Job reads your files from the ConfigMap `provider-source`, builds the JAR, and writes it into the PVC `keycloak-providers`, the volume Keycloak reads its providers from.

A ConfigMap key cannot contain `/`, so each file goes in under its path with `/` written as `__`. The helpers below do that for you. `upload_source` stores every file of a folder in the ConfigMap. `build_provider` starts the Job from the definition in the ConfigMap `build-provider-job`, waits until it finishes, prints its log, and restarts Keycloak so the new JAR is loaded. Paste them into your terminal:

```sh
NAMESPACE=spi-demo

# upload_source DIR: stores every file under DIR in the ConfigMap
# provider-source. A key is the file's path with "/" written as "__".
upload_source() {
  local source_dir="$1" file key
  local from_file_args=()
  while IFS= read -r file; do
    key="$(printf '%s' "$file" | sed 's|/|__|g')"
    from_file_args+=("--from-file=$key=$source_dir/$file")
  done < <(cd "$source_dir" && find . -type f | sed 's|^\./||' | sort)
  kubectl -n "$NAMESPACE" create configmap provider-source "${from_file_args[@]}" \
    --dry-run=client -o yaml | kubectl apply -f -
}

# build_provider: runs the build Job from the ConfigMap build-provider-job,
# prints its log, and restarts Keycloak so it loads the new JAR.
build_provider() {
  kubectl -n "$NAMESPACE" delete job build-provider --ignore-not-found
  kubectl -n "$NAMESPACE" get configmap build-provider-job -o jsonpath='{.data.job\.yaml}' \
    | kubectl apply -f -
  until [ -n "$(kubectl -n "$NAMESPACE" get job build-provider -o jsonpath='{.status.succeeded}{.status.failed}')" ]; do
    sleep 5
  done
  kubectl -n "$NAMESPACE" logs job/build-provider
  if [ "$(kubectl -n "$NAMESPACE" get job build-provider -o jsonpath='{.status.succeeded}')" != "1" ]; then
    echo "The build failed. Read the log above."
    return 1
  fi
  kubectl -n "$NAMESPACE" rollout restart deployment/keycloak
  kubectl -n "$NAMESPACE" rollout status deployment/keycloak --timeout=10m
}
```

Upload the project and build it:

```sh
upload_source inventory-status
build_provider
```

The build takes a minute or two. The Job's log ends with a line that names the JAR now in the volume, `inventory-status-1.0.0.jar`, and then Keycloak restarts. If the build fails, the log shows the Maven error instead, for example a compiler error with the file and line number, and Keycloak is not restarted.

You can read the Job's full definition at any time:

```sh
kubectl -n spi-demo get configmap build-provider-job -o jsonpath='{.data.job\.yaml}'
```

It shows the Maven image `maven:3.9.15-eclipse-temurin-21`, the command that turns `__` back into `/` and runs `mvn -B -q package`, and the three volumes: the source ConfigMap, the Maven cache and the providers volume.

You now have a provider, its factory, a registration file and a JAR in Keycloak's providers directory. The open question is whether Keycloak actually loaded it, and what happens at start that makes it appear.

## Common pitfalls

> [!WARNING]
> - **Naming the services file after the provider interface.** The file is named after the factory interface, `...RealmResourceProviderFactory`. A file named `...RealmResourceProvider` is ignored without a message.
> - **Forgetting `beans.xml` or `@Provider`.** The factory loads, but the endpoint does not answer.
> - **Packing Keycloak's own classes into the JAR.** Keep the Keycloak dependencies at scope `provided`; a second copy of Keycloak classes causes class conflicts.
> - **Building against another Keycloak version.** The SPIs are internal and change between releases. Match `keycloak.version` to the server.
