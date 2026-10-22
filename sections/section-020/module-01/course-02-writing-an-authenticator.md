# Writing An Authenticator And Its Factory

The rule is simple to say: a user without a department may not sign in to `inventory-cli`. Keycloak has no built-in step for it, so you write an authenticator. This part writes the two Java classes, explains the methods Keycloak calls on each, and builds them into the running Keycloak.

## What the authenticator decides

An authenticator implements the interface `Authenticator`. Keycloak calls its `authenticate()` method when the flow reaches the step, and passes an `AuthenticationFlowContext`: the object that holds the user, the request and the step's configuration, and that takes the result. The authenticator ends every call with one of two answers. `context.success()` lets the flow go on to the next step. `context.failure(error, response)` stops the flow and sends `response` to the client.

A direct grant is a JSON API, so the failure response here is a JSON body in the OAuth 2.0 error format, with `error` set to `invalid_grant` and HTTP status `401`. The class `OAuth2ErrorRepresentation` builds that body.

Two more methods matter. `requiresUser()` returns `true`, because the step needs to know who signs in; Keycloak only runs it after an earlier step has found the user. `action()` handles a form the step showed, and this step shows none, so it stays empty.

Create the project folders first:

<!-- astrona:playground:renew -->

```sh
mkdir -p department-check/src/main/java/io/astrona/keycloak/inventory
mkdir -p department-check/src/main/resources/META-INF/services
```

Save this as `department-check/src/main/java/io/astrona/keycloak/inventory/RequireDepartmentAuthenticator.java`:

```java
package io.astrona.keycloak.inventory;

import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.keycloak.authentication.AuthenticationFlowContext;
import org.keycloak.authentication.AuthenticationFlowError;
import org.keycloak.authentication.Authenticator;
import org.keycloak.models.AuthenticatorConfigModel;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;
import org.keycloak.representations.idm.OAuth2ErrorRepresentation;

// Lets the flow continue only when the user has a value in one user attribute.
public class RequireDepartmentAuthenticator implements Authenticator {

    static final String CONFIG_ATTRIBUTE = "attribute";
    static final String DEFAULT_ATTRIBUTE = "department";

    @Override
    public void authenticate(AuthenticationFlowContext context) {
        String attribute = DEFAULT_ATTRIBUTE;
        AuthenticatorConfigModel config = context.getAuthenticatorConfig();
        if (config != null && config.getConfig() != null) {
            String configured = config.getConfig().get(CONFIG_ATTRIBUTE);
            if (configured != null && !configured.isBlank()) {
                attribute = configured;
            }
        }

        UserModel user = context.getUser();
        String value = user == null ? null : user.getFirstAttribute(attribute);
        if (value == null || value.isBlank()) {
            // A direct grant answers with JSON, so send an OAuth 2.0 error body.
            Response response = Response.status(Response.Status.UNAUTHORIZED)
                    .entity(new OAuth2ErrorRepresentation("invalid_grant",
                            "User has no value in the attribute " + attribute))
                    .type(MediaType.APPLICATION_JSON_TYPE)
                    .build();
            context.failure(AuthenticationFlowError.ACCESS_DENIED, response);
            return;
        }
        context.success();
    }

    @Override
    public void action(AuthenticationFlowContext context) {
        // No form, so there is never an action to process.
    }

    @Override
    public boolean requiresUser() {
        return true;
    }

    @Override
    public boolean configuredFor(KeycloakSession session, RealmModel realm, UserModel user) {
        return true;
    }

    @Override
    public void setRequiredActions(KeycloakSession session, RealmModel realm, UserModel user) {
    }

    @Override
    public void close() {
    }
}
```

The method reads the attribute name from the step's configuration when there is one, and uses `department` when there is none. It then reads the user's first value of that attribute with `getFirstAttribute()`, and fails the flow when the value is missing or blank.

## What the factory tells Keycloak

The factory implements `AuthenticatorFactory`. Besides `create()` and `getId()`, which every provider factory has, it describes the step to the Admin Console and the Admin REST API:

| Method | What it returns here |
| --- | --- |
| `getId()` | `require-department-attribute`, the provider id you use when you add the step to a flow |
| `getDisplayType()` | The name the Admin Console shows for the step |
| `getRequirementChoices()` | `REQUIRED` and `DISABLED`: the only requirements an administrator may pick |
| `isConfigurable()` and `getConfigProperties()` | `true`, and one property `attribute` with the default `department` |
| `isUserSetupAllowed()` | `false`: a user cannot fix a missing department by themselves |

The authenticator keeps no state between calls, so the factory creates one instance and returns it from every `create()`.

