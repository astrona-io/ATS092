# The Account Theme And Languages

A user opens the account console to change their profile, their password and their signed-in devices. That page also has a theme, and a realm can show it in more than one language. This part explains what the account theme can change, how to select it, and how a realm turns languages on.

## The account console is not a FreeMarker page

The login pages and the emails are FreeMarker templates that the server fills. The account console of current Keycloak versions is different: its theme `keycloak.v3` is a single-page application, a program that runs in the browser and loads its data from the server through the Admin and Account REST APIs. Its pages are not templates, so you cannot override a page by writing an `.ftl` file for it.

What an account theme can change is the text, the style and the resources. A theme with `parent=keycloak.v3` in `account/theme.properties` inherits the application. It adds `account/messages/messages_en.properties` to change text, and style sheets and images to change the look. The properties and the style settings that the application reads depend on the Keycloak version, so read the parent theme before you rely on one.

## Select the account theme

List the account themes that your Keycloak knows, then select one for the realm. The field is `accountTheme`:

<!-- astrona:playground:renew -->

```sh
kcadm get serverinfo | jq '.themes.account | map(.name)'
kcadm get realms/inventory --fields accountTheme
```

The first command lists names such as `keycloak.v3` and `base`. The second shows the realm's current account theme, which is not set in a new realm. A theme in a mounted directory has the same layout as an email theme, with the folder `account` in place of `email`. After the mount, select it with `kcadm update realms/inventory -s accountTheme=inventory`.

## Turn on languages

Languages are a realm setting, and every theme type reads it. Three fields control it: `internationalizationEnabled` turns the language choice on, `supportedLocales` lists the language codes, and `defaultLocale` is used when a user has not chosen one. Set English and Danish:

```sh
kcadm update realms/inventory \
  -s internationalizationEnabled=true \
  -s 'supportedLocales=["en","da"]' \
  -s defaultLocale=en
kcadm get realms/inventory --fields internationalizationEnabled,supportedLocales,defaultLocale
```

From now on, a login page shows a language choice. Keycloak picks the language of a page in this order: the choice of the user in this session, the `locale` attribute of the user, the language of the browser, and the realm's default.

## Add a language to a theme

Keycloak finds the messages of a language in a file named after the language code, such as `messages_da.properties`, in the `messages` folder of the theme type. An email theme with `email/messages/messages_da.properties` sends mails in Danish to a user whose locale is `da`. A key that the file does not contain falls back to the parent theme, which falls back to English. So a translation can start with only the keys you changed.

The realm can also keep message overrides in its own data, set in the admin console, without any theme file. That is quick for a few words. A theme file is better when the text must be reviewed, versioned and shipped with the rest of the code.

You now know that the account console is changed through messages, style and resources, how to select an account theme, and how a realm turns on languages. That closes the three theme types the module covers: login, email and account.

## Common pitfalls

> [!WARNING]
> - **Looking for `.ftl` files of the account console.** The application in `keycloak.v3` has no page templates to override.
> - **Setting `supportedLocales` without `internationalizationEnabled`.** The language choice does not appear.
> - **Forgetting `defaultLocale`.** A user without a choice gets a language you did not intend.
> - **Expecting a missing key to fail.** Keycloak falls back to the parent theme and then to English, so a gap shows up as English text.
