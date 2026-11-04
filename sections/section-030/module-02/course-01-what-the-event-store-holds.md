# What The Event Store Holds

When a user fails to sign in, Keycloak does two separate things. It sends the event to every listener of the realm, and it may save the event in the database. Many administrators think these are one setting. This part separates them and reads the fields that control the saving.

## Two stores, two kinds of event

Keycloak keeps user events and admin events in two separate tables of its database. The default storage provider is `jpa`, which means Java Persistence API: it writes the events through the same database connection as the rest of Keycloak. A user event is a record such as `LOGIN` or `LOGIN_ERROR`. An admin event is a record of one change made through the Admin REST API, such as the creation of a user.

A realm turns each kind on on its own. The field `eventsEnabled` turns on the storing of user events. The field `adminEventsEnabled` turns on the storing of admin events. Both are `false` in a new realm.

## The fields of the event configuration

The realm's event configuration is one JSON object, at the path `events/config` of the Admin REST API. These fields matter:

- `eventsEnabled`: store user events.
- `enabledEventTypes`: the list of user event types that the realm stores. When the list is empty, Keycloak stores a default set of types.
- `eventsExpiration`: how long stored user events live, in seconds. When it is not set, they never expire.
- `eventsListeners`: the listeners that receive events. A new realm lists `jboss-logging`.
- `adminEventsEnabled`: store admin events.
- `adminEventsDetailsEnabled`: store the representation, the JSON of the changed object, with each admin event.

The fields of the first group concern the store. `eventsListeners` concerns the listeners, and it has no effect on what is stored. Storing and listening are independent: a realm can store events and have no listener, or have listeners and store nothing.

## Read the configuration

Read the event configuration of the realm `inventory`. The helper `kcadm` runs `kcadm.sh` in the Keycloak pod as the lab-only administrator:

<!-- astrona:playground:renew -->

```sh
kcadm get events/config -r inventory
```

The output is a JSON object with the fields above. In a new realm, `eventsEnabled` and `adminEventsEnabled` are `false` and `eventsListeners` holds `jboss-logging`. Ask for the stored user events:

```sh
kcadm get events -r inventory
```

The list is empty, because the realm stores nothing yet. The `jboss-logging` listener still writes failed events to the server log, but the Admin REST API shows only what the store holds.

You now know that Keycloak stores user events and admin events separately, and which fields turn the storing on. The open question is which event types to store, because storing all of them fills the database quickly.

## Common pitfalls

> [!WARNING]
> - **Thinking a listener fills the store.** The store holds an event only when the realm has the matching `...Enabled` field on and the type is on the list.
> - **Reading `eventsListeners` as a storage setting.** It names the listeners and has no effect on the saved events.
> - **Expecting old events after turning the store on.** Only events that happen after the change are saved.
