package io.astrona.keycloak.inventory;

import org.keycloak.Config;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;
import org.keycloak.services.resource.RealmResourceProvider;
import org.keycloak.services.resource.RealmResourceProviderFactory;

// The factory reads its setting "mode" once, in init(), and hands it to
// every provider it creates.
public class InventoryStatusResourceProviderFactory implements RealmResourceProviderFactory {

    public static final String PROVIDER_ID = "inventory-status";

    private String mode;

    @Override
    public RealmResourceProvider create(KeycloakSession session) {
        return new InventoryStatusResourceProvider(session, mode);
    }

    @Override
    public void init(Config.Scope config) {
        this.mode = config.get("mode", "standard");
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
