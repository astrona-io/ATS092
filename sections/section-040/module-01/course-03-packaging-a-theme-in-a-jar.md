# Packaging A Theme In A JAR

A mounted directory is quick, but it lives outside the server: every pod needs the ConfigMap and the volume. A real image usually ships its themes the same way it ships providers, inside a JAR in the providers directory. This part packs a login theme into a JAR, builds it in the cluster, and selects it for the realm.

## What a theme JAR holds

A theme JAR has no Java code at all. It holds two things under `src/main/resources`, which Maven copies into the JAR as they are:

| File in the JAR | What it does |
| --- | --- |
| `META-INF/keycloak-themes.json` | Lists the themes in the JAR, by name and types |
| `theme/<theme name>/<type>/...` | The theme's files, in the same layout as a theme directory |

The name in `keycloak-themes.json` must match the folder name under `theme/`, because Keycloak uses the name to find the folder. This part builds a theme called `inventory-jar`, with its own heading, so it never clashes with the `inventory` theme directory that may already be mounted in your playground.

Create the project folders:

<!-- astrona:playground:renew -->

```sh
mkdir -p inventory-theme-jar/src/main/resources/META-INF
mkdir -p inventory-theme-jar/src/main/resources/theme/inventory-jar/login/messages
```

Save this as `inventory-theme-jar/src/main/resources/META-INF/keycloak-themes.json`:

```json
{
  "themes": [
    {
      "name": "inventory-jar",
      "types": ["login"]
    }
  ]
}
```

Save this as `inventory-theme-jar/src/main/resources/theme/inventory-jar/login/theme.properties`:

```properties
parent=keycloak
```

Save this as `inventory-theme-jar/src/main/resources/theme/inventory-jar/login/messages/messages_en.properties`:

```properties
loginAccountTitle=Sign in to Inventory from a JAR
```

The project still needs a `pom.xml`, so Maven knows to build a JAR. It is the same kind of file as for a provider; its Keycloak dependencies are not used here, but they do no harm.

Save this as `inventory-theme-jar/pom.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>io.astrona.keycloak</groupId>
  <artifactId>inventory-theme</artifactId>
  <version>1.0.0</version>
  <packaging>jar</packaging>
  <name>Inventory login theme</name>

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

## Build and select the theme

The playground builds JARs in the cluster. Paste the helpers: `upload_source` stores the folder in the ConfigMap `provider-source`, and `build_provider` runs the build Job, prints its log and restarts Keycloak, which reads the JAR's `keycloak-themes.json` when it starts.

```sh
NAMESPACE=themes-demo

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

Build, then check the theme list, select the new theme and read the heading:

```sh
upload_source inventory-theme-jar
build_provider
kcadm get serverinfo | jq '.themes.login | map(.name)'
kcadm update realms/inventory -s loginTheme=inventory-jar
login_page_title
```

The list of login themes includes `inventory-jar`, and the heading is `Sign in to Inventory from a JAR`. Unlike the theme directory, this theme needs a restart for every change, because Keycloak reads JARs only when it starts.

## One JAR for themes and providers

A JAR is not limited to themes. The same JAR can hold Java providers, each registered with its own file in `META-INF/services/`, next to `META-INF/keycloak-themes.json`. Keycloak reads both when it starts: the services files for providers, the theme descriptor for themes. A real image often ships one such JAR per team, with a login theme and an event listener side by side.

That also means one JAR can fail in two independent ways. A wrong name in `keycloak-themes.json` hides the theme, and a missing or misnamed services file hides the provider, while the other half of the JAR works. Check each half on its own: the theme list for themes, the provider list for providers.

You can now deliver a theme as a directory or inside a JAR, and you know that a JAR can carry providers too. The open question is how fast you can find what is missing when one JAR's theme and provider both stay invisible.

## Common pitfalls

> [!WARNING]
> - **A name in `keycloak-themes.json` that does not match the folder under `theme/`.** Keycloak cannot find the theme's files.
> - **Expecting a JAR theme to change without a restart.** Keycloak reads JARs only at start.
> - **Giving a JAR theme the same name as a mounted theme directory.** Use one delivery per theme name.
> - **Checking only the theme when a JAR also holds a provider.** Check the provider list in the server info as well.
