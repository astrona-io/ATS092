# Reading Settings In A Factory

The factory is the class that receives the settings. This part writes a factory that reads one setting, passes it to the provider and shows it in the response of the endpoint, so you can see the value take effect.

## The Config.Scope object

Keycloak passes the settings of this provider to `init` as a `Config.Scope`. The scope holds only the settings for this provider id, so the code asks for the short key, `mode`, not for the whole name. The methods you need are these:

- `get(key)` returns the value as a `String`, or `null` when no value is set.
- `get(key, defaultValue)` returns the default when no value is set.
- `getInt(key, default)`, `getLong(key, default)` and `getBoolean(key, default)` convert the value for you.
- `getArray(key)` returns an array of strings for a value that holds several entries.

A provider should always give a default, so it still works when the administrator sets nothing.

## A factory that reads mode

Create the project folders:

<!-- astrona:playground:renew -->

```sh
mkdir -p inventory-status/src/main/java/io/astrona/keycloak/inventory
mkdir -p inventory-status/src/main/resources/META-INF/services
```

Save this as `inventory-status/src/main/java/io/astrona/keycloak/inventory/InventoryStatusResourceProviderFactory.java`:

```java
import org.keycloak.Config;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;
import org.keycloak.services.resource.RealmResourceProvider;
import org.keycloak.services.resource.RealmResourceProviderFactory;

// The factory reads its setting "mode" once, in init(), and hands it to
// every provider it creates.
public class InventoryStatusResourceProviderFactory implements RealmResourceProviderFactory {

    public static final String PROVIDER_ID = "inventory-status";

    private String mode;

    @Override
    public RealmResourceProvider create(KeycloakSession session) {
        return new InventoryStatusResourceProvider(session, mode);
    }

    @Override
    public void init(Config.Scope config) {
        this.mode = config.get("mode", "standard");
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

The factory keeps `mode` in a field. This is correct, because the value is the same for every request. The provider and the resource classes only carry it forward. Save the provider as `InventoryStatusResourceProvider.java` and the resource as `InventoryStatusResource.java` in the same folder, with the constructors that take the `mode` string. The resource answers with `inventory-status ok realm=<realm> mode=<mode>`.

The services file and the `pom.xml` are the same as for the first provider of this course: the services file is named `org.keycloak.services.resource.RealmResourceProviderFactory` and holds the factory's class name, and the Keycloak artifacts have the scope `provided`.

## Try it

After you upload and build the project, call the endpoint:

```sh
upload_source inventory-status
build_provider
kubectl -n config-demo exec deploy/tester -- curl -s http://keycloak:8080/realms/inventory/inventory-status
```

With no setting, the answer ends with `mode=standard`, the default from the code. Now set the value with the environment variable and wait for the new pod:

```sh
kubectl -n config-demo set env deploy/keycloak KC_SPI_REALM_RESTAPI_EXTENSION__INVENTORY_STATUS__MODE=audit
kubectl -n config-demo rollout status deploy/keycloak
```

Call the endpoint again. The answer now ends with `mode=audit`. The JAR did not change; only the setting changed, which is the point of provider configuration.

## Showing settings in the admin console

A factory can also describe its settings to the administrator. If the factory implements `ServerInfoAwareProviderFactory`, its `getOperationalInfo()` method returns a map of text values, and the admin console shows them on the provider information page of the server. Return the active `mode` there, so an administrator can see the value without reading the pod's environment. Never return a password or a secret in that map.

You can now read a setting with a default and carry it from the factory to the code that uses it. The open question is how to switch a whole provider on or off, and how Keycloak chooses between two providers of the same SPI.

## Common pitfalls

> [!WARNING]
> - **Reading the setting with the full name.** The scope already holds only this provider's settings; use `mode`.
> - **Giving no default.** The provider fails in every environment that does not set the value.
> - **Reading the setting in `create`.** Read it once in `init` and keep it in a field.
> - **Showing a secret in `getOperationalInfo()`.** Every administrator can read that page.
