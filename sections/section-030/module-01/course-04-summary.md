# Summary

Keycloak records what happens in a realm as events. A user event, such as `LOGIN` or `LOGIN_ERROR`, comes from what a user does and has a type. An admin event comes from a change made through the Admin REST API and has an operation type, such as `CREATE`, a resource type, such as `USER`, and a resource path. An admin event belongs to the realm that was changed, not to the realm the administrator signed in to.

A realm's event configuration lists its listeners in `eventsListeners`, and every listener in that list receives every event of the realm. Saving is a separate choice: `eventsEnabled` and `adminEventsEnabled` store events in the database, and this course turns admin events on whenever a listener needs them. The built-in `jboss-logging` listener writes failed events at `warn` and successful ones at `debug`, so a successful sign-in does not appear in a server log that prints `info` and above.

A listener implements `EventListenerProvider`, with `onEvent(Event)` for user events and `onEvent(AdminEvent, boolean)` for admin events. A user event holds ids, so a listener that writes names looks the realm and the user up through its `KeycloakSession`. The factory implements `EventListenerProviderFactory`; its id is the name a realm puts in its list, and the services file is named after the factory interface. A new JAR needs a restart, but changing a realm's listeners does not. The key facts to remember are these:

- A loaded listener receives nothing until a realm lists it.
- Setting `eventsListeners` replaces the list; keep `jboss-logging` in it.
- Test a `LOGIN` listener with a successful sign-in; a wrong password sends `LOGIN_ERROR`.
- Prove a listener with a real event and a line in `kubectl logs`.

<!-- astrona:playground:destroy -->
