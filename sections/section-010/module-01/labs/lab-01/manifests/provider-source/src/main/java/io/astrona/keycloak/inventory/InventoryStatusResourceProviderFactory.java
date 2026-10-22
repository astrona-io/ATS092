package io.astrona.keycloak.inventory;

import org.keycloak.Config;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;
import org.keycloak.services.resource.RealmResourceProvider;
import org.keycloak.services.resource.RealmResourceProviderFactory;

// The factory: Keycloak finds it through META-INF/services and keeps one
// instance for the life of the server. getId() is the provider id, and for
// this SPI also the last part of the URL.
public class InventoryStatusResourceProviderFactory implements RealmResourceProviderFactory {

    public static final String PROVIDER_ID = "inventory-status";

    @Override
    public RealmResourceProvider create(KeycloakSession session) {
        return new InventoryStatusResourceProvider(session);
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
