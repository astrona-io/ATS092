# Event Types And Event Details

A listener that logs every event is rarely useful. The security team wants a failed sign-in with its reason, or a password change with the client that caused it. To write that, you must know which types exist and which fields an event carries. This part lists the common user event types, the fields of user and admin events and how to filter.

## The Event object

A user event is an `Event` object. These fields are the ones a listener uses most:

- `getType()` is an `EventType` value such as `LOGIN`.
- `getRealmId()`, `getClientId()`, `getUserId()` and `getSessionId()` are ids, not names. Any of them can be `null`.
- `getIpAddress()` is the address of the caller.
- `getError()` is set only on error events and holds a short code such as `invalid_user_credentials` or `user_not_found`.
- `getDetails()` is a map of extra values, for example `username`, `auth_method`, `redirect_uri` and `grant_type`, depending on the type.
- `getTime()` is the time of the event in milliseconds.

Because a failed sign-in often has no user (the name does not exist), the `userId` can be `null` and the `username` is in the details. A listener that writes the user must therefore not assume `getUserId()` is set.

## Common user event types

Each type is a constant of `EventType`. A failed variant ends with `_ERROR`.

- Signing in and out: `LOGIN`, `LOGIN_ERROR`, `LOGOUT`, `LOGOUT_ERROR`.
- Tokens: `CODE_TO_TOKEN` (an authorization code exchanged for tokens), `REFRESH_TOKEN`, `CLIENT_LOGIN` (a service account signs in), `INTROSPECT_TOKEN`.
- Accounts: `REGISTER`, `UPDATE_PROFILE`, `UPDATE_PASSWORD`, `RESET_PASSWORD`, `UPDATE_EMAIL`, `DELETE_ACCOUNT`.
- Verification and credentials: `SEND_VERIFY_EMAIL`, `VERIFY_EMAIL`, `UPDATE_TOTP`, `REMOVE_TOTP`.
- Consent: `GRANT_CONSENT`, `REVOKE_GRANT`.

The realm decides which types it stores through its list of enabled event types. A listener, by contrast, receives every event that the code sends, whatever the realm stores.

## Filter by type

A listener usually handles a small set of types. Keep the set in a field and check it first, so unrelated events return at once:

```java
private static final Set<EventType> HANDLED = EnumSet.of(
        EventType.LOGIN, EventType.LOGIN_ERROR, EventType.UPDATE_PASSWORD);

@Override
public void onEvent(Event event) {
    if (!HANDLED.contains(event.getType())) {
        return;
    }
    String reason = event.getError() == null ? "none" : event.getError();
    String username = event.getDetails() == null ? null : event.getDetails().get("username");
    // write a line with the type, the client, the username and the reason
}
```

## Admin events

An `AdminEvent` describes a change made through the Admin REST API. Its fields are `getOperationType()` (`CREATE`, `UPDATE`, `DELETE` or `ACTION`), `getResourceType()` (for example `USER`, `CLIENT` or `REALM_ROLE`), `getResourcePath()` (for example `users/<id>`), `getRealmId()` and `getRealmName()`, and `getAuthDetails()`. The auth details say who made the change: the realm, client and user ids and the IP address of the administrator. The representation, the JSON of the changed object, is present only when the second argument of `onEvent` is true, which is controlled by the realm setting `adminEventsDetailsEnabled`.

## Look at stored events

If the realm stores events, you can read them from the Admin REST API. Turn on storing, sign `alice` in once, then ask for the sign-in events of the realm:

<!-- astrona:playground:renew -->

```sh
kcadm update events/config -r inventory -s eventsEnabled=true -s 'enabledEventTypes=["LOGIN","LOGIN_ERROR","UPDATE_PASSWORD"]'
get_user_token alice alice-password > /dev/null
kcadm get events -r inventory -q type=LOGIN
```

The last command prints the stored `LOGIN` events as JSON, with the fields listed above. The `-q type=LOGIN` option sends a query parameter that filters by type. Repeat it with a wrong password and `-q type=LOGIN_ERROR` to see the `error` field.

You now know the fields and types that matter and how to filter on them. The open question is what happens to a sign-in when your own listener throws an error.

## Common pitfalls

> [!WARNING]
> - **Assuming `getUserId()` is set.** Failed sign-ins for an unknown user have no user id.
> - **Looking for the failure reason in the type.** The type is `LOGIN_ERROR`; the reason is in `getError()`.
> - **Reading the representation of an admin event without checking the setting.** It is empty unless details are enabled.
> - **Confusing stored events with received events.** The stored list is limited by the enabled types; the listener sees every event.
