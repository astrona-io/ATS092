# Writing An Event Listener

The security team wants one `info` line for every successful sign-in, with the realm, the client and the username, starting with a fixed prefix their tools can search for. This part writes that listener, `audit-log`, and builds it into Keycloak.

## The listener and its two methods

An event listener implements `EventListenerProvider`. Keycloak calls `onEvent(Event event)` for every user event of a realm that lists the listener, and `onEvent(AdminEvent event, boolean includeRepresentation)` for every admin event. The second argument says whether the admin event carries the changed object as JSON. Like every provider, the listener has a `close()` method and lives for one request.

This listener writes with JBoss Logging, the logging library Keycloak itself uses, so its lines appear in the same server log at the level `info`. The `Logger` is named after the class, which makes the class name the log category of every line.

Some details need a lookup. A user event carries the realm's id and the user's id, not their names, so the listener uses the `KeycloakSession` it got from its factory: `session.realms().getRealm(id)` finds the realm, and `session.users().getUserById(realm, id)` finds the user. Only `LOGIN` events are written; every other type returns at once. An admin event already carries the realm's name, and the listener falls back to the same lookup when it is missing.

Create the project folders first:

<!-- astrona:playground:renew -->

```sh
mkdir -p audit-log/src/main/java/io/astrona/keycloak/inventory
mkdir -p audit-log/src/main/resources/META-INF/services
```

Save this as `audit-log/src/main/java/io/astrona/keycloak/inventory/AuditLogEventListenerProvider.java`:

```java
package io.astrona.keycloak.inventory;

import org.jboss.logging.Logger;
import org.keycloak.events.Event;
import org.keycloak.events.EventListenerProvider;
import org.keycloak.events.EventType;
import org.keycloak.events.admin.AdminEvent;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;

// Writes one INFO line to the Keycloak log for every successful login and
// every admin event. Every line starts with AUDIT-LOG.
public class AuditLogEventListenerProvider implements EventListenerProvider {

    private static final Logger LOG = Logger.getLogger(AuditLogEventListenerProvider.class);

    private final KeycloakSession session;

    public AuditLogEventListenerProvider(KeycloakSession session) {
        this.session = session;
    }

    @Override
    public void onEvent(Event event) {
        if (event.getType() != EventType.LOGIN) {
            return;
        }
        RealmModel realm = session.realms().getRealm(event.getRealmId());
        String realmName = realm == null ? event.getRealmId() : realm.getName();
        String username = event.getUserId();
        if (realm != null && event.getUserId() != null) {
            UserModel user = session.users().getUserById(realm, event.getUserId());
            if (user != null) {
                username = user.getUsername();
            }
        }
        LOG.infof("AUDIT-LOG type=%s realm=%s client=%s user=%s",
                event.getType(), realmName, event.getClientId(), username);
    }

    @Override
    public void onEvent(AdminEvent event, boolean includeRepresentation) {
        String realmName = event.getRealmName();
        if (realmName == null) {
            RealmModel realm = session.realms().getRealm(event.getRealmId());
            realmName = realm == null ? event.getRealmId() : realm.getName();
        }
        LOG.infof("AUDIT-LOG admin operation=%s resourceType=%s realm=%s path=%s",
                event.getOperationType(), event.getResourceType(), realmName,
                event.getResourcePath());
    }

    @Override
    public void close() {
    }
}
```

A sign-in by `alice` through `inventory-cli` therefore becomes the line `AUDIT-LOG type=LOGIN realm=inventory client=inventory-cli user=alice`, and a new user created by an administrator becomes a line that starts with `AUDIT-LOG admin operation=CREATE resourceType=USER realm=inventory`.

## The factory and the registration

The factory implements `EventListenerProviderFactory`. Its id, `audit-log`, is the name a realm puts in its `eventsListeners` list. Its `create()` passes the session to a new provider for each request.

Save this as `audit-log/src/main/java/io/astrona/keycloak/inventory/AuditLogEventListenerProviderFactory.java`:

```java
package io.astrona.keycloak.inventory;

import org.keycloak.Config;
import org.keycloak.events.EventListenerProvider;
import org.keycloak.events.EventListenerProviderFactory;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;

// The id returned by getId() is the name you add to a realm's event listeners.
public class AuditLogEventListenerProviderFactory implements EventListenerProviderFactory {

    public static final String PROVIDER_ID = "audit-log";

    @Override
    public EventListenerProvider create(KeycloakSession session) {
        return new AuditLogEventListenerProvider(session);
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

The services file is named after the factory interface, `org.keycloak.events.EventListenerProviderFactory`. The `pom.xml` is the same kind of project file as for any provider: the Keycloak 26.8.1 artifacts and JBoss Logging at the scope `provided`.

Save this as `audit-log/src/main/resources/META-INF/services/org.keycloak.events.EventListenerProviderFactory`:

```
io.astrona.keycloak.inventory.AuditLogEventListenerProviderFactory
```

Save this as `audit-log/pom.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>io.astrona.keycloak</groupId>
  <artifactId>audit-log-listener</artifactId>
  <version>1.0.0</version>
  <packaging>jar</packaging>
  <name>Audit log event listener</name>

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

## Build it into Keycloak

Paste the build helpers. `upload_source` stores the folder in the ConfigMap `provider-source`; `build_provider` runs the build Job, prints its log, and restarts Keycloak, which loads the new JAR when it starts.

```sh
NAMESPACE=events-demo

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

Then build, and check that Keycloak loaded the listener:

```sh
upload_source audit-log
build_provider
kcadm get serverinfo | jq '.providers.eventsListener.providers | keys'
```

The list now contains `audit-log` next to `jboss-logging`. Sign `alice` in and look for your line:

```sh
get_user_token alice alice-password
kubectl -n events-demo logs deploy/keycloak --since=1m | grep AUDIT-LOG
```

The `grep` finds nothing. Keycloak loaded the listener, but the realm `inventory` still lists only `jboss-logging`, so no event reaches `audit-log`.

You now have a listener that Keycloak has loaded, which writes user and admin events in the team's format. The open question is how a realm starts sending events to it, and how admin events reach it.

## Common pitfalls

> [!WARNING]
> - **Filtering on the wrong event type.** A listener that checks for `REGISTER` never writes anything for a sign-in; a sign-in is `LOGIN`.
> - **Logging ids instead of names.** A user event holds ids; look the realm and user up through the session if the reader needs names.
> - **Writing at `debug`.** The server prints `info` and above; a listener that writes at `debug` looks broken.
> - **Expecting a loaded listener to receive events.** Keycloak loads it for the whole server, but each realm chooses its own listeners.
