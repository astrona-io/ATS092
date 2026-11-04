# Summary

A required action is a step that Keycloak shows to a known user after the authentication flow succeeds. The user's list `requiredActions` holds the aliases, and a sign-in finishes only when the list is empty. Built-in actions have upper-case aliases such as `UPDATE_PASSWORD` and `VERIFY_EMAIL`. An administrator, a flow or a provider can put an action on a user, and an action marked as a default action goes to every new user. A client that uses the password grant cannot show the page, so it receives the error `invalid_grant`.

A custom action has a provider that implements `RequiredActionProvider` and a factory that implements `RequiredActionFactory`. The provider's `evaluateTriggers` adds the action by condition, `requiredActionChallenge` shows a page or finishes, and `processAction` handles the submitted form. `success()` removes the action, `challenge` shows a page, `failure` ends the sign-in and `ignore` leaves the action for the next sign-in. The services file is named after `org.keycloak.authentication.RequiredActionFactory`.

A loaded action is not used until a realm registers it with its provider id, enables it and assigns it to users. The key facts to remember are these:

- Load, register, enable and assign are four separate steps.
- A custom action's alias equals its provider id.
- `requiredActions` replaces the whole list when you set it.
- A disabled action is skipped without an error.

<!-- astrona:playground:destroy -->
