package io.astrona.keycloak.inventory;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.ext.Provider;
import org.keycloak.models.KeycloakSession;

@Provider
public class InventoryStatusResource {

    private final KeycloakSession session;
    private final String mode;

    public InventoryStatusResource(KeycloakSession session, String mode) {
        this.session = session;
        this.mode = mode;
    }

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public String status() {
        String realmName = session.getContext().getRealm().getName();
        return "inventory-status ok realm=" + realmName + " mode=" + mode + "\n";
    }
}
