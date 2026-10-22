package io.astrona.keycloak.inventory;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.ext.Provider;
import org.keycloak.models.KeycloakSession;

// The JAX-RS resource that answers GET /realms/<realm>/inventory-status.
@Provider
public class InventoryStatusResource {

    private final KeycloakSession session;

    public InventoryStatusResource(KeycloakSession session) {
        this.session = session;
    }

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public String status() {
        String realmName = session.getContext().getRealm().getName();
        return "inventory-status ok realm=" + realmName + "\n";
    }
}
