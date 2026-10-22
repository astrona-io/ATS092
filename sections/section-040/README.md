# Section 040: Themes With FreeMarker

Every page Keycloak shows to a user, from the login form to the account console and the emails it sends, comes from a theme. A theme is a set of templates, message files and static files such as CSS and images. Keycloak ships its own themes, and you change what users see by writing a theme of your own that inherits from one of them and overrides only what you need.

This section teaches the parts of a theme that matter in practice: the theme types, how inheritance through `parent` works, how FreeMarker templates print messages, and the two ways to deliver a theme to Keycloak. A mounted directory is quick to change; a JAR is how a theme ships next to providers in a real image.

## What you will learn

- The theme types (`login`, `account`, `email`, `admin`, `welcome`) and which pages each one styles.
- How `theme.properties` and `parent=` let a theme override a few files and inherit the rest.
- How a FreeMarker template prints a message with `${msg("key")}`, and why overriding a message beats copying a template.
- How to deliver a theme as a directory under `/opt/keycloak/themes`, mounted from a ConfigMap.
- How to pack a theme in a JAR with `META-INF/keycloak-themes.json`, next to providers.
- How to select a theme for a realm and prove it with the login page.

## The learning path

Work through the module in order. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground.

### 1. Change The Login Page With A Theme

The playground runs Keycloak 26.8.1 in the namespace `themes-demo`, with the realm `inventory` and the public client `inventory-web`, which the pages use to fetch the realm's login page.

1. Theme Types And How Keycloak Finds A Theme
2. A Theme In A Mounted Directory, followed by the lab **Brand The Login Page With A Mounted Theme**
3. Packaging A Theme In A JAR
4. Summary

## Section capstone: Ship A Theme And A Listener In One JAR

The capstone combines the whole section with what a JAR can hold. One JAR should deliver both the `inventory` login theme and the `audit-log` event listener. It builds and Keycloak starts, but the login page looks like Keycloak's default and no sign-in is audited. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS092.git -c sections/section-040/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-092-capstone-040
```
