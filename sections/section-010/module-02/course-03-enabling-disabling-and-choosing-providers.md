# Enabling, Disabling And Choosing Providers

When two providers of one SPI are present, Keycloak must pick one. An administrator also needs a way to switch a provider off without deleting its JAR. This part explains the `enabled` setting, the `provider` setting that sets the default and the order of the factories.

## Switch a provider off

Every provider accepts the setting `enabled`. With the value `false`, Keycloak does not use the factory, even though its JAR is loaded. For the endpoint of this module:

```
--spi-realm-restapi-extension--inventory-status--enabled=false
```

As an environment variable it is `KC_SPI_REALM_RESTAPI_EXTENSION__INVENTORY_STATUS__ENABLED=false`. After a restart, the provider id is no longer in the list of the SPI in `serverinfo`, and the endpoint answers `404`. Remove the setting, or set it to `true`, and restart to bring the provider back. Use this when you must remove a feature fast and want the JAR to stay in place.

## Choose the default provider

Some SPIs are used with one provider at a time, for example the SPI that stores credentials or the one that sends email. If several factories of the SPI exist, Keycloak chooses the default in this way:

1. If the administrator set `--spi-<spi>--provider=<id>`, Keycloak uses that provider.
2. Otherwise, if one factory exists, Keycloak uses it.
3. Otherwise Keycloak uses the factory whose `order()` method returns the highest number.

`order()` is a method of `ProviderFactory` that returns `0` unless you override it. A custom provider that should replace a built-in one can return a higher number. An explicit `provider` setting is clearer, because it shows the choice in the configuration instead of in the code. For an SPI where all providers are used at the same time, such as event listeners, there is no default: a realm lists the ids it wants.

## Providers that are not always available

A factory can also decide for itself whether it is available. It implements `EnvironmentDependentProviderFactory` and returns false from `isSupported(Config.Scope config)`. Keycloak then skips it, as if it were disabled. This is used for providers that need a profile feature or a library that is not always present. Use `enabled` for an administrator's choice and `isSupported` for a technical condition.

## Check the result

Whatever you set, confirm it in the server info and not only in the configuration. In the playground, list the providers of the SPI:

<!-- astrona:playground:renew -->

```sh
kcadm get serverinfo | jq '.providers["realm-restapi-extension"].providers | keys'
```

Set `enabled=false` with `kubectl set env`, wait for the rollout, and run the command again. The id `inventory-status` is gone from the list. Remove the variable to bring it back:

```sh
kubectl -n config-demo set env deploy/keycloak KC_SPI_REALM_RESTAPI_EXTENSION__INVENTORY_STATUS__ENABLED=false
kubectl -n config-demo rollout status deploy/keycloak
kubectl -n config-demo set env deploy/keycloak KC_SPI_REALM_RESTAPI_EXTENSION__INVENTORY_STATUS__ENABLED-
```

A trailing dash after the name of a variable removes it. Wait for the second rollout before you test again.

You now know how to disable a provider, how to choose between providers and what `order()` does. The open question is how to deliver all these settings to a Kubernetes pod in a clean way.

## Common pitfalls

> [!WARNING]
> - **Deleting the JAR to disable a provider.** Set `enabled=false`; it is reversible and keeps the files.
> - **Relying on `order()` when two providers compete.** Set `provider` explicitly.
> - **Setting `provider` to an id that does not exist.** The SPI then has no default and fails at the first use.
> - **Checking only the configuration.** Confirm the result in `serverinfo`.
