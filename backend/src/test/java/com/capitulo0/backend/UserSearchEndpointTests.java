
package com.capitulo0.backend;

import com.capitulo0.backend.auth.model.AuthenticatedFirebaseUser;
import com.capitulo0.backend.auth.service.FirebaseTokenVerifier;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.repository.UserRepository;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class UserSearchEndpointTests {

    @Value("${local.server.port}")
    int port;

    @MockitoBean
    FirebaseTokenVerifier verifier;

    @Autowired
    UserRepository users;

    private final HttpClient client = HttpClient.newHttpClient();
    private final JsonMapper json = JsonMapper.builder().build();

    private final Map<String, AuthenticatedFirebaseUser> identities =
        new HashMap<>();

    @BeforeEach
    void setup() {
        identities.clear();

        when(verifier.verify(anyString())).thenAnswer(call -> {
            var identity = identities.get(call.getArgument(0));

            if (identity == null) {
                throw new BadCredentialsException("Token inválido");
            }

            return identity;
        });
    }

    private User createUser(
        String username,
        String displayName,
        boolean isPrivate
    ) {
        User user = User.create();

        user.setFirebaseUid("search-" + UUID.randomUUID());
        user.setEmail(UUID.randomUUID() + "@example.test");
        user.setUsername(username);
        user.setDisplayName(displayName);
        user.setIsPrivate(isPrivate);

        return users.saveAndFlush(user);
    }

    private String tokenFor(User user) {
        String token = "fixture-" + UUID.randomUUID();

        identities.put(
            token,
            new AuthenticatedFirebaseUser(
                user.getFirebaseUid(),
                user.getEmail(),
                user.getDisplayName(),
                true
            )
        );

        return token;
    }

    private HttpResponse<String> search(
        String query,
        String token
    ) throws Exception {
        String path = "/api/users/search";

        if (query != null) {
            path += "?q=" + URLEncoder.encode(
                query,
                StandardCharsets.UTF_8
            );
        }

        var request = HttpRequest.newBuilder(
                URI.create("http://127.0.0.1:" + port + path)
            )
            .GET();

        if (token != null) {
            request.header("Authorization", "Bearer " + token);
        }

        return client.send(
            request.build(),
            HttpResponse.BodyHandlers.ofString()
        );
    }

    private JsonNode data(
        HttpResponse<String> response,
        int expectedStatus
    ) {
        assertThat(response.statusCode())
            .as(response.body())
            .isEqualTo(expectedStatus);

        return json.readTree(response.body());
    }

    private boolean containsUsername(
        JsonNode results,
        String username
    ) {
        for (JsonNode result : results) {
            if (username.equals(result.get("username").asText())) {
                return true;
            }
        }

        return false;
    }

    @Test
    void findsUsersByPartialUsername() throws Exception {
        String suffix = UUID.randomUUID()
            .toString().replace("-", "").substring(0, 8);

        User visitor = createUser(
            "visitor_" + suffix, "Visitante", false
        );
        String username = "edu_" + suffix;

        createUser(username, "Eduardo", false);

        JsonNode results = data(
            search(username.substring(0, 7), tokenFor(visitor)),
            200
        );

        assertThat(containsUsername(results, username)).isTrue();
    }

    @Test
    void findsUsersByDisplayNameIgnoringCase() throws Exception {
        String unique = UUID.randomUUID()
            .toString().replace("-", "").substring(0, 8);

        User visitor = createUser(
            "visitor_" + unique, "Visitante", false
        );

        String username = "reader_" + unique;
        createUser(username, "Lector " + unique, false);

        JsonNode results = data(
            search(("LECTOR " + unique), tokenFor(visitor)),
            200
        );

        assertThat(containsUsername(results, username)).isTrue();
    }

    @Test
    void findsPrivateAndPublicProfiles() throws Exception {
        String unique = UUID.randomUUID()
            .toString().replace("-", "").substring(0, 8);

        User visitor = createUser(
            "visitor_" + unique, "Visitante", false
        );

        String publicUsername = "public_" + unique;
        String privateUsername = "private_" + unique;

        createUser(publicUsername, "Grupo " + unique, false);
        createUser(privateUsername, "Grupo " + unique, true);

        JsonNode results = data(
            search("Grupo " + unique, tokenFor(visitor)),
            200
        );

        assertThat(containsUsername(results, publicUsername)).isTrue();
        assertThat(containsUsername(results, privateUsername)).isTrue();
    }

    @Test
    void prioritizesExactUsername() throws Exception {
        String unique = UUID.randomUUID()
            .toString().replace("-", "").substring(0, 8);

        User visitor = createUser(
            "visitor_" + unique, "Visitante", false
        );

        String exact = "edu_" + unique;

        createUser("x" + exact, "Otro lector", false);
        createUser(exact, "Eduardo", false);

        JsonNode results = data(
            search(exact, tokenFor(visitor)),
            200
        );

        assertThat(results.get(0).get("username").asText())
            .isEqualTo(exact);
    }

    @Test
    void underscoreIsNotTreatedAsWildcard() throws Exception {
        String unique = UUID.randomUUID()
            .toString().replace("-", "").substring(0, 8);

        User visitor = createUser(
            "visitor_" + unique, "Visitante", false
        );

        String matching = "edu_" + unique;
        String notMatching = "edux" + unique;

        createUser(matching, "Coincidencia", false);
        createUser(notMatching, "Otra persona", false);

        JsonNode results = data(
            search("edu_" + unique, tokenFor(visitor)),
            200
        );

        assertThat(containsUsername(results, matching)).isTrue();
        assertThat(containsUsername(results, notMatching)).isFalse();
    }

    @Test
    void responseDoesNotExposePrivateFields() throws Exception {
        String unique = UUID.randomUUID()
            .toString().replace("-", "").substring(0, 8);

        User visitor = createUser(
            "visitor_" + unique, "Visitante", false
        );

        createUser(
            "reader_" + unique,
            "Nombre " + unique,
            true
        );

        JsonNode results = data(
            search("Nombre " + unique, tokenFor(visitor)),
            200
        );

        assertThat(results.isEmpty()).isFalse();

        JsonNode result = results.get(0);

        assertThat(result.has("displayName")).isTrue();
        assertThat(result.has("username")).isTrue();
        assertThat(result.has("avatarUrl")).isTrue();

        assertThat(result.has("email")).isFalse();
        assertThat(result.has("firebaseUid")).isFalse();
        assertThat(result.has("isPrivate")).isFalse();
        assertThat(result.has("biography")).isFalse();
    }

    @Test
    void limitsSearchResultsToTen() throws Exception {
        String unique = UUID.randomUUID()
            .toString().replace("-", "").substring(0, 8);

        User visitor = createUser(
            "visitor_" + unique, "Visitante", false
        );

        for (int index = 0; index < 15; index++) {
            createUser(
                "group_" + unique + "_" + index,
                "Grupo " + unique,
                false
            );
        }

        JsonNode results = data(
            search("Grupo " + unique, tokenFor(visitor)),
            200
        );

        assertThat(results.size()).isEqualTo(10);
    }

    @Test
    void emptyQueryReturnsEmptyResults() throws Exception {
        User visitor = createUser(
            "visitor_" + UUID.randomUUID()
                .toString().substring(0, 8),
            "Visitante",
            false
        );

        JsonNode results = data(
            search("", tokenFor(visitor)),
            200
        );

        assertThat(results.isEmpty()).isTrue();
    }

    @Test
    void unauthenticatedSearchIsRejected() throws Exception {
        HttpResponse<String> response = search("edu", null);

        assertThat(response.statusCode()).isEqualTo(401);
    }
}
