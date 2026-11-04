# Resources, Styles And Localisation

A branded login page needs a logo, a style sheet and text in the user's language. Keycloak serves static files from the theme and reads messages from message files. This part explains the folders of a theme, how to add a style sheet and an image, and how to add a second language.

## The folders of a login theme

A theme directory holds one folder per theme type. For the login theme, the layout is this:

```
inventory/
  login/
    theme.properties
    messages/
      messages_en.properties
      messages_da.properties
    resources/
      css/login.css
      img/logo.png
```

`theme.properties` holds the settings. `messages/` holds the text. Everything under `resources/` is served as static files. The templates, if you override any, are `.ftl` files directly in `login/`.

## Add a style sheet

The setting `styles` lists the style sheets that the page loads, separated by spaces, each relative to `resources/`. The parent theme's styles are inherited, so you add to them. Add the file to `theme.properties`:

```properties
parent=keycloak.v2
styles=css/login.css
```

Whether the page also loads the parent's styles depends on the parent theme. If your own style sheet does not take effect, check what the parent sets for `styles` and whether a CSS rule of the parent is more specific than yours. The `scripts` setting works the same way for JavaScript files.

## Use an image

A template reaches a static file through `url.resourcesPath`, which includes a version that changes when the server changes. Never write the path by hand:

```ftl
<img src="${url.resourcesPath}/img/logo.png" alt="${msg("logoAlt")}">
```

In a style sheet, use a path relative to the sheet, such as `url(../img/logo.png)`.

## Add a language

A message file is named `messages_<locale>.properties`. The text is a list of `key=value` lines. A value may contain `{0}`, `{1}` for arguments that `msg("key", arg)` fills in. A key that is missing in a language falls back to the parent theme's text in that language and then to English.

Two steps turn a second language on. First list the locales in the theme's `theme.properties`:

```properties
locales=en,da
```

Then enable internationalisation in the realm and set its languages:

<!-- astrona:playground:renew -->

```sh
kcadm update realms/inventory -s internationalizationEnabled=true -s 'supportedLocales=["en","da"]' -s defaultLocale=en
```

The login page now shows a language selector, and a user who picks Danish gets the keys from `messages_da.properties`. To read back the setting, run:

```sh
kcadm get realms/inventory --fields internationalizationEnabled,supportedLocales,defaultLocale
```

## Caching hides your change

Keycloak caches themes and static files. When a change does not appear, the cause is usually the cache or an old pod, not your file. In development mode, `start-dev` turns the theme cache off, but a ConfigMap change is not copied into a running pod at once. Restart Keycloak after a ConfigMap change, or wait for the volume to sync.

You now know the folders of a theme, how styles and images are served, and how a second language is added. The open question is how to package all of this in a JAR so one artifact carries both a theme and a provider.

## Common pitfalls

> [!WARNING]
> - **Hard-coding a path to an image.** Use `${url.resourcesPath}`, which includes the version.
> - **Writing `styles` relative to the wrong folder.** The path is relative to `resources/`.
> - **Adding a message file without `locales`.** The language selector does not list it.
> - **Enabling the language only in the theme.** The realm must turn internationalisation on and list the locales.
