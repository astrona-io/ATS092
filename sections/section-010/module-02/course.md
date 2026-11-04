# Configure A Provider Without Rebuilding It

One JAR is often used in several places: a test cluster, a staging cluster and production. The code is the same, but a few values differ. Keycloak lets an administrator set those values outside the JAR, as provider configuration, so a change needs a restart and not a new build.

A provider setting is a named value that Keycloak passes to the provider factory when the server starts. This module changes the endpoint `inventory-status` so that it reports a `mode` from a setting, and then uses the setting in the three places Keycloak reads: the command line, environment variables and `keycloak.conf`.

Keep one sentence in mind: **a misspelled setting is not an error; the provider silently keeps its default.** The only proof that a setting works is the behaviour of the provider.

The module has four parts. **Where Provider Settings Come From** explains the name of a setting and the three sources. **Reading Settings In A Factory** reads a setting with `Config.Scope` and shows it in the endpoint. **Enabling, Disabling And Choosing Providers** covers `enabled`, `provider` and `order()`. **Supplying Settings In Kubernetes** delivers settings to the pod. A graded lab follows the fourth part.

## Learning objectives

After this module you can:

- Write the name of a provider setting for the command line, the environment and `keycloak.conf`.
- Read a setting in a factory with `Config.Scope` and a default.
- Switch a provider off with `enabled=false` and choose a default with `provider`.
- Explain what `order()` does.
- Deliver settings to a Keycloak pod from a Deployment, a ConfigMap, a Secret or a mounted file.
- Find out why a provider ignores a setting.

## Before you start

You need the basics of providers, factories and the build helpers of this course. You do not need Java or Maven on your machine.

Your playground is a single-node `kind` cluster in the namespace **`config-demo`**:

| Workload | What it is |
| --- | --- |
| `keycloak` | Keycloak 26.8.1 in development mode, with the realm `inventory` and the lab-only administrator `admin` / `admin`. The providers directory is empty at the start |
| `maven-cache`, `build-provider-job` | The Maven cache, already filled, and the build Job's definition |
| `tester` | A client pod with `curl` and `jq` |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
