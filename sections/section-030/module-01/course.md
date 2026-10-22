# Send Keycloak Events To Your Own Listener

The security team wants one log line for every successful sign-in to the realm `inventory`, in a fixed format their tools can search for. Keycloak already records every sign-in as an event, but the built-in log listener writes successful sign-ins at a level the server does not print. You write a listener that does exactly what the team asks.

An **event** is a record of something that happened in a realm. A **user event**, such as `LOGIN` or `LOGIN_ERROR`, comes from what a user does. An **admin event**, such as creating a user, comes from a change made through the Admin REST API. An **event listener** is a provider that Keycloak calls for every event of the realms that turn it on. This module writes the listener `audit-log`, which writes lines that start with `AUDIT-LOG`.

Keep one sentence in mind: **a listener receives events only from realms that list it in their event configuration.** A loaded listener that no realm lists receives nothing.

The module has three parts. **User Events And Admin Events** reads the realm's event configuration and finds the events that `jboss-logging` writes to the server log. **Writing An Event Listener** writes the listener and its factory and builds them into Keycloak. **Enabling A Listener In A Realm** turns the listener on next to `jboss-logging`, proves it with a sign-in, and adds admin events. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Explain the difference between user events and admin events, and name common event types.
- Read and change a realm's event configuration with `kcadm.sh`.
- Explain which events `jboss-logging` writes, and at which log level.
- Write an `EventListenerProvider` with its two `onEvent()` methods, and its factory.
- Turn a listener on in a realm without removing `jboss-logging`.
- Turn admin events on and see an admin change in your listener.
- Prove a listener works with a real sign-in and the server log.

## Before you start

You need Kubernetes basics, `kubectl logs`, and the `kcadm` habits of this course. You should be able to read short Java classes. You do not need Java or Maven on your machine: every build runs in a Job inside the cluster.

Your playground is a single-node `kind` cluster in the namespace **`events-demo`**:

| Workload | What it is |
| --- | --- |
| `keycloak` | Keycloak 26.8.1 in development mode, with the lab-only administrator `admin` / `admin`. It reads provider JARs from the PVC `keycloak-providers`, which is empty at the start |
| realm `inventory` | The user `alice` (password `alice-password`) and the public client `inventory-cli` with direct access grants on |
| `maven-cache`, `build-provider-job` | The Maven cache, already filled, and the build Job's definition |
| `tester` | A client pod with `curl` and `jq` |

The pages sign `alice` in with the password grant through `inventory-cli`, because that works from a terminal and produces a real `LOGIN` event. OAuth 2.1 drops the password grant, and a real application uses the authorization code flow. Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
