# Section 010: Service Provider Interfaces

Keycloak is built from many small parts. Each way to sign a user in, each place an event can go, and each kind of HTTP endpoint is a separate piece of Java code. Keycloak loads all of them the same way, through Service Provider Interfaces (SPIs). An SPI is a Java interface that Keycloak defines for one kind of extension, and your own code plugs into the server by implementing it.

This section comes first because everything else in the course depends on it. A custom authenticator, an event listener and a theme packed in a JAR all follow the same steps: write a provider and its factory, register the factory, build a JAR, put it in the providers directory, and restart Keycloak. When one of those steps goes wrong, the symptoms are quiet and easy to misread, so you also learn to prove that Keycloak really loaded your code.

## What you will learn

- What an SPI, a provider and a provider factory are, and how `KeycloakSession` connects them.
- How to list every SPI and provider a running Keycloak knows, with `kcadm.sh get serverinfo`.
- How to write a realm resource provider: a small HTTP endpoint under `/realms/<realm>/<provider id>`.
- How the file `META-INF/services/<factory interface>` registers a factory, and what happens when it is wrong.
- How to build a provider JAR inside the cluster with Maven, without Java on your machine.
- How Keycloak loads JARs from `/opt/keycloak/providers`, in development mode and with `kc.sh build`.

## The learning path

Work through the module in order. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground, a cluster where you can explore freely.

### 1. Build And Load Your First Keycloak Provider

The playground runs Keycloak 26.8.1 in the namespace `spi-demo`, with an empty providers directory and the build setup ready to use.

1. What A Service Provider Interface Is
2. Writing A Provider And Its Factory
3. Loading Providers Into Keycloak, followed by the lab **Make Keycloak Load A Provider**
4. Summary

## Section capstone: Get A Broken Provider Build Running

The capstone is one graded scenario that combines the whole section. A colleague wrote the `inventory-status` provider, but the build fails, and the next mistake waits behind the first one: once the code compiles, Keycloak itself stops starting. You must find both faults from the logs and get the endpoint answering. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS092.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-092-capstone-010
```
