
package com.capitulo0.backend;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.UUID;

import com.capitulo0.backend.auth.model.AuthenticatedFirebaseUser;
import com.capitulo0.backend.auth.service.FirebaseTokenVerifier;
import com.capitulo0.backend.user.repository.UserRepository;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import tools.jackson.databind.json.JsonMapper;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class ProfilePrivacyEndpointTests {

    @Value("${local.server.port}")
    int port;

    @MockitoBean
    FirebaseTokenVerifier verifier;

    @Autowired
    UserRepository users;

    private final HttpClient client = HttpClient.newHttpClient();
    private final JsonMapper json = JsonMapper.builder().build();

    private String token;
    private String uid;

    @BeforeEach
    void setup() {
        uid = UUID.randomUUID().toString();
        token = "test-" + UUID.randomUUID();

        var identity = new AuthenticatedFirebaseUser(
            uid,
            UUID.randomUUID() + "@example.test",
            "Usuario de prueba",
            true
        );

        when(verifier.verify(anyString())).thenAnswer(call -> {
            if (!token.equals(call.getArgument(0))) {
                throw new BadCredentialsException("Token inválido");
            }
            return identity;
        });
    }

    private String username() {
        return "user_" + UUID.randomUUID()
            .toString().replace("-", "").substring(0, 20);
    }

    private HttpResponse<String> call(
        String method,
        String path,
        String authToken,
        String body
    ) throws Exception {
        var builder = HttpRequest.newBuilder(
                URI.create("http://127.0.0.1:" + port + path)
            )
            .header("Content-Type", "application/json");

        if (authToken != null) {
            builder.header("Authorization", "Bearer " + authToken);
        }

        return client.send(
            builder.method(
                method,
                body == null
                    ? HttpRequest.BodyPublishers.noBody()
                    : HttpRequest.BodyPublishers.ofString(body)
            ).build(),
            HttpResponse.BodyHandlers.ofString()
        );
    }

    private void provision() throws Exception {
        var response = call(
            "POST",
            "/api/me/provision",
            token,
            "{\"username\":\"" + username() + "\"}"
        );

        assertThat(response.statusCode())
            .as(response.body())
            .isEqualTo(200);
    }

    @Test
    void newAccountsArePublicByDefault() throws Exception {
        provision();

        var response = call("GET", "/api/me", token, null);

        assertThat(response.statusCode()).isEqualTo(200);
        assertThat(json.readTree(response.body())
            .get("isPrivate").asBoolean()).isFalse();

        assertThat(users.findByFirebaseUid(uid)
            .orElseThrow().getIsPrivate()).isFalse();
    }

    @Test
    void canChangeToPrivateAndPersist() throws Exception {
        provision();

        var response = call(
            "PATCH",
            "/api/me/privacy",
            token,
            "{\"isPrivate\":true}"
        );

        assertThat(response.statusCode())
            .as(response.body())
            .isEqualTo(200);

        assertThat(json.readTree(response.body())
            .get("isPrivate").asBoolean()).isTrue();

        assertThat(users.findByFirebaseUid(uid)
            .orElseThrow().getIsPrivate()).isTrue();

        var reloaded = call("GET", "/api/me", token, null);

        assertThat(json.readTree(reloaded.body())
            .get("isPrivate").asBoolean()).isTrue();
    }

    @Test
    void canChangeFromPrivateToPublic() throws Exception {
        provision();

        call(
            "PATCH",
            "/api/me/privacy",
            token,
            "{\"isPrivate\":true}"
        );

        var response = call(
            "PATCH",
            "/api/me/privacy",
            token,
            "{\"isPrivate\":false}"
        );

        assertThat(response.statusCode())
            .as(response.body())
            .isEqualTo(200);

        assertThat(json.readTree(response.body())
            .get("isPrivate").asBoolean()).isFalse();

        assertThat(users.findByFirebaseUid(uid)
            .orElseThrow().getIsPrivate()).isFalse();
    }

    @Test
    void rejectsMissingPrivacyValue() throws Exception {
        provision();

        var response = call(
            "PATCH",
            "/api/me/privacy",
            token,
            "{}"
        );

        assertThat(response.statusCode()).isEqualTo(400);

        assertThat(users.findByFirebaseUid(uid)
            .orElseThrow().getIsPrivate()).isFalse();
    }

    @Test
    void rejectsNullPrivacyValue() throws Exception {
        provision();

        var response = call(
            "PATCH",
            "/api/me/privacy",
            token,
            "{\"isPrivate\":null}"
        );

        assertThat(response.statusCode()).isEqualTo(400);
    }

    @Test
    void changingPrivacyPreservesProfileFields() throws Exception {
        provision();

        var before = users.findByFirebaseUid(uid).orElseThrow();

        String originalUsername = before.getUsername();
        String originalName = before.getDisplayName();
        Integer originalGoal = before.getAnnualReadingGoal();

        var response = call(
            "PATCH",
            "/api/me/privacy",
            token,
            "{\"isPrivate\":true}"
        );

        assertThat(response.statusCode()).isEqualTo(200);

        var after = users.findByFirebaseUid(uid).orElseThrow();

        assertThat(after.getUsername()).isEqualTo(originalUsername);
        assertThat(after.getDisplayName()).isEqualTo(originalName);
        assertThat(after.getAnnualReadingGoal()).isEqualTo(originalGoal);
    }

    @Test
    void rejectsUnauthenticatedPrivacyChanges() throws Exception {
        var response = call(
            "PATCH",
            "/api/me/privacy",
            null,
            "{\"isPrivate\":true}"
        );

        assertThat(response.statusCode()).isEqualTo(401);
    }
}
