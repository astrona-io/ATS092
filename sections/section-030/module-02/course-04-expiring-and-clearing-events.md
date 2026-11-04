# Expiring And Clearing Events

Stored events grow without limit. A realm that keeps every failed sign-in for years has a large table, slow queries and a pile of personal data such as IP addresses. This part sets a lifetime for stored user events and deletes events by hand, and says what the realm does with them.

## Set a lifetime for user events

The field `eventsExpiration` is the lifetime of stored user events, in seconds. Keycloak runs a background task that deletes the events that are older than the lifetime. A value of 86400 keeps events for one day, and 2592000 keeps them for 30 days. When the field is not set, events never expire.

Set the lifetime to one day:

<!-- astrona:playground:renew -->

```sh
kcadm update events/config -r inventory -s eventsExpiration=86400
kcadm get events/config -r inventory --fields eventsEnabled,eventsExpiration
```

The second command shows that both fields are set. The deleting does not happen the moment an event passes its age. The background task runs on a schedule, so an event can stay in the list somewhat longer than the lifetime. The lifetime is a limit on how old a stored event can become, not an exact timer.

The field `eventsExpiration` applies to user events. For admin events, delete them with the command in the next section when you no longer need them.

## Delete events by hand

The Admin REST API can delete all stored events of a realm in one request. The request has no filter: it removes every event of that kind. Read the list before and after to see the effect:

```sh
kcadm get events -r inventory --fields type
kcadm delete events -r inventory
kcadm get events -r inventory --fields type
```

The first command lists the stored events, and the last one prints an empty list. Deleting stored admin events works the same way:

```sh
kcadm delete admin-events -r inventory
```

Neither command touches the log lines that `jboss-logging` or your own listener already wrote. The server log is not part of the store.

## Plan what to keep

Choose the lifetime from the question the store must answer. A security review of failed sign-ins needs a few weeks. A legal rule can require a year or more, and a database is then the wrong long-term place. For long retention, forward each event to a log system or a message queue with an event listener, and keep the realm's store short. The store answers recent questions fast; the external system keeps the history.

A realm can also change the storage itself. The default provider writes to the database. Keycloak lets you replace it with another event store provider, which is a normal SPI: the `eventsStore` SPI, with the id `jpa` for the default provider. Writing one follows the same steps as any provider.

You now know how long stored events live, how to delete them and how to decide what to keep. The module has covered the whole path of an event: sent to listeners, saved by the realm, read through the API and removed when it is old.

## Common pitfalls

> [!WARNING]
> - **Setting `eventsExpiration` in days.** The value is in seconds.
> - **Expecting an exact deletion time.** The background task runs on a schedule.
> - **Deleting events to "reset" a test.** The request removes all events of that kind in the realm, with no filter.
> - **Treating the store as long-term audit storage.** Forward events with a listener when you must keep them for a long time.
