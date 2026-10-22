package io.astrona.keycloak.inventory;

import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.keycloak.authentication.AuthenticationFlowContext;
import org.keycloak.authentication.AuthenticationFlowError;
import org.keycloak.authentication.Authenticator;
import org.keycloak.models.AuthenticatorConfigModel;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;
import org.keycloak.representations.idm.OAuth2ErrorRepresentation;

// Lets the flow continue only when the user has a value in one user attribute.
public class RequireDepartmentAuthenticator implements Authenticator {

    static final String CONFIG_ATTRIBUTE = "attribute";
    static final String DEFAULT_ATTRIBUTE = "department";

    @Override
    public void authenticate(AuthenticationFlowContext context) {
        String attribute = DEFAULT_ATTRIBUTE;
        AuthenticatorConfigModel config = context.getAuthenticatorConfig();
        if (config != null && config.getConfig() != null) {
            String configured = config.getConfig().get(CONFIG_ATTRIBUTE);
            if (configured != null && !configured.isBlank()) {
                attribute = configured;
            }
        }

        UserModel user = context.getUser();
        String value = user == null ? null : user.getFirstAttribute(attribute);
        if (value == null || value.isBlank()) {
            // A direct grant answers with JSON, so send an OAuth 2.0 error body.
            Response response = Response.status(Response.Status.UNAUTHORIZED)
                    .entity(new OAuth2ErrorRepresentation("invalid_grant",
                            "User has no value in the attribute " + attribute))
                    .type(MediaType.APPLICATION_JSON_TYPE)
                    .build();
            context.failure(AuthenticationFlowError.ACCESS_DENIED, response);
            return;
        }
        context.success();
    }

    @Override
    public void action(AuthenticationFlowContext context) {
        // No form, so there is never an action to process.
    }

    @Override
    public boolean requiresUser() {
        return true;
    }

    @Override
    public boolean configuredFor(KeycloakSession session, RealmModel realm, UserModel user) {
        return true;
    }

    @Override
    public void setRequiredActions(KeycloakSession session, RealmModel realm, UserModel user) {
    }

    @Override
    public void close() {
    }
}
