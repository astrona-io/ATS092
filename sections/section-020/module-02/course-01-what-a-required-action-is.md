# What A Required Action Is

Some things must happen after a user proves who they are, and before Keycloak lets them in: set a new password, verify an email address, accept the terms of use. Keycloak calls these steps required actions. This part explains what a required action is, how a user gets one and what the built-in ones are.

## A required action runs after authentication

A **required action** is a step that Keycloak shows a user after the authentication flow succeeds. The user is already known. Keycloak looks at the list `requiredActions` of the user, and for each action in the list it shows the matching page. The sign-in finishes only when the list is empty. This differs from an authenticator, which decides whether the user may pass at all. A required action never decides who the user is; it asks the user to do or accept something.

The built-in actions have uppercase aliases. The most used are `VERIFY_EMAIL`, `UPDATE_PASSWORD`, `UPDATE_PROFILE`, `CONFIGURE_TOTP` and `TERMS_AND_CONDITIONS`. List the actions of the realm `inventory` in the playground:

<!-- astrona:playground:renew -->

```sh
kcadm get authentication/required-actions -r inventory --fields alias,name,enabled,defaultAction
```

Each entry has an `alias`, a display `name`, a flag `enabled` and a flag `defaultAction`. The entry `TERMS_AND_CONDITIONS` is present but disabled in a new realm.

## How a user gets a required action

Three things can put an action on a user. An administrator can set it on the user. A flow or a provider can add it while the user signs in, for example Keycloak adds `VERIFY_EMAIL` when the realm needs verified addresses and the address is not verified. And an action marked as a **default action** is added to every new user of the realm. Set one on the user `alice` with `kcadm`:

```sh
kcadm get users -r inventory -q username=alice --fields id
```

Copy the id and run:

```sh
kcadm update users/<USER_ID> -r inventory -s 'requiredActions=["UPDATE_PASSWORD"]'
```

The next sign-in of `alice` through a browser shows the page to change the password. Keycloak removes the action from the list when the user finishes it.

## Required actions and the password grant

A required action needs a page, so it needs a browser. A client that signs in with the password grant cannot show it. If the user still has a required action, Keycloak refuses the token request with the error `invalid_grant` and the description `Account is not fully set up`. Remember this when you test: use the Admin REST API to check the user's list, not the password grant.

You now know that a required action is a step after sign-in, how a user gets one and why the password grant cannot complete it. The open question is how to write your own.

## Common pitfalls

> [!WARNING]
> - **Mixing up an authenticator and a required action.** An authenticator decides who may pass; a required action asks a known user for something.
> - **Testing with the password grant.** A user with a required action cannot get a token that way.
> - **Using lower case for a built-in alias.** The aliases are upper case, such as `UPDATE_PASSWORD`.
> - **Leaving a default action on by accident.** It is added to every new user.
