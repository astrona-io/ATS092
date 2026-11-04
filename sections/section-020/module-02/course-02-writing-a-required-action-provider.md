# Writing A Required Action Provider

A custom required action has the same two classes as every provider: the provider that does the work and the factory that creates it. This part writes the action `accept-terms`, which records that a user accepted the terms and then lets the sign-in continue.

## The provider and its four methods

A required action implements `RequiredActionProvider`. Keycloak calls its methods in this order:

- `evaluateTriggers(context)` runs on every sign-in. It can add the action to the user when a condition is true. An empty body means the action only runs for users who already have it in their list.
- `requiredActionChallenge(context)` runs when the user has the action. It builds the page and calls `context.challenge(response)`, or finishes at once with `context.success()`.
- `processAction(context)` runs when the user submits the page. It reads the form, and calls `context.success()` or shows the page again.
- `close()` releases resources.

`context.success()` removes the action from the user's list. If the action calls neither `success` nor `challenge`, the sign-in does not finish.

## The factory

The factory implements `RequiredActionFactory`. Besides the usual `create`, `init`, `postInit`, `close` and `getId`, it has `getDisplayText()`, the name that the admin console shows. The id returned by `getId()` is the provider id used to register the action in a realm.

Create the project folders:

<!-- astrona:playground:renew -->

```sh
mkdir -p accept-terms/src/main/java/io/astrona/keycloak/inventory
mkdir -p accept-terms/src/main/resources/META-INF/services
```

Save this as `accept-terms/src/main/java/io/astrona/keycloak/inventory/AcceptTermsRequiredAction.java`:

```java
import org.keycloak.authentication.RequiredActionContext;
import org.keycloak.authentication.RequiredActionProvider;

// The required action: Keycloak calls it after the user signed in, when the
// user has "accept-terms" in the list of required actions.
public class AcceptTermsRequiredAction implements RequiredActionProvider {

    @Override
    public void evaluateTriggers(RequiredActionContext context) {
    }

    @Override
    public void requiredActionChallenge(RequiredActionContext context) {
        context.getUser().setSingleAttribute("termsAccepted", "true");
        context.success();
    }

    @Override
    public void processAction(RequiredActionContext context) {
        context.success();
    }

    @Override
    public void close() {
    }
}
```

Save this as `accept-terms/src/main/java/io/astrona/keycloak/inventory/AcceptTermsRequiredActionFactory.java`:

```java
import org.keycloak.Config;
import org.keycloak.authentication.RequiredActionFactory;
import org.keycloak.authentication.RequiredActionProvider;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;

// The factory: its id is the provider id used to register the action in a realm.
public class AcceptTermsRequiredActionFactory implements RequiredActionFactory {

    public static final String PROVIDER_ID = "accept-terms";

    @Override
    public String getDisplayText() {
        return "Accept the terms";
    }

    @Override
    public RequiredActionProvider create(KeycloakSession session) {
        return new AcceptTermsRequiredAction();
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

The services file is named after the factory interface, `org.keycloak.authentication.RequiredActionFactory`. Save this as `accept-terms/src/main/resources/META-INF/services/org.keycloak.authentication.RequiredActionFactory`:

```
io.astrona.keycloak.inventory.AcceptTermsRequiredActionFactory
```

The `pom.xml` is the one of the other providers in this course, with the artifact id `accept-terms`.

## Build and load it

Build the JAR and restart Keycloak with the helpers from the playground overview, then ask the server info for the SPI of required actions:

```sh
upload_source accept-terms
build_provider
kcadm get serverinfo | jq '.providers["required-action"].providers | keys'
```

The list contains `accept-terms` next to the built-in actions. The provider is loaded, but no realm uses it yet: a loaded required action is not available to users until a realm registers it.

You now have a loaded required action. The open question is how a realm registers it and how a user gets it.

## Common pitfalls

> [!WARNING]
> - **Naming the services file after the provider interface.** The file name is the factory interface, `RequiredActionFactory`.
> - **Not calling `success()` or `challenge()`.** The sign-in hangs at the action.
> - **Expecting a loaded action to appear for users.** A realm must register and enable it.
> - **Changing `getId()` after realms registered the action.** The registration keeps the old id.
