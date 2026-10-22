package io.astrona.keycloak.inventory;

import org.keycloak.Config;
import org.keycloak.events.EventListenerProvider;
import org.keycloak.events.EventListenerProviderFactory;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;

// The id returned by getId() is the name you add to a realm's event listeners.
public class AuditLogEventListenerProviderFactory implements EventListenerProviderFactory {

    public static final String PROVIDER_ID = "audit-log";

    @Override
    public EventListenerProvider create(KeycloakSession session) {
        return new AuditLogEventListenerProvider(session);
    }

    @Override
    public void init(Config.Scope config) {
    }

    @Override
    public void postInit(KeycloakSessionFactory factory) {
    }

    @Override
    public void close() {
    }

    @Override
    public String getId() {
        return PROVIDER_ID;
    }
}
