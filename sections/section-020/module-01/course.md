# Add A Custom Step To An Authentication Flow

The client `inventory-cli` lets every user of the realm `inventory` sign in. The team wants one more rule: a user may sign in to this client only if their user attribute `department` has a value. Keycloak has no built-in step for that. You write one.

An **authentication flow** is an ordered list of steps that Keycloak runs to sign a user in. Each step is an **execution**, and each execution runs one **authenticator**, the Java code that checks one thing. Every execution has a **requirement**, which decides whether its result counts. This module writes the authenticator `require-department-attribute` and adds it to the flow that `inventory-cli` uses.

Keep one sentence in mind: **an authenticator does nothing until an execution in a flow uses it, and the flow does nothing until something binds it.** Code, flow and binding are three separate places, and each one can be wrong.

The module has three parts. **Authentication Flows, Executions And Requirements** reads the realm's flows and the executions of the direct grant flow with `kcadm.sh`. **Writing An Authenticator And Its Factory** writes the Java code, with requirement choices and a configuration property, and builds it into Keycloak. **Wiring An Authenticator Into A Flow** copies the direct grant flow, adds the new step, binds the copy to `inventory-cli` and proves the rule with two users. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Explain what an authentication flow, an execution, an authenticator and a requirement are.
- List a realm's flows, the flows it binds, and the executions of one flow with `kcadm.sh`.
- Write an `Authenticator` that calls `success()` or `failure()` on the `AuthenticationFlowContext`.
- Write an `AuthenticatorFactory` with a provider id, requirement choices and a configuration property.
- Copy a built-in flow, add an execution and set its requirement.
- Bind a flow to one client with a flow override.
- Prove the rule with one token issued and one refused.

## Before you start

You need Kubernetes basics and the `kcadm` habits of this course: the Admin REST API, realms, users and clients. You should be able to read short Java classes. You do not need Java or Maven on your machine: every build runs in a Job inside the cluster.

Your playground is a single-node `kind` cluster in the namespace **`authenticator-demo`**:

| Workload | What it is |
| --- | --- |
| `keycloak` | Keycloak 26.8.1 in development mode, with the lab-only administrator `admin` / `admin`. It reads provider JARs from the PVC `keycloak-providers`, which is empty at the start |
| realm `inventory` | The users `alice` (attribute `department` = `warehouse`) and `bob` (no `department`), both with a complete profile, and the public client `inventory-cli` with direct access grants on |
| `maven-cache`, `build-provider-job` | The Maven cache, already filled, and the build Job's definition |
| `tester` | A client pod with `curl` and `jq` |

The pages sign users in with the password grant (`grant_type=password`) through `inventory-cli`, because that works from a terminal. OAuth 2.1 drops the password grant, and a real application uses the authorization code flow in a browser. Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
