# Build And Load Your First Keycloak Provider

Every feature you add to Keycloak with your own code starts the same way. You write two Java classes, a provider and its factory, and you register the factory in a small text file. You build a JAR, put it in Keycloak's providers directory, and restart the server. If any step is wrong, Keycloak does not complain: your feature is simply not there.

A Service Provider Interface (SPI) is a Java interface that Keycloak defines for one kind of extension. A **provider** is one implementation of an SPI, and a **provider factory** is the class Keycloak loads at start to create providers. This module builds the smallest useful provider there is: an HTTP endpoint that answers `inventory-status ok realm=inventory` when you call `/realms/inventory/inventory-status`.

Keep one sentence in mind: **Keycloak finds a factory only through `META-INF/services`, and only when it starts.** A class that is not listed there does not exist for Keycloak, and a new JAR does nothing until the next start.

The module has three parts. **What A Service Provider Interface Is** looks at the SPIs and providers a running Keycloak already has, and explains how a factory, a provider and a `KeycloakSession` work together. **Writing A Provider And Its Factory** writes the endpoint, its factory and the services file, and builds them into a JAR inside the cluster. **Loading Providers Into Keycloak** proves that Keycloak loaded the JAR, explains what happens at start, and shows how production images do the same with `kc.sh build`. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Explain what an SPI, a provider, a provider factory and a `KeycloakSession` are.
- List the SPIs and providers of a running Keycloak with `kcadm.sh get serverinfo`.
- Write a realm resource provider with its factory and resource class.
- Register a factory in `META-INF/services` with the right file name.
- Build a provider JAR with Maven inside the cluster and load it into Keycloak.
- Tell a silent registration mistake from a start failure, and prove a provider is loaded.
- Explain how `kc.sh build` and `start --optimized` load providers in production.

## Before you start

You need Kubernetes basics: namespaces, Deployments, ConfigMaps, Jobs, `kubectl logs` and `kubectl exec`. You should be able to read short Java classes; you do not need to write Java from memory. You do not need Java or Maven on your machine: every build runs in a Job inside the cluster.

Your playground is a single-node `kind` cluster in the namespace **`spi-demo`**:

| Workload | What it is |
| --- | --- |
| `keycloak` | Keycloak 26.8.1 in development mode (`start-dev`), with the realm `inventory` and the lab-only administrator `admin` / `admin`. It reads provider JARs from the PVC `keycloak-providers`, which is empty at the start |
| `maven-cache` | A PVC that keeps Maven's downloads between builds. The playground fills it when it starts |
| `build-provider-job` | A ConfigMap that holds the definition of the build Job |
| `tester` | A client pod with `curl` and `jq`. Every test request in this module is sent from here |

The first build downloads from Maven Central, so the cluster needs outbound internet. Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
