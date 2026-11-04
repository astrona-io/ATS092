package io.astrona.keycloak.inventory;

import org.keycloak.authentication.RequiredActionContext;
import org.keycloak.authentication.RequiredActionProvider;

// The required action: Keycloak calls it after the user signed in, when the
// user has "accept-terms" in the list of required actions.
public class AcceptTermsRequiredAction implements RequiredActionProvider {

    @Override
    public void evaluateTriggers(RequiredActionContext context) {
    }

    @Override
    public void requiredActionChallenge(RequiredActionContext context) {
        context.getUser().setSingleAttribute("termsAccepted", "true");
        context.success();
    }

    @Override
    public void processAction(RequiredActionContext context) {
        context.success();
    }

    @Override
    public void close() {
    }
}
