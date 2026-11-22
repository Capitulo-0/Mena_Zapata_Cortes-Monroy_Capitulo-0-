package com.capitulo0.backend;

import com.capitulo0.backend.auth.model.AuthenticatedFirebaseUser;
import com.capitulo0.backend.auth.service.FirebaseAdminTokenVerifier;
import com.google.firebase.ErrorCode;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.AuthenticationServiceException;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

class FirebaseAdminTokenVerifierTests {
    @SuppressWarnings("unchecked")
    private ObjectProvider<FirebaseAuth> provider() { return mock(ObjectProvider.class); }

    @Test void delegatesToAdminSdkWithRevocationCheckAndReturnsOnlyVerifiedFields() throws Exception {
        var provider = provider(); var sdk = mock(FirebaseAuth.class); var token = mock(FirebaseToken.class);
        when(provider.getObject()).thenReturn(sdk);
        when(sdk.verifyIdToken("raw", true)).thenReturn(token);
        when(token.getUid()).thenReturn("verified-uid"); when(token.getEmail()).thenReturn(null);
        when(token.getName()).thenReturn("Verified name");
        assertThat(new FirebaseAdminTokenVerifier(provider, true).verify("raw"))
            .isEqualTo(new AuthenticatedFirebaseUser("verified-uid", null, "Verified name"));
        verify(sdk).verifyIdToken("raw", true);
    }
    @Test void emailVerificationIsTakenOnlyFromVerifiedSdkToken() throws Exception {
        var provider = provider(); var sdk = mock(FirebaseAuth.class); var token = mock(FirebaseToken.class);
        when(provider.getObject()).thenReturn(sdk);
        when(sdk.verifyIdToken("fixture", true)).thenReturn(token);
        when(token.getUid()).thenReturn("verified-fixture-uid");
        when(token.getEmail()).thenReturn("reader@example.test");
        when(token.isEmailVerified()).thenReturn(true);
        var identity = new FirebaseAdminTokenVerifier(provider, true).verify("fixture");
        assertThat(identity.emailVerified()).isTrue();
        when(token.isEmailVerified()).thenReturn(false);
        assertThat(new FirebaseAdminTokenVerifier(provider, true).verify("fixture").emailVerified()).isFalse();
    }
    @Test void sdkRejectsTokenWithoutExposingItsDetails() throws Exception {
        var provider = provider(); var sdk = mock(FirebaseAuth.class); var error = mock(FirebaseAuthException.class);
        when(provider.getObject()).thenReturn(sdk); when(error.getErrorCode()).thenReturn(ErrorCode.INVALID_ARGUMENT);
        when(sdk.verifyIdToken("bad", true)).thenThrow(error);
        assertThatThrownBy(() -> new FirebaseAdminTokenVerifier(provider, true).verify("bad"))
            .isInstanceOf(BadCredentialsException.class).hasMessage("Invalid token").hasNoCause();
    }
    @Test void unavailableAdcInitializationFailsClosedWithoutLeakingPaths() {
        var provider = provider();
        when(provider.getObject()).thenThrow(new BeanCreationException("sensitive credential path"));
        assertThatThrownBy(() -> new FirebaseAdminTokenVerifier(provider, true).verify("raw"))
            .isInstanceOf(AuthenticationServiceException.class).hasMessage("Identity service unavailable").hasNoCause();
    }
    @Test void emptyTokenIsRejectedBeforeSdkInitialization() {
        var provider = provider();
        assertThatThrownBy(() -> new FirebaseAdminTokenVerifier(provider, true).verify(" "))
            .isInstanceOf(BadCredentialsException.class);
        verifyNoInteractions(provider);
    }
    @Test void sdkInfrastructureFailureIsUnavailableInsteadOfInvalidCredentials() throws Exception {
        var provider = provider(); var sdk = mock(FirebaseAuth.class); var error = mock(FirebaseAuthException.class);
        when(provider.getObject()).thenReturn(sdk); when(error.getErrorCode()).thenReturn(ErrorCode.UNAVAILABLE);
        when(sdk.verifyIdToken("raw", true)).thenThrow(error);
        assertThatThrownBy(() -> new FirebaseAdminTokenVerifier(provider, true).verify("raw"))
            .isInstanceOf(AuthenticationServiceException.class).hasNoCause();
    }
}
