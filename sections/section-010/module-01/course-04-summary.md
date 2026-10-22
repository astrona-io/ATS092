# Summary

Keycloak is built from providers of Service Provider Interfaces (SPIs). An SPI is a Java interface for one kind of extension, a provider is one implementation of it, and a provider factory is the class Keycloak loads at start to create providers. The factory lives as long as the server; Keycloak calls its `init()` and `postInit()` once and its `create()` for each request, passing a `KeycloakSession`. The provider lives for one request, keeps that session, and is closed at the end.

Keycloak finds a factory only through Java's `ServiceLoader`, which reads files in `META-INF/services/` inside the JAR. The file is named after the factory interface, and each line names one factory class. A file with the wrong name is never opened, so the provider is missing without any message. A file that names a class that does not exist makes the build at start fail, and the pod restarts again and again.

A provider is a small Maven project. The Keycloak artifacts use the scope `provided`, so Maven compiles against them without packing them into the JAR, and their version must match the server. A realm resource provider adds an HTTP endpoint under `/realms/<realm>/<provider id>`; its resource class needs the `@Provider` annotation, and the JAR needs an empty `META-INF/beans.xml`.

Keycloak reads the providers directory only during its build. `start-dev` and a plain `start` build on every start, so a restart loads a new JAR. A production image runs `kc.sh build` once with the JAR inside and starts with `--optimized`. The key facts to remember are these:

- `kcadm get serverinfo` lists every SPI and provider Keycloak loaded.
- The services file is named after the factory interface, not the provider interface.
- A missing provider with a clean log points at the services file name; a crash loop points at a class name.
- Prove a provider three ways: the JAR is in the directory, the server info lists it, and its behaviour works.

<!-- astrona:playground:destroy -->
