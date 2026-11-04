# Summary

A provider receives its settings from Keycloak as a `Config.Scope` in the factory's `init` method. A setting is named by the SPI, the provider id and the key. On the command line the three parts follow `--spi-` and are separated by two dashes. In an environment variable the name starts with `KC_SPI_`, is in upper case, and uses two underscores between the parts. In `keycloak.conf` the line is the command-line form without the leading dashes.

Keycloak reads the command line first, then the environment, then the file. A name that matches no provider is ignored without an error, so the provider quietly keeps its default. The SPI name and the provider id come from `serverinfo`. The factory reads the values once, in `init`, so a change needs a restart.

Every provider accepts `enabled=false`, which keeps its JAR loaded but removes the factory from use. For an SPI with one active provider, the setting `provider` names the default, and without it Keycloak takes the factory with the highest `order()`. In Kubernetes the values come from the Deployment's environment, from a ConfigMap or Secret, or from a mounted `keycloak.conf`. The key facts to remember are these:

- Copy the SPI name and the provider id from `serverinfo`.
- Two underscores separate the parts of an environment variable.
- A misspelled setting is ignored, not rejected.
- Secrets come from a Secret, never from a plain value.

<!-- astrona:playground:destroy -->
