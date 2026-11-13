
package com.capitulo0.backend;

import java.net.URI;
import java.net.http.*;
import java.util.List;
import java.util.UUID;

import com.capitulo0.backend.auth.model.AuthenticatedFirebaseUser;
import com.capitulo0.backend.auth.service.FirebaseTokenVerifier;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

@SpringBootTest(
    webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
    properties = "app.cors.allowed-origins=http://localhost:7357"
)
@ActiveProfiles("test")
class CorsEndpointTests {

    @Value("${local.server.port}")
    int port;

    @MockitoBean
    FirebaseTokenVerifier verifier;

    final HttpClient client = HttpClient.newHttpClient();

    static final String ORIGIN = "http://localhost:7357";

    @BeforeEach
    void tokens() {
        when(verifier.verify("valid-fixture"))
            .thenReturn(
                new AuthenticatedFirebaseUser(
                    "cors-" + UUID.randomUUID(),
                    UUID.randomUUID() + "@example.test",
                    "Cors fixture",
                    true
                )
            );

        when(verifier.verify("invalid-fixture"))
            .thenThrow(
                new BadCredentialsException("fixture-only")
            );
    }

    HttpRequest.Builder request(String path) {
        return HttpRequest.newBuilder(
            URI.create("http://127.0.0.1:" + port + path)
        );
    }

    String username() {
        return "cors_" + UUID.randomUUID()
            .toString()
            .replace("-", "")
            .substring(0, 20);
    }

    String provisionBody() {
        return "{\"username\":\"" + username() + "\"}";
    }

    HttpResponse<String> preflight(
        String origin,
        String method,
        String headers
    ) throws Exception {

        return client.send(
            request("/api/me/provision")
                .header("Origin", origin)
                .header("Access-Control-Request-Method", method)
                .header("Access-Control-Request-Headers", headers)
                .method(
                    "OPTIONS",
                    HttpRequest.BodyPublishers.noBody()
                )
                .build(),
            HttpResponse.BodyHandlers.ofString()
        );
    }

    void assertCors(HttpResponse<String> response) {

        assertThat(
            response.headers()
                .firstValue("Access-Control-Allow-Origin")
        ).contains(ORIGIN);

        assertThat(
            response.headers()
                .firstValue("Access-Control-Allow-Credentials")
        ).isEmpty();
    }

    @Test
    void allowedPreflightDoesNotRequireBearerOrInvokeFirebase()
            throws Exception {

        var response = preflight(
            ORIGIN,
            "POST",
            "authorization,content-type"
        );

        assertThat(response.statusCode()).isEqualTo(200);

        assertCors(response);

        assertThat(
            response.headers()
                .firstValue("Access-Control-Allow-Methods")
                .orElse("")
        ).contains("POST");

        verifyNoInteractions(verifier);
    }

    @Test
    void rejectsOtherOriginsAndPortsBeforeAuthentication()
            throws Exception {

        for (var origin : List.of(
            "http://localhost:7358",
            "http://127.0.0.1:7357",
            "https://untrusted.example.test"
        )) {

            var response = preflight(
                origin,
                "POST",
                "authorization"
            );

            assertThat(response.statusCode()).isEqualTo(403);

            assertThat(
                response.headers()
                    .firstValue("Access-Control-Allow-Origin")
            ).isEmpty();
        }

        verifyNoInteractions(verifier);
    }

    @Test
    void rejectsUnconfiguredMethodsAndHeaders()
            throws Exception {

        assertThat(
            preflight(
                ORIGIN,
                "PUT",
                "authorization"
            ).statusCode()
        ).isEqualTo(403);

        assertThat(
            preflight(
                ORIGIN,
                "POST",
                "x-client-uid"
            ).statusCode()
        ).isEqualTo(403);

        verifyNoInteractions(verifier);
    }

    @Test
    void allowedCorsDoesNotBypassAuthenticationAndIncludesErrorHeaders()
            throws Exception {

        var response = client.send(
            request("/api/me")
                .header("Origin", ORIGIN)
                .GET()
                .build(),
            HttpResponse.BodyHandlers.ofString()
        );

        assertThat(response.statusCode()).isEqualTo(401);

        assertCors(response);

        assertThat(
            response.headers()
                .firstValue("WWW-Authenticate")
        ).contains("Bearer");

        verifyNoInteractions(verifier);
    }

    @Test
    void browserCanProvisionWithVerifiedBearerAndMeStillUsesUid()
            throws Exception {

        var response = client.send(
            request("/api/me/provision")
                .header("Origin", ORIGIN)
                .header(
                    "Authorization",
                    "Bearer valid-fixture"
                )
                .header(
                    "Content-Type",
                    "application/json"
                )
                .POST(
                    HttpRequest.BodyPublishers.ofString(
                        provisionBody()
                    )
                )
                .build(),
            HttpResponse.BodyHandlers.ofString()
        );

        assertThat(response.statusCode())
            .as(response.body())
            .isEqualTo(200);

        assertCors(response);

        assertThat(response.body())
            .doesNotContain(
                "firebaseUid",
                "firebase_uid"
            );

        var me = client.send(
            request("/api/me")
                .header("Origin", ORIGIN)
                .header(
                    "Authorization",
                    "Bearer valid-fixture"
                )
                .GET()
                .build(),
            HttpResponse.BodyHandlers.ofString()
        );

        assertThat(me.statusCode()).isEqualTo(200);

        assertCors(me);
    }

    @Test
    void deniedLegacyUserApiKeepsCorsAndPermissionChecks()
            throws Exception {

        var response = client.send(
            request("/api/users")
                .header("Origin", ORIGIN)
                .header(
                    "Authorization",
                    "Bearer valid-fixture"
                )
                .GET()
                .build(),
            HttpResponse.BodyHandlers.ofString()
        );

        assertThat(response.statusCode()).isEqualTo(403);

        assertCors(response);
    }

    @Test
    void invalidTokenKeepsSanitized401WithCors()
            throws Exception {

        var response = client.send(
            request("/api/me")
                .header("Origin", ORIGIN)
                .header(
                    "Authorization",
                    "Bearer invalid-fixture"
                )
                .GET()
                .build(),
            HttpResponse.BodyHandlers.ofString()
        );

        assertThat(response.statusCode()).isEqualTo(401);

        assertCors(response);

        assertThat(response.body())
            .doesNotContain("fixture-only");
    }

    @Test
    void nativeRequestsWithoutOriginRemainSupported()
            throws Exception {

        var response = client.send(
            request("/api/me/provision")
                .header(
                    "Authorization",
                    "Bearer valid-fixture"
                )
                .header(
                    "Content-Type",
                    "application/json"
                )
                .POST(
                    HttpRequest.BodyPublishers.ofString(
                        provisionBody()
                    )
                )
                .build(),
            HttpResponse.BodyHandlers.ofString()
        );

        assertThat(response.statusCode())
            .as(response.body())
            .isEqualTo(200);

        assertThat(
            response.headers()
                .firstValue("Access-Control-Allow-Origin")
        ).isEmpty();
    }
}
