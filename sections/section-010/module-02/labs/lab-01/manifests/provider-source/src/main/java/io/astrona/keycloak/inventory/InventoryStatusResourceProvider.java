package io.astrona.keycloak.inventory;

import org.keycloak.models.KeycloakSession;
import org.keycloak.services.resource.RealmResourceProvider;

public class InventoryStatusResourceProvider implements RealmResourceProvider {

    private final KeycloakSession session;
    private final String mode;

    public InventoryStatusResourceProvider(KeycloakSession session, String mode) {
        this.session = session;
        this.mode = mode;
    }

    @Override
    public Object getResource() {
        return new InventoryStatusResource(session, mode);
    }

    @Override
    public void close() {
    }
}