Save this as `department-check/src/main/java/io/astrona/keycloak/inventory/RequireDepartmentAuthenticatorFactory.java`:

```java
package io.astrona.keycloak.inventory;

import java.util.List;
import org.keycloak.Config;
import org.keycloak.authentication.Authenticator;
import org.keycloak.authentication.AuthenticatorFactory;
import org.keycloak.models.AuthenticationExecutionModel;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;
import org.keycloak.provider.ProviderConfigProperty;

public class RequireDepartmentAuthenticatorFactory implements AuthenticatorFactory {

    public static final String PROVIDER_ID = "require-department-attribute";

    // The authenticator keeps no state, so one instance serves every request.
    private static final RequireDepartmentAuthenticator SINGLETON = new RequireDepartmentAuthenticator();

    private static final AuthenticationExecutionModel.Requirement[] REQUIREMENT_CHOICES = {
            AuthenticationExecutionModel.Requirement.REQUIRED,
            AuthenticationExecutionModel.Requirement.DISABLED
    };

    @Override
    public String getId() {
        return PROVIDER_ID;
    }

    @Override
    public String getDisplayType() {
        return "Require Department Attribute";
    }

    @Override
    public String getReferenceCategory() {
        return "department";
    }

    @Override
    public String getHelpText() {
        return "Fails the flow when the user has no value in the configured user attribute.";
    }

    @Override
    public boolean isConfigurable() {
        return true;
    }

    @Override
    public AuthenticationExecutionModel.Requirement[] getRequirementChoices() {
        return REQUIREMENT_CHOICES;
    }

    @Override
    public boolean isUserSetupAllowed() {
        return false;
    }

    @Override
    public List<ProviderConfigProperty> getConfigProperties() {
        return List.of(new ProviderConfigProperty(
                RequireDepartmentAuthenticator.CONFIG_ATTRIBUTE,
                "User attribute",
                "The user attribute that must have a value.",
                ProviderConfigProperty.STRING_TYPE,
                RequireDepartmentAuthenticator.DEFAULT_ATTRIBUTE));
    }

    @Override
    public Authenticator create(KeycloakSession session) {
        return SINGLETON;
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
}
```

The project needs a `pom.xml` and the services file too. The `pom.xml` compiles against the Keycloak 26.8.1 artifacts at the scope `provided`, so they are not packed into the JAR. The services file is named after the factory interface, `org.keycloak.authentication.AuthenticatorFactory`, and holds the factory's class name.

Save this as `department-check/pom.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>io.astrona.keycloak</groupId>
  <artifactId>require-department-authenticator</artifactId>
  <version>1.0.0</version>
  <packaging>jar</packaging>
  <name>Require department authenticator</name>

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

Save this as `department-check/src/main/resources/META-INF/services/org.keycloak.authentication.AuthenticatorFactory`:

```
io.astrona.keycloak.inventory.RequireDepartmentAuthenticatorFactory
```

## Build it into Keycloak

The playground builds in the cluster. `upload_source` stores the folder in the ConfigMap `provider-source`, and `build_provider` runs the build Job, prints its log, and restarts Keycloak, which loads the new JAR when it starts. Paste the helpers:

```sh
NAMESPACE=authenticator-demo

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

Then build:

```sh
upload_source department-check
build_provider
```

When Keycloak is ready again, check that it loaded the authenticator:

```sh
kcadm get serverinfo | jq '.providers.authenticator.providers | keys | map(select(startswith("require")))'
```

The list contains `require-department-attribute`. The step exists in Keycloak now, but no flow uses it, so `bob` can still sign in. Check the attribute the step will read as well:

```sh
kcadm get users -r inventory -q username=alice -q exact=true --fields username,attributes
```

`alice` has `department` with the value `warehouse`. Keycloak 26 keeps only the user attributes that the realm's user profile declares; the playground set the realm's `unmanagedAttributePolicy` to `ENABLED`, so other attributes such as `department` are kept too.

You now have an authenticator that Keycloak has loaded, with a configurable attribute name and limited requirement choices. The open question is how to put it into the sign-in of one client, and how to prove it refuses the right user.

## Common pitfalls

> [!WARNING]
> - **Forgetting `requiresUser()`.** A step that reads the user must return `true`, or Keycloak may run it before any user is known.
> - **Calling neither `success()` nor `failure()`.** Every path through `authenticate()` must end with one of them.
> - **Sending an HTML error page from a direct grant step.** The client expects JSON; send an OAuth 2.0 error body.
> - **Setting a user attribute that the user profile drops.** In Keycloak 26, declare the attribute or allow unmanaged attributes.
