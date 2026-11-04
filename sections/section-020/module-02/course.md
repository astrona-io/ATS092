# Add A Required Action To The Sign-In

Many realms must make users do something once: accept new terms, confirm a phone number, read a notice. Keycloak shows such a step after the user signed in, as a required action. The built-in actions cover the common cases, and a custom required action covers the rest.

A **required action** is a step that Keycloak shows to a signed-in user until the user completes it. This module builds the action `accept-terms` as a provider, loads it, registers it in the realm `inventory` and assigns it to a user.

Keep one sentence in mind: **a required action needs four steps before it runs: load it, register it, enable it and put it on a user.** If one step is missing, the user signs in without ever seeing the action.

The module has four parts. **What A Required Action Is** reads the built-in actions and the list on a user. **Writing A Required Action Provider** writes the provider, its factory and the services file. **Registering And Assigning A Required Action** registers, enables and assigns it. **Triggers, Forms And Completing An Action** adds an action by condition and shows a form. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Explain what a required action is and how it differs from an authenticator.
- List the required actions of a realm and set them on a user with `kcadm.sh`.
- Write a `RequiredActionProvider` and a `RequiredActionFactory`.
- Register, enable and assign a custom required action.
- Add an action from `evaluateTriggers` and finish it with `success()`.
- Find out why a required action does not run.

## Before you start

You need the basics of providers and factories and the build helpers of this course. You do not need Java or Maven on your machine.

Your playground is a single-node `kind` cluster in the namespace **`actions-demo`**:

| Workload | What it is |
| --- | --- |
| `keycloak` | Keycloak 26.8.1 in development mode, with the realm `inventory`, the users `alice` and `bob` and the lab-only administrator `admin` / `admin`. The providers directory is empty at the start |
| `maven-cache`, `build-provider-job` | The Maven cache, already filled, and the build Job's definition |
| `tester` | A client pod with `curl` and `jq` |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
