# FreeMarker Templates

A theme that only changes messages and colours soon reaches its limit. To change what a page contains, you override its template. Keycloak's templates are written in FreeMarker, a template language that fills a page with values from the server. This part explains the FreeMarker syntax you will meet, the template layout of a login page and the objects a template can use.

## FreeMarker in four constructs

A template is HTML with directives. These four cover most of what a login theme needs:

- `${expression}` prints a value, for example `${realm.name}`.
- `<#if condition> ... <#elseif> ... <#else> ... </#if>` shows a block only when the condition is true.
- `<#list items as item> ... </#list>` repeats a block for each item.
- `<#import "template.ftl" as layout>` and `<@layout.registrationLayout ...>` import a template and call a macro of it.

A value that may be missing needs a default, because FreeMarker stops with an error when a value is missing. The operator `!` gives the default: `${realm.displayName!realm.name}` prints the display name, or the realm name when there is none. `${value!""}` prints an empty string.

## The layout macro

Every login page of the `keycloak` theme imports `template.ftl` and calls the macro `registrationLayout`. The macro draws the frame of the page, and the page fills named sections. The sections that matter are `header` (the title), `form` (the main content), `info` (the text under the form) and `socialProviders`.

```ftl
<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=true; section>
    <#if section = "header">
        ${msg("loginAccountTitle")}
    <#elseif section = "form">
        <p>${msg("loginSupportText")}</p>
    </#if>
</@layout.registrationLayout>
```

The text after the semicolon, `section`, is the name the macro uses for the section it is currently drawing. The `<#if section = ...>` lines choose what to print in each one. When you override a template, copy the one of the parent theme and change only what you need. Which templates exist depends on the parent theme; the file `login.ftl` is the sign-in page and `register.ftl` is the registration page.

## The objects in a login template

Keycloak gives every template a set of objects. Common ones are:

- `realm`: the realm, with `realm.name`, `realm.displayName` and flags such as `realm.registrationAllowed`.
- `url`: the addresses for the page, such as `url.loginAction` (where a form must post), `url.registrationUrl` and `url.resourcesPath` (where the theme's static files are).
- `message`: the message to show, with `message.summary` and `message.type`.
- `messagesPerField`: errors per form field, used as `messagesPerField.existsError('username')`.
- `msg("key")`: a function that returns the text for a message key in the user's language.
- `properties`: the values of `theme.properties`.

Any attribute that a custom authenticator sets with `setAttribute` is available in its own template under that name.

## Find the parent's template

To override a template, you need its source. The Keycloak container has the base themes inside its JAR files in `/opt/keycloak/lib/lib/main`. In the playground, list the JAR files whose name contains `theme`:

<!-- astrona:playground:renew -->

```sh
kubectl -n themes-demo exec deploy/keycloak -- sh -c 'ls /opt/keycloak/lib/lib/main | grep -i theme'
```

The listing shows the JAR files that hold the built-in themes. Copy one out with `kubectl cp` and open it as an archive on your machine to read `login.ftl` and `template.ftl`. The exact file names and the layout inside a base theme change between Keycloak versions, so always read the templates of the version you run.

You now know the syntax of a template, how a login page is built from a macro and sections, and which objects it can use. The open question is where the style sheets, scripts and translations of a theme live.

## Common pitfalls

> [!WARNING]
> - **Printing a value that can be missing.** Add a default with `!`, or the page ends with an error.
> - **Copying a template from another Keycloak version.** The macros and objects can differ; copy from the version you run.
> - **Forgetting the section structure.** Content outside the `<#if section = ...>` blocks is not drawn.
> - **Hard-coding text in the template.** Use `msg("key")` so the text can be translated.
