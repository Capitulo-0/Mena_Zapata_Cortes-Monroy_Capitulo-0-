package com.capitulo0.backend;

import java.util.concurrent.atomic.AtomicReference;
import com.capitulo0.backend.auth.model.AuthenticatedFirebaseUser;
import com.capitulo0.backend.auth.service.FirebaseTokenVerifier;
import com.capitulo0.backend.config.security.FirebaseBearerFilter;
import com.capitulo0.backend.config.security.RestSecurityErrors;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import tools.jackson.databind.json.JsonMapper;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class FirebaseBearerFilterTests {
    @Test void verifiedUidBecomesAuthenticationAndRawTokenIsNotRetained() throws Exception {
        var verifier = mock(FirebaseTokenVerifier.class);
        var identity = new AuthenticatedFirebaseUser("verified-uid", null, "Name");
        when(verifier.verify("raw-token")).thenReturn(identity);
        var filter = new FirebaseBearerFilter(verifier, new RestSecurityErrors(JsonMapper.builder().build()));
        var request = new MockHttpServletRequest("GET", "/api/me");
        request.setServletPath("/api/me");
        request.addHeader("Authorization", "bEaReR raw-token");
        var captured = new AtomicReference<Authentication>();
        try {
            filter.doFilter(request, new MockHttpServletResponse(), (req, res) -> {
                captured.set(SecurityContextHolder.getContext().getAuthentication());
                assertThat(req.getServletContext()).isNotNull();
                assertThat(((jakarta.servlet.http.HttpServletRequest) req).getSession(false)).isNull();
            });
            assertThat(captured.get().isAuthenticated()).isTrue();
            assertThat(captured.get().getPrincipal()).isSameAs(identity);
            assertThat(captured.get().getName()).isEqualTo("verified-uid");
            assertThat(captured.get().getCredentials()).isNull();
            verify(verifier, times(1)).verify("raw-token");
        } finally { SecurityContextHolder.clearContext(); }
    }
    @Test void multipleAuthorizationHeadersAreRejectedWithoutVerification() throws Exception {
        var verifier = mock(FirebaseTokenVerifier.class);
        var filter = new FirebaseBearerFilter(verifier, new RestSecurityErrors(JsonMapper.builder().build()));
        var request = new MockHttpServletRequest("GET", "/api/me"); request.setServletPath("/api/me");
        request.addHeader("Authorization", "Bearer first"); request.addHeader("Authorization", "Bearer second");
        var response = new MockHttpServletResponse();
        filter.doFilter(request, response, (req,res) -> { throw new AssertionError("Must not continue"); });
        assertThat(response.getStatus()).isEqualTo(401);
        verifyNoInteractions(verifier);
    }
}
