# Section 030: Event Listeners

Keycloak records what happens in a realm as events. A user signs in, enters a wrong password or updates a profile; an administrator creates a user or changes a client. Each of these is an event, and Keycloak hands every event to the event listeners that the realm turns on. An event listener is a provider that receives events and does something with them: writes a log line, sends a message, or stores a record.

This section teaches you to write your own listener and to make a realm use it. That is the standard way to connect Keycloak to an audit system, a message queue or a security tool. You also learn the difference between user events and admin events, because they arrive through different methods and are turned on in different places.

## What you will learn

- What user events and admin events are, and the event types you meet most often.
- What the built-in `jboss-logging` listener writes to the server log, and at which log level.
- How to write an `EventListenerProvider` and its factory, and register them.
- How a realm turns listeners on with its event configuration, next to `jboss-logging`.
- How to turn admin events on, and how to see an admin change in your own listener.
- How to prove a listener works with a real sign-in and a line in `kubectl logs`.
- How the realm's event store keeps events in its database, which event types and admin event details to store, and how to query them with filters.
- How to expire stored events and how to clear them.

## The learning path

Work through the modules in order. Each has a landing page, five short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground.

### 1. Send Keycloak Events To Your Own Listener

The playground runs Keycloak 26.8.1 in the namespace `events-demo`, with the realm `inventory`, the user `alice` and the client `inventory-cli`.

1. User Events And Admin Events
2. Writing An Event Listener
3. Enabling A Listener In A Realm, followed by the lab **Log Every Login With A Custom Listener**
4. Summary

### 2. Store, Query And Expire Keycloak Events

The playground runs Keycloak 26.8.1 in the namespace `events-demo`, with the realm `inventory`, the user `alice` and the client `inventory-cli`.

1. What The Event Store Holds
2. Choosing What To Store
3. Querying Stored Events, followed by the lab **Make Failed Sign-Ins Searchable**
4. Expiring And Clearing Events
5. Summary

## Section capstone: Audit Admin Changes With A Custom Listener

The capstone combines the whole section. The audit team now wants every administrator change in the realm `inventory` in the log as well, and the realm's event settings were changed in a hurry. You must extend the listener's code, restore the realm's listeners and turn on admin events, then prove it with a user created through the Admin REST API. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS092.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-092-capstone-030
```
