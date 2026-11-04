# Failures And Transactions In Listeners

A listener runs inside the request of the user or the administrator that caused the event. A slow or failing listener can therefore affect that request. This part explains what Keycloak does when a listener throws an exception, why a listener must be fast, and how to act after a change is saved.

## An exception does not break the request

Keycloak sends an event to each listener in the realm's list. If one listener throws an exception, Keycloak catches it, writes an error line to the server log that names the listener, and goes on with the other listeners. The sign-in or the admin change still succeeds. This protects users from a broken listener, but it also means a failure is quiet: the user sees nothing, and only the log shows it.

For this reason, a listener should catch the errors it expects, write a clear message, and never let a failure of an outside system, such as a slow web service, stop the work of the others. Do not rely on the exception to cancel the user's action: it cannot.

## The listener runs in the request

Keycloak calls `onEvent` in the same thread and the same request that produced the event. A listener that waits for an outside service delays the user. Keep the work short. If the job is slow, put the event on a queue or in a table and let another process do the job.

## Order of listeners

A realm stores its listeners as a set of ids. Do not write a listener that depends on running before or after another one. If two actions must happen in order, do both in one listener.

## When the change is not saved yet

An admin event is created while the request is still running. The change it describes, such as a new user, may not be in the database yet, and it is not saved if the request later fails. A listener that sends a message to an outside system could report a change that never happened.

To act only after the surrounding transaction commits, a listener enlists a transaction step in the session. Keycloak provides the class `EventListenerTransaction` for this. The listener creates it with two methods, one for admin events and one for user events, and enlists it with `session.getTransactionManager().enlistAfterCompletion(...)`. In `onEvent` it then adds the event to the step instead of handling it, and the step runs the handling after the transaction completes:

```java
public class AuditLogEventListenerProvider implements EventListenerProvider {

    private final EventListenerTransaction transaction =
            new EventListenerTransaction(this::writeAdminLine, this::writeUserLine);

    public AuditLogEventListenerProvider(KeycloakSession session) {
        session.getTransactionManager().enlistAfterCompletion(transaction);
    }

    @Override
    public void onEvent(Event event) {
        transaction.addEvent(event);
    }

    @Override
    public void onEvent(AdminEvent event, boolean includeRepresentation) {
        transaction.addAdminEvent(event, includeRepresentation);
    }
    // writeUserLine(Event) and writeAdminLine(AdminEvent, boolean) write the lines.
}
```

Use this pattern when the effect is hard to undo, such as sending an email or a message. For a log line, the simple form of the listener is enough.

## Find a failing listener in the log

When a listener throws, search the server log for the error that names the listener, and show the lines around it. In the playground, run:

<!-- astrona:playground:renew -->

```sh
kubectl -n events-demo logs deploy/keycloak --since=10m | grep -i "listener"
```

The matching lines tell you which listener failed and the exception it threw. If nothing matches, the listener did not fail; check instead that the realm lists it and that the event type is one the listener handles.

You now know that a listener failure does not stop the request, that a listener runs inside the request and how to act after a commit. The open question is how to keep the events themselves, search them later and stop them from filling the database.

## Common pitfalls

> [!WARNING]
> - **Expecting an exception to stop a sign-in.** Keycloak logs it and continues.
> - **Calling a slow service in `onEvent`.** The user waits for it.
> - **Reporting an admin change before it is saved.** Use a transaction step when the effect is hard to undo.
> - **Depending on the order of listeners.** The order is not defined.
