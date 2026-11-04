# Summary

Keycloak stores events in its database separately from the listeners that receive them. A realm stores user events when `eventsEnabled` is true, and only for the types in `enabledEventTypes`. It stores admin events when `adminEventsEnabled` is true, and it stores the representation of each change only when `adminEventsDetailsEnabled` is also true. The field `eventsListeners` chooses who receives events and has no effect on what is stored.

An update of `enabledEventTypes` replaces the whole list, so a command must name every type the realm should keep. A change to the event configuration is realm data and is active at once. Only events that happen after the change are stored.

The Admin REST API reads the store. The path `events` takes the filters `type`, `user` (an id), `client`, `ipAddress`, `dateFrom`, `dateTo`, `first` and `max`. The path `admin-events` takes `operationTypes`, `resourceTypes`, `resourcePath`, the `auth...` filters for the caller, the dates, `first` and `max`. A result holds `error` for a failed user event, and `authDetails` and `representation` for an admin event.

The field `eventsExpiration` sets the lifetime of stored user events in seconds, and a background task deletes older events on a schedule. A request to the `events` or `admin-events` path with the delete method removes every stored event of that kind. The key facts to remember are these:

- Storing and listening are separate; a listener never fills the store.
- A failed sign-in is the type `LOGIN_ERROR`, with the reason in `error`.
- The `user` filter takes an id, not a name, and the date filters take `yyyy-MM-dd`.
- `eventsExpiration` is in seconds.

<!-- astrona:playground:destroy -->
