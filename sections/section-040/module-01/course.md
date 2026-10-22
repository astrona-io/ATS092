# Change The Login Page With A Theme

The `inventory` team wants its own heading on the login page of the realm `inventory`: "Sign in to Inventory" instead of Keycloak's generic text. The heading is one message in one template of one theme. You change it by writing a small theme that inherits everything else.

A **theme** is a set of FreeMarker templates, message files and static files that Keycloak uses to render pages. FreeMarker is the template language of Keycloak's pages; a template prints a message with `${msg("key")}`, and the theme's message files map each key to text. A theme has a **type**, such as `login`, and a file `theme.properties` whose `parent=` names the theme it inherits from. This module writes the login theme `inventory`, first as a directory mounted from a ConfigMap, then as a theme inside a JAR.

Keep one sentence in mind: **override the smallest thing that does the job.** One message in a message file survives Keycloak upgrades; a copied template has to be compared with the new version on every upgrade.

The module has three parts. **Theme Types And How Keycloak Finds A Theme** lists the themes Keycloak has, explains `parent` and the lookup order, and reads the current heading from the login page. **A Theme In A Mounted Directory** writes the theme, mounts it from a ConfigMap and selects it for the realm. **Packaging A Theme In A JAR** puts a theme in a JAR with `META-INF/keycloak-themes.json`, the way it ships next to providers. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Name the theme types and the built-in themes, and explain inheritance through `parent`.
- Explain how a FreeMarker template prints a message, and override one message.
- Create a login theme as a directory and mount it into the Keycloak pod from a ConfigMap.
- Select a login theme for a realm with `kcadm.sh`.
- Pack a theme in a JAR with `META-INF/keycloak-themes.json` and load it.
- Prove a theme works with the login page served to the `tester` pod.

## Before you start

You need Kubernetes basics: ConfigMaps, Deployments, volumes and `kubectl apply`. You need the `kcadm` habits of this course. HTML knowledge helps but is not required. You do not need Java or Maven on your machine.

Your playground is a single-node `kind` cluster in the namespace **`themes-demo`**:

| Workload | What it is |
| --- | --- |
| `keycloak` | Keycloak 26.8.1 in development mode, with the lab-only administrator `admin` / `admin`. In development mode Keycloak does not cache themes and templates |
| realm `inventory` | The user `alice` and the public client `inventory-web`, which uses the authorization code flow with the redirect URI `http://localhost/*`. The pages use it only to fetch the realm's login page |
| `keycloak-providers`, `maven-cache`, `build-provider-job` | The build setup, used in the last part |
| `tester` | A client pod with `curl` and `jq` |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
