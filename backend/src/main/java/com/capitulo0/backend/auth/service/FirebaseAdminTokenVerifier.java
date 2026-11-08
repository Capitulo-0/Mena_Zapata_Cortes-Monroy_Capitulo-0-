package com.capitulo0.backend.auth.service;

import com.capitulo0.backend.auth.model.AuthenticatedFirebaseUser;
import com.google.firebase.ErrorCode;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import org.springframework.beans.BeansException;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationServiceException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.stereotype.Component;

@Component
public class FirebaseAdminTokenVerifier implements FirebaseTokenVerifier {
    private final ObjectProvider<FirebaseAuth> auth;
    private final boolean checkRevoked;

    public FirebaseAdminTokenVerifier(ObjectProvider<FirebaseAuth> auth,
            @Value("${firebase.check-revoked:true}") boolean checkRevoked) {
        this.auth = auth;
        this.checkRevoked = checkRevoked;
    }

    @Override public AuthenticatedFirebaseUser verify(String idToken) {
        if (idToken == null || idToken.isBlank()) throw new BadCredentialsException("Invalid token");
        FirebaseAuth firebaseAuth;
        try {
            firebaseAuth = auth.getObject();
        } catch (BeansException | IllegalStateException ex) {
            // Never expose ADC paths, credential contents or SDK exception messages.
            throw new AuthenticationServiceException("Identity service unavailable");
        }
        try {
            var token = firebaseAuth.verifyIdToken(idToken, checkRevoked);
            return new AuthenticatedFirebaseUser(token.getUid(), token.getEmail(), token.getName());
        } catch (FirebaseAuthException ex) {
            if (ex.getErrorCode() == ErrorCode.UNAVAILABLE || ex.getErrorCode() == ErrorCode.INTERNAL) {
                throw new AuthenticationServiceException("Identity service unavailable");
            }
            throw new BadCredentialsException("Invalid token");
        } catch (IllegalArgumentException ex) {
            throw new BadCredentialsException("Invalid token");
        }
    }
}
