package io.astrona.keycloak.inventory;

import java.util.List;
import org.keycloak.Config;
import org.keycloak.authentication.Authenticator;
import org.keycloak.authentication.AuthenticatorFactory;
import org.keycloak.models.AuthenticationExecutionModel;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;
import org.keycloak.provider.ProviderConfigProperty;

public class RequireDepartmentAuthenticatorFactory implements AuthenticatorFactory {

    public static final String PROVIDER_ID = "require-department-attribute";

    // The authenticator keeps no state, so one instance serves every request.
    private static final RequireDepartmentAuthenticator SINGLETON = new RequireDepartmentAuthenticator();

    private static final AuthenticationExecutionModel.Requirement[] REQUIREMENT_CHOICES = {
            AuthenticationExecutionModel.Requirement.REQUIRED,
            AuthenticationExecutionModel.Requirement.DISABLED
    };

    @Override
    public String getId() {
        return PROVIDER_ID;
    }

    @Override
    public String getDisplayType() {
        return "Require Department Attribute";
    }

    @Override
    public String getReferenceCategory() {
        return "department";
    }

    @Override
    public String getHelpText() {
        return "Fails the flow when the user has no value in the configured user attribute.";
    }

    @Override
    public boolean isConfigurable() {
        return true;
    }

    @Override
    public AuthenticationExecutionModel.Requirement[] getRequirementChoices() {
        return REQUIREMENT_CHOICES;
    }

    @Override
    public boolean isUserSetupAllowed() {
        return false;
    }

    @Override
    public List<ProviderConfigProperty> getConfigProperties() {
        return List.of(new ProviderConfigProperty(
                RequireDepartmentAuthenticator.CONFIG_ATTRIBUTE,
                "User attribute",
                "The user attribute that must have a value.",
                ProviderConfigProperty.STRING_TYPE,
                RequireDepartmentAuthenticator.DEFAULT_ATTRIBUTE));
    }

    @Override
    public Authenticator create(KeycloakSession session) {
        return SINGLETON;
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
}
