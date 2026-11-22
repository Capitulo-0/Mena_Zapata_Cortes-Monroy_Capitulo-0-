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
class ProfileUpdateEndpointTests {
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
    private void provision(String username) throws Exception {
        var response = call(
            "POST",
            "/api/me/provision",
            token,
            "{\"username\":\"" + username + "\"}"
        );
        assertThat(response.statusCode())
            .as(response.body())
            .isEqualTo(200);
    }
    @Test
    void updatesProfileAndPersistsChanges() throws Exception {
        provision(username());
        String newUsername = username();
        var response = call(
            "PATCH",
            "/api/me",
            token,
            """
            {
              "displayName": "Eduardo Lector",
              "username": "%s",
              "biography": "Me encantan los libros.",
              "annualReadingGoal": 40
            }
            """.formatted(newUsername)
        );
        assertThat(response.statusCode())
            .as(response.body())
            .isEqualTo(200);

        var profile = json.readTree(response.body());
        assertThat(profile.get("displayName").asText())
            .isEqualTo("Eduardo Lector");
        assertThat(profile.get("username").asText())
            .isEqualTo(newUsername);
        assertThat(profile.get("biography").asText())
            .isEqualTo("Me encantan los libros.");
        assertThat(profile.get("annualReadingGoal").asInt())
            .isEqualTo(40);

        var saved = users.findByFirebaseUid(uid).orElseThrow();
        assertThat(saved.getAnnualReadingGoal()).isEqualTo(40);
        assertThat(saved.getUsername()).isEqualTo(newUsername);
        var reloaded = call("GET", "/api/me", token, null);
        assertThat(reloaded.statusCode()).isEqualTo(200);
        assertThat(json.readTree(reloaded.body())
            .get("annualReadingGoal").asInt()).isEqualTo(40);
    }
    @Test
    void newUserStartsWithAnnualGoalOf25() throws Exception {
        provision(username());
        var response = call("GET", "/api/me", token, null);
        assertThat(response.statusCode()).isEqualTo(200);
        assertThat(json.readTree(response.body())
            .get("annualReadingGoal").asInt()).isEqualTo(25);
    }
    @Test
    void partialUpdatePreservesExistingValues() throws Exception {
        String initialUsername = username();
        provision(initialUsername);
        var response = call(
            "PATCH",
            "/api/me",
            token,
            "{\"annualReadingGoal\":35}"
        );
        assertThat(response.statusCode()).isEqualTo(200);
        var saved = users.findByFirebaseUid(uid).orElseThrow();
        assertThat(saved.getUsername()).isEqualTo(initialUsername);
        assertThat(saved.getDisplayName()).isEqualTo("Usuario de prueba");
        assertThat(saved.getAnnualReadingGoal()).isEqualTo(35);
    }
    @Test
    void rejectsInvalidAnnualGoal() throws Exception {
        provision(username());
        var response = call(
            "PATCH",
            "/api/me",
            token,
            "{\"annualReadingGoal\":0}"
        );
        assertThat(response.statusCode()).isEqualTo(400);
        assertThat(users.findByFirebaseUid(uid)
            .orElseThrow().getAnnualReadingGoal()).isEqualTo(25);
    }
    @Test
    void rejectsInvalidUsername() throws Exception {
        provision(username());
        var response = call(
            "PATCH",
            "/api/me",
            token,
            "{\"username\":\"Nombre Invalido!\"}"
        );
        assertThat(response.statusCode()).isEqualTo(400);
    }
    @Test
    void rejectsUsernameAlreadyTaken() throws Exception {
        String occupiedUsername = username();
        provision(occupiedUsername);
        String otherUid = UUID.randomUUID().toString();
        var other = com.capitulo0.backend.user.entity.User.create();
        other.setFirebaseUid(otherUid);
        other.setEmail(UUID.randomUUID() + "@example.test");
        other.setUsername(username());
        users.saveAndFlush(other);
        var response = call(
            "PATCH",
            "/api/me",
            token,
            "{\"username\":\"" + other.getUsername() + "\"}"
        );
        assertThat(response.statusCode()).isEqualTo(409);
        assertThat(json.readTree(response.body())
            .get("code").asText()).isEqualTo("USERNAME_TAKEN");
    }
    @Test
    void unauthenticatedRequestsAreRejected() throws Exception {
        var response = call(
            "PATCH",
            "/api/me",
            null,
            "{\"displayName\":\"Intruso\"}"
        );
        assertThat(response.statusCode()).isEqualTo(401);
    }
}
