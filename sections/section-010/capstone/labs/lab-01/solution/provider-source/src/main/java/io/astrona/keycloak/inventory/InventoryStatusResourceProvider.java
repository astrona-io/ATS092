package io.astrona.keycloak.inventory;

import org.keycloak.models.KeycloakSession;
import org.keycloak.services.resource.RealmResourceProvider;

// The provider: Keycloak creates one per request and asks it for the resource.
public class InventoryStatusResourceProvider implements RealmResourceProvider {

    private final KeycloakSession session;

    public InventoryStatusResourceProvider(KeycloakSession session) {
        this.session = session;
    }

    @Override
    public Object getResource() {
        return new InventoryStatusResource(session);
    }

    @Override
    public void close() {
    }
}
