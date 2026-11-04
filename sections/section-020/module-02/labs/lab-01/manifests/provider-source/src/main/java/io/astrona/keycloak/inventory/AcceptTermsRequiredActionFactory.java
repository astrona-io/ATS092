package io.astrona.keycloak.inventory;

import org.keycloak.Config;
import org.keycloak.authentication.RequiredActionFactory;
import org.keycloak.authentication.RequiredActionProvider;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;

// The factory: its id is the provider id used to register the action in a realm.
public class AcceptTermsRequiredActionFactory implements RequiredActionFactory {

    public static final String PROVIDER_ID = "accept-terms";

    @Override
    public String getDisplayText() {
        return "Accept the terms";
    }

    @Override
    public RequiredActionProvider create(KeycloakSession session) {
        return new AcceptTermsRequiredAction();
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
