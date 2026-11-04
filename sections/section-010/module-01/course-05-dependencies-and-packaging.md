# Dependencies And Packaging A Provider JAR

A provider JAR must contain the classes that Keycloak does not have and must leave out the classes that Keycloak already has. If the JAR gets this wrong, the provider fails with a `ClassNotFoundException` at runtime, or it fights with a different version of a library that Keycloak uses. This part explains the Maven dependency scopes, what goes into the JAR and how to check it.

## Provided and compile scope

The Keycloak classes your code imports, such as `org.keycloak.models.KeycloakSession`, exist inside the running server. In the `pom.xml` you declare them with `<scope>provided</scope>`. Maven then puts them on the compile classpath but does not pack them into the JAR. The same applies to JBoss Logging and the Jakarta REST API (`jakarta.ws.rs`), which Keycloak also ships.

A library that Keycloak does not ship, for example a client for an outside service, must be inside your JAR or next to it. A dependency with the default scope `compile` is not packed automatically. A normal Maven JAR contains only the classes of your own project. There are two ways to include a library:

- **A shaded JAR.** The Maven Shade plugin copies the classes of the `compile` dependencies into your JAR.
- **A second JAR in the providers directory.** Keycloak puts every JAR of `/opt/keycloak/providers` on the classpath of the server, so a dependency JAR placed next to your provider JAR is found.

Prefer a small dependency list. Every library you add can clash with a library that Keycloak already loaded.

## Java and Keycloak versions

Keycloak 26.8.1 runs on Java 21. A provider compiled with a newer Java release than the server runs fails to load with an `UnsupportedClassVersionError`. The `pom.xml` of this course sets `maven.compiler.release` to 17, which Java 21 can run. The artifact version of the Keycloak dependencies, `keycloak.version`, should equal the server's version. Internal Keycloak classes can change between versions, so rebuild a provider against every new server version you use.

## Check what is in the JAR

The build Job writes the JAR to the providers volume. To see what the JAR contains, list it from a container that has a JDK. The `jar` tool lists the files of an archive:

<!-- astrona:playground:renew -->

```sh
jar tf inventory-status-1.0.0.jar
```

The list must contain your classes, and the file `META-INF/services/org.keycloak.services.resource.RealmResourceProviderFactory` for the provider of this module. It must not contain `org/keycloak/` classes of Keycloak itself, because those belong to the server.

To see which libraries Maven resolved, and with which scope, run this in the project folder inside a build container:

```sh
mvn dependency:tree
```

Each line shows a dependency and its scope. The Keycloak artifacts show `provided`.

## What happens when two JARs define the same provider

If two JARs in the providers directory register a factory with the same provider id for the same SPI, Keycloak keeps one of them and logs a warning that two providers have the same id. Which one wins is not something your code should depend on. Give each provider a unique id, and remove the old JAR from the directory when you replace it. Delete the old file; do not only add a new JAR next to it.

## Dependencies in the production image

A production image copies every JAR into `/opt/keycloak/providers` and runs `kc.sh build`. Dependency JARs follow the same path. A change to any JAR means a new image.

You can now decide which dependencies belong in the JAR, which belong to the server, and how to check the result. The open question is how a provider receives settings so one JAR can behave differently in two environments.

## Common pitfalls

> [!WARNING]
> - **Packing Keycloak classes into the JAR.** Use `provided` for everything the server ships.
> - **Forgetting a runtime dependency.** The build works, and the provider fails with `ClassNotFoundException` at the first request.
> - **Compiling for a newer Java than the server.** The class version error appears when Keycloak starts.
> - **Leaving the old JAR in the directory.** Two JARs with the same provider id give an undefined winner.
