# Authenticator Configuration

A hard-coded rule such as "the department must be `warehouse`" needs a new JAR every time it changes. Keycloak can store settings for a step in the realm, so an administrator changes the rule in the admin console or through the Admin REST API. This part explains how a factory declares its settings, how the authenticator reads them and how a configuration is attached to a step.

## The factory declares the settings

Only a factory that implements `ConfigurableAuthenticatorFactory` can have settings. It adds these methods to `AuthenticatorFactory`: `isConfigurable()` returns true, and `getConfigProperties()` returns the list of settings as `ProviderConfigProperty` objects. The helper `ProviderConfigurationBuilder` builds the list:

```java
private static final List<ProviderConfigProperty> CONFIG = ProviderConfigurationBuilder.create()
        .property()
            .name("requiredDepartment")
            .label("Required department")
            .helpText("Only users with this department value may continue.")
            .type(ProviderConfigProperty.STRING_TYPE)
            .defaultValue("warehouse")
            .add()
        .build();

@Override
public List<ProviderConfigProperty> getConfigProperties() {
    return CONFIG;
}
```

The `type` is one of constants such as `STRING_TYPE`, `BOOLEAN_TYPE`, `LIST_TYPE` and `PASSWORD`. The `name` is the key the authenticator reads and the key in the stored configuration.

The factory also decides which requirements the administrator can choose. `getRequirementChoices()` returns an array of `AuthenticationExecutionModel.Requirement` values, such as `REQUIRED`, `ALTERNATIVE` and `DISABLED`. If your step only makes sense as a required step, return only `REQUIRED` and `DISABLED`.

## The authenticator reads the values

The context holds the configuration of the execution that is running. It is `null` when the administrator saved none, so the code must handle that:

```java
AuthenticatorConfigModel configModel = context.getAuthenticatorConfig();
String department = "warehouse";
if (configModel != null && configModel.getConfig() != null) {
    department = configModel.getConfig().getOrDefault("requiredDepartment", department);
}
```

The same execution has one configuration at a time. Two copies of the step in the same flow have two separate configurations, and two flows do not share them.

## Attach a configuration to a step

An execution is one step in a flow, and each has an id. List the executions of a flow, then create the configuration for the one you want. In the playground, run these after you paste the helpers:

<!-- astrona:playground:renew -->

```sh
kcadm get authentication/flows/direct-grant-department/executions -r inventory
```

The answer is a list of executions with their `id`, `displayName`, `requirement` and, for a configurable step, `configurable: true`. Copy the id of your step. Save this as `department-config.json`:

```json
{
  "alias": "department-rule",
  "config": {
    "requiredDepartment": "warehouse"
  }
}
```

Send it to the Admin REST API with `kcadm`, replacing `<EXECUTION_ID>` with the id you copied:

```sh
kcadm create authentication/executions/<EXECUTION_ID>/config -r inventory -f department-config.json
```

The `alias` is the name the administrator sees. Reading the stored values later needs the configuration id that the execution lists in `authenticationConfig`:

```sh
kcadm get authentication/config/<CONFIG_ID> -r inventory
```

To change the rule, update the same configuration with `kcadm update authentication/config/<CONFIG_ID>`; no new JAR and no restart are needed, because the authenticator reads the configuration on each run.

You now know how a step gets settings: declare them in the factory, read them from the context and attach a configuration to the execution. The open question is how to prove that the rule you configured is the one that runs.

## Common pitfalls

> [!WARNING]
> - **Reading the configuration without a `null` check.** A step with no saved configuration returns `null`.
> - **Changing the property `name` after a configuration was saved.** The stored key stays, and the authenticator no longer reads it.
> - **Leaving `isConfigurable()` at false.** The admin console shows no settings gear.
> - **Offering every requirement choice.** A step that only works when required should not allow `ALTERNATIVE`.
