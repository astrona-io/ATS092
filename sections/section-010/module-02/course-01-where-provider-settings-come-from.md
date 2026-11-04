# Where Provider Settings Come From

A provider that works the same everywhere is easy to write and hard to use. A test server needs a short timeout, a production server needs a long one, and a customer wants a different greeting. Keycloak solves this with provider configuration: values that an administrator sets outside the JAR and that the factory reads at start. This part shows where the values can be set and how a name in the setting maps to a provider.

## The name of a setting

Every setting has a name made of three parts: the SPI, the provider id and the setting key. The SPI name is the key under which `serverinfo` lists the SPI. For the endpoint of this module, `kcadm get serverinfo` lists the provider `inventory-status` under the SPI `realm-restapi-extension`. A setting called `mode` for that provider is therefore written like this on the command line:

```
--spi-realm-restapi-extension--inventory-status--mode=audit
```

The prefix is `--spi-`, and two dashes (`--`) separate the three parts. Dashes inside a part stay single dashes.

## Three places to set a value

Keycloak reads configuration from three sources and uses the first one that has a value, in this order:

1. A command-line argument, such as the one above, given to `kc.sh start`.
2. An environment variable. The name starts with `KC_SPI_`, uses upper case, writes every dash inside a part as an underscore, and writes the double dash between the parts as two underscores: `KC_SPI_REALM_RESTAPI_EXTENSION__INVENTORY_STATUS__MODE=audit`.
3. A line in the file `conf/keycloak.conf`, written without the leading dashes: `spi-realm-restapi-extension--inventory-status--mode=audit`.

The three forms name the same setting. A form that does not match this rule is not an error. Keycloak ignores a setting that no provider reads, and the provider then uses its default. This is the most common mistake with provider configuration, and the lab of this module is built around it.

## Find the SPI name

You do not have to guess the SPI name. In the playground, paste the helpers and list the SPIs that accept REST extensions:

<!-- astrona:playground:renew -->

```sh
kcadm get serverinfo | jq '.providers | keys | map(select(test("rest")))'
```

The list contains `realm-restapi-extension`. Then list its provider ids:

```sh
kcadm get serverinfo | jq '.providers["realm-restapi-extension"].providers | keys'
```

The SPI name and the provider id from these two commands go straight into the setting name. At the start of the playground the list of provider ids has no `inventory-status`, because the JAR is not built yet.

## Settings are read at start

The factory reads its settings in `init`, which runs once when the server starts. A changed value therefore needs a restart of Keycloak. A change to the environment of the pod is a change to the Deployment, and Kubernetes restarts the pod for you.

You now know how a setting is named and where it can be set. The open question is how the provider's code asks for the value.

## Common pitfalls

> [!WARNING]
> - **Writing the SPI name from memory.** Copy it from `serverinfo`.
> - **Using one underscore between the parts of an environment variable.** The parts are separated by two underscores.
> - **Expecting an error for a wrong name.** An unknown setting is ignored and the default stays.
> - **Changing a value and not restarting.** The factory reads it once, in `init`.
