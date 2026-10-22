package io.astrona.keycloak.inventory;

import org.jboss.logging.Logger;
import org.keycloak.events.Event;
import org.keycloak.events.EventListenerProvider;
import org.keycloak.events.EventType;
import org.keycloak.events.admin.AdminEvent;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;

// Writes one INFO line to the Keycloak log for every successful login and
// every admin event. Every line starts with AUDIT-LOG.
public class AuditLogEventListenerProvider implements EventListenerProvider {

    private static final Logger LOG = Logger.getLogger(AuditLogEventListenerProvider.class);

    private final KeycloakSession session;

    public AuditLogEventListenerProvider(KeycloakSession session) {
        this.session = session;
    }

    @Override
    public void onEvent(Event event) {
        if (event.getType() != EventType.LOGIN) {
            return;
        }
        RealmModel realm = session.realms().getRealm(event.getRealmId());
        String realmName = realm == null ? event.getRealmId() : realm.getName();
        String username = event.getUserId();
        if (realm != null && event.getUserId() != null) {
            UserModel user = session.users().getUserById(realm, event.getUserId());
            if (user != null) {
                username = user.getUsername();
            }
        }
        LOG.infof("AUDIT-LOG type=%s realm=%s client=%s user=%s",
                event.getType(), realmName, event.getClientId(), username);
    }

    @Override
    public void onEvent(AdminEvent event, boolean includeRepresentation) {
        // Admin events are not handled yet.
    }

    @Override
    public void close() {
    }
}
