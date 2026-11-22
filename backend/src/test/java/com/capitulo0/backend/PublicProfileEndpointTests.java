
package com.capitulo0.backend;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import com.capitulo0.backend.auth.model.AuthenticatedFirebaseUser;
import com.capitulo0.backend.auth.service.FirebaseTokenVerifier;
import com.capitulo0.backend.catalog.book.entity.Book;
import com.capitulo0.backend.catalog.book.repository.BookRepository;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.repository.UserRepository;
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
class PublicProfileEndpointTests {

    @Value("${local.server.port}")
    int port;

    @MockitoBean
    FirebaseTokenVerifier verifier;

    @Autowired
    UserRepository users;

    @Autowired
    BookRepository books;

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

    private User createUser(boolean isPrivate) {
        User user = User.create();

        user.setFirebaseUid("profile-" + UUID.randomUUID());
        user.setEmail(UUID.randomUUID() + "@example.test");
        user.setUsername(
            "user_" + UUID.randomUUID()
                .toString().replace("-", "").substring(0, 20)
        );
        user.setDisplayName("Lector de prueba");
        user.setBiography("Me encanta leer.");
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

    private HttpResponse<String> request(
        String path,
        String token
    ) throws Exception {
        var builder = HttpRequest.newBuilder(
                URI.create("http://127.0.0.1:" + port + path)
            )
            .GET();

        if (token != null) {
            builder.header("Authorization", "Bearer " + token);
        }

        return client.send(
            builder.build(),
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

    @Test
    void publicProfileAllowsOtherAuthenticatedUsers()
        throws Exception {

        User owner = createUser(false);
        User visitor = createUser(false);

        var response = data(
            request(
                "/api/users/" + owner.getUsername(),
                tokenFor(visitor)
            ),
            200
        );

        assertThat(response.get("username").asText())
            .isEqualTo(owner.getUsername());
        assertThat(response.get("isPrivate").asBoolean())
            .isFalse();
        assertThat(response.get("canViewContent").asBoolean())
            .isTrue();
    }

    @Test
    void privateProfileRestrictsOtherUsers()
        throws Exception {

        User owner = createUser(true);
        User visitor = createUser(false);

        var response = data(
            request(
                "/api/users/" + owner.getUsername(),
                tokenFor(visitor)
            ),
            200
        );

        assertThat(response.get("isPrivate").asBoolean())
            .isTrue();
        assertThat(response.get("canViewContent").asBoolean())
            .isFalse();

        assertThat(response.get("displayName").asText())
            .isEqualTo(owner.getDisplayName());
        assertThat(response.get("biography").asText())
            .isEqualTo(owner.getBiography());
    }

    @Test
    void privateProfileAllowsItsOwner()
        throws Exception {

        User owner = createUser(true);

        var response = data(
            request(
                "/api/users/" + owner.getUsername(),
                tokenFor(owner)
            ),
            200
        );

        assertThat(response.get("isPrivate").asBoolean())
            .isTrue();
        assertThat(response.get("canViewContent").asBoolean())
            .isTrue();
    }

    @Test
    void profileNeverExposesPrivateIdentityFields()
        throws Exception {

        User owner = createUser(false);
        User visitor = createUser(false);

        var response = data(
            request(
                "/api/users/" + owner.getUsername(),
                tokenFor(visitor)
            ),
            200
        );

        assertThat(response.has("email")).isFalse();
        assertThat(response.has("firebaseUid")).isFalse();
    }

    @Test
    void profileCountsActualLibraryEntries()
        throws Exception {

        User owner = createUser(true);
        User visitor = createUser(false);

        Book first = Book.create();
        first.setTitle("Libro de prueba 1");
        first.setTotalPages(200);
        first = books.saveAndFlush(first);

        Book second = Book.create();
        second.setTitle("Libro de prueba 2");
        second.setTotalPages(300);
        second = books.saveAndFlush(second);

        String ownerToken = tokenFor(owner);

        var addFirst = HttpRequest.newBuilder(
                URI.create("http://127.0.0.1:" + port
                    + "/api/me/library")
            )
            .header("Authorization", "Bearer " + ownerToken)
            .header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(
                "{\"bookId\":" + first.getId() + "}"
            ))
            .build();

        var addSecond = HttpRequest.newBuilder(
                URI.create("http://127.0.0.1:" + port
                    + "/api/me/library")
            )
            .header("Authorization", "Bearer " + ownerToken)
            .header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(
                "{\"bookId\":" + second.getId() + "}"
            ))
            .build();

        assertThat(client.send(
            addFirst,
            HttpResponse.BodyHandlers.ofString()
        ).statusCode()).isEqualTo(201);

        assertThat(client.send(
            addSecond,
            HttpResponse.BodyHandlers.ofString()
        ).statusCode()).isEqualTo(201);

        var response = data(
            request(
                "/api/users/" + owner.getUsername(),
                tokenFor(visitor)
            ),
            200
        );

        assertThat(response.get("booksCount").asLong())
            .isEqualTo(2);
        assertThat(response.get("canViewContent").asBoolean())
            .isFalse();
    }

    @Test
    void nonexistentProfileReturns404()
        throws Exception {

        User visitor = createUser(false);

        var response = request(
            "/api/users/user_not_found_" + UUID.randomUUID()
                .toString().replace("-", "").substring(0, 10),
            tokenFor(visitor)
        );

        assertThat(response.statusCode()).isEqualTo(404);
    }

    @Test
    void unauthenticatedProfileRequestsAreRejected()
        throws Exception {

        User owner = createUser(false);

        var response = request(
            "/api/users/" + owner.getUsername(),
            null
        );

        assertThat(response.statusCode()).isEqualTo(401);
    }
}
