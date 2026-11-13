
package com.capitulo0.backend;

import java.net.URI;
import java.net.http.*;
import java.util.*;
import java.util.concurrent.*;

import com.capitulo0.backend.auth.model.AuthenticatedFirebaseUser;
import com.capitulo0.backend.auth.service.FirebaseTokenVerifier;
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

import tools.jackson.databind.json.JsonMapper;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class ProvisioningEndpointTests {

    @Value("${local.server.port}")
    int port;

    @MockitoBean
    FirebaseTokenVerifier verifier;

    @Autowired
    UserRepository users;

    final HttpClient client = HttpClient.newHttpClient();
    final JsonMapper json = JsonMapper.builder().build();

    final Map<String, AuthenticatedFirebaseUser> identities =
        new ConcurrentHashMap<>();

    @BeforeEach
    void configureVerifier() {
        identities.clear();

        when(verifier.verify(anyString())).thenAnswer(call -> {
            var identity = identities.get(call.getArgument(0));

            if (identity == null) {
                throw new BadCredentialsException("Invalid test token");
            }

            return identity;
        });
    }

    String email() {
        return UUID.randomUUID() + "@example.test";
    }

    String username() {
        return "user_" + UUID.randomUUID()
            .toString()
            .replace("-", "")
            .substring(0, 20);
    }

    String token(String uid, String email, boolean verified) {
        String raw = "fixture-" + UUID.randomUUID();

        identities.put(
            raw,
            new AuthenticatedFirebaseUser(
                uid,
                email,
                "Verified name",
                verified
            )
        );

        return raw;
    }

    HttpResponse<String> call(
        String method,
        String path,
        String token,
        String body
    ) throws Exception {
        var request = HttpRequest.newBuilder(
                URI.create("http://127.0.0.1:" + port + path)
            )
            .header("Content-Type", "application/json")
            .method(
                method,
                body == null
                    ? HttpRequest.BodyPublishers.noBody()
                    : HttpRequest.BodyPublishers.ofString(body)
            );

        if (token != null) {
            request.header("Authorization", "Bearer " + token);
        }

        return client.send(
            request.build(),
            HttpResponse.BodyHandlers.ofString()
        );
    }

    HttpResponse<String> provision(String token) throws Exception {
        return call(
            "POST",
            "/api/me/provision",
            token,
            null
        );
    }

    HttpResponse<String> provision(
        String token,
        String username
    ) throws Exception {
        return call(
            "POST",
            "/api/me/provision",
            token,
            "{\"username\":\"" + username + "\"}"
        );
    }

    @Test
    void createsFromVerifiedClaimsAndMeWorksWithoutExposingUid()
            throws Exception {

        String uid = UUID.randomUUID().toString();
        String email = email();
        String selectedUsername = username();

        String raw = token(
            uid,
            "  " + email.toUpperCase(Locale.ROOT) + "  ",
            true
        );

        var created = provision(raw, selectedUsername);

        assertThat(created.statusCode())
            .as(created.body())
            .isEqualTo(200);

        var me = call("GET", "/api/me", raw, null);

        assertThat(me.statusCode()).isEqualTo(200);

        var profile = json.readTree(me.body());

        assertThat(profile.get("email").asText())
            .isEqualTo(email);

        assertThat(profile.get("displayName").asText())
            .isEqualTo("Verified name");

        assertThat(profile.get("username").asText())
            .isEqualTo(selectedUsername);

        assertThat(me.body())
            .doesNotContain("firebaseUid", "firebase_uid", uid);

        assertThat(users.findByFirebaseUid(uid)).isPresent();
    }

    @Test
    void repeatedProvisionIsIdempotentAndDoesNotOverwriteDomainData()
            throws Exception {

        String uid = UUID.randomUUID().toString();
        String raw = token(uid, email(), true);
        String selectedUsername = username();

        var firstResponse = provision(raw, selectedUsername);

        assertThat(firstResponse.statusCode())
            .as(firstResponse.body())
            .isEqualTo(200);

        var first = json.readTree(firstResponse.body());

        String secondToken = token(uid, null, false);

        var second = provision(secondToken);

        assertThat(second.statusCode()).isEqualTo(200);

        var result = json.readTree(second.body());

        assertThat(result.get("id")).isEqualTo(first.get("id"));
        assertThat(result.get("email")).isEqualTo(first.get("email"));
        assertThat(result.get("username"))
            .isEqualTo(first.get("username"));
    }

    @Test
    void bodyQueryAndPathCannotChooseIdentity() throws Exception {

        String uid = UUID.randomUUID().toString();
        String otherUid = UUID.randomUUID().toString();
        String raw = token(uid, email(), true);
        String selectedUsername = username();

        var response = call(
            "POST",
            "/api/me/provision?firebaseUid=" + otherUid + "&userId=999",
            raw,
            "{\"firebaseUid\":\"" + otherUid + "\","
                + "\"email\":\"attacker@example.test\","
                + "\"displayName\":\"Attacker\","
                + "\"userId\":999,"
                + "\"username\":\"" + selectedUsername + "\"}"
        );

        assertThat(response.statusCode())
            .as(response.body())
            .isEqualTo(200);

        assertThat(users.findByFirebaseUid(otherUid)).isEmpty();

        User actual = users.findByFirebaseUid(uid).orElseThrow();

        assertThat(actual.getDisplayName())
            .isEqualTo("Verified name");

        assertThat(actual.getUsername())
            .isEqualTo(selectedUsername);

        var me = call(
            "GET",
            "/api/me?firebaseUid=" + otherUid + "&userId=999",
            raw,
            null
        );

        assertThat(json.readTree(me.body()).get("id"))
            .isEqualTo(json.readTree(response.body()).get("id"));
    }

    @Test
    void missingEmailIsControlledAndDoesNotCreateUser()
            throws Exception {

        String uid = UUID.randomUUID().toString();

        assertThat(
            provision(
                token(uid, null, true),
                username()
            ).statusCode()
        ).isEqualTo(400);

        assertThat(users.findByFirebaseUid(uid)).isEmpty();
    }

    @Test
    void unverifiedOrInvalidEmailIsRejected() throws Exception {

        assertThat(
            provision(
                token(UUID.randomUUID().toString(), email(), false),
                username()
            ).statusCode()
        ).isEqualTo(400);

        assertThat(
            provision(
                token(UUID.randomUUID().toString(), "invalid-email", true),
                username()
            ).statusCode()
        ).isEqualTo(400);

        assertThat(
            provision(
                token(
                    UUID.randomUUID().toString(),
                    "x".repeat(321) + "@example.test",
                    true
                ),
                username()
            ).statusCode()
        ).isEqualTo(400);
    }

    @Test
    void legacyEmailIsNeverAutoLinked() throws Exception {

        User legacy = User.create();
        legacy.setEmail(email());

        users.saveAndFlush(legacy);

        String uid = UUID.randomUUID().toString();

        var response = provision(
            token(uid, legacy.getEmail(), true),
            username()
        );

        assertThat(response.statusCode()).isEqualTo(409);

        assertThat(
            users.findById(legacy.getId())
                .orElseThrow()
                .getFirebaseUid()
        ).isNull();

        assertThat(users.findByFirebaseUid(uid)).isEmpty();
    }

    @Test
    void differentUidCannotTakeOverAnEmail() throws Exception {

        String email = email();
        String uid = UUID.randomUUID().toString();
        String other = UUID.randomUUID().toString();

        assertThat(
            provision(
                token(uid, email, true),
                username()
            ).statusCode()
        ).isEqualTo(200);

        assertThat(
            provision(
                token(other, email, true),
                username()
            ).statusCode()
        ).isEqualTo(409);

        assertThat(users.findByFirebaseUid(other)).isEmpty();

        assertThat(
            users.findByFirebaseUid(uid)
                .orElseThrow()
                .getEmail()
        ).isEqualTo(email);
    }

    @Test
    void provisioningRequiresAuthenticationAndLegacyUsersRemainBlocked()
            throws Exception {

        assertThat(provision(null).statusCode()).isEqualTo(401);
        assertThat(provision("invalid").statusCode()).isEqualTo(401);

        String raw = token(
            UUID.randomUUID().toString(),
            email(),
            true
        );

        assertThat(
            call(
                "POST",
                "/api/users",
                raw,
                "{\"email\":\"untrusted@example.test\"}"
            ).statusCode()
        ).isEqualTo(403);

        assertThat(
            call("GET", "/api/users", raw, null).statusCode()
        ).isEqualTo(403);
    }

    @Test
    void concurrentSameUidRequestsReturnOneInternalId()
            throws Exception {

        String uid = UUID.randomUUID().toString();
        String raw = token(uid, email(), true);
        String selectedUsername = username();

        var start = new CountDownLatch(1);

        try (var executor = Executors.newFixedThreadPool(6)) {

            var futures =
                new ArrayList<Future<HttpResponse<String>>>();

            for (int i = 0; i < 6; i++) {
                futures.add(executor.submit(() -> {
                    start.await();
                    return provision(raw, selectedUsername);
                }));
            }

            start.countDown();

            Set<Long> ids = new HashSet<>();

            for (var future : futures) {
                var response = future.get(30, TimeUnit.SECONDS);

                assertThat(response.statusCode())
                    .as(response.body())
                    .isEqualTo(200);

                ids.add(
                    json.readTree(response.body())
                        .get("id")
                        .asLong()
                );
            }

            assertThat(ids).hasSize(1);
        }
    }

    @Test
    void concurrentDifferentUidsWithSameEmailCannotLink()
            throws Exception {

        String email = email();

        String first = token(
            UUID.randomUUID().toString(),
            email,
            true
        );

        String second = token(
            UUID.randomUUID().toString(),
            email,
            true
        );

        var start = new CountDownLatch(1);

        try (var executor = Executors.newFixedThreadPool(2)) {

            var a = executor.submit(() -> {
                start.await();
                return provision(first, username()).statusCode();
            });

            var b = executor.submit(() -> {
                start.await();
                return provision(second, username()).statusCode();
            });

            start.countDown();

            assertThat(
                List.of(
                    a.get(30, TimeUnit.SECONDS),
                    b.get(30, TimeUnit.SECONDS)
                )
            ).containsExactlyInAnyOrder(200, 409);
        }
    }

    @Test
    void newAccountWithoutUsernameIsRejected() throws Exception {

        String uid = UUID.randomUUID().toString();
        String raw = token(uid, email(), true);

        var response = provision(raw);

        assertThat(response.statusCode()).isEqualTo(400);

        assertThat(
            json.readTree(response.body())
                .get("code")
                .asText()
        ).isEqualTo("USERNAME_REQUIRED");

        assertThat(users.findByFirebaseUid(uid)).isEmpty();
    }

    @Test
    void duplicatedUsernameReturnsSpecificConflict() throws Exception {

        String selectedUsername = username();

        String firstUid = UUID.randomUUID().toString();
        String secondUid = UUID.randomUUID().toString();

        String firstToken = token(firstUid, email(), true);
        String secondToken = token(secondUid, email(), true);

        assertThat(
            provision(firstToken, selectedUsername).statusCode()
        ).isEqualTo(200);

        var response = provision(secondToken, selectedUsername);

        assertThat(response.statusCode()).isEqualTo(409);

        assertThat(
            json.readTree(response.body())
                .get("code")
                .asText()
        ).isEqualTo("USERNAME_TAKEN");

        assertThat(users.findByFirebaseUid(secondUid)).isEmpty();
    }

    @Test
    void invalidUsernameIsRejected() throws Exception {

        String uid = UUID.randomUUID().toString();
        String raw = token(uid, email(), true);

        var response = provision(raw, "Usuario Invalido!");

        assertThat(response.statusCode()).isEqualTo(400);

        assertThat(users.findByFirebaseUid(uid)).isEmpty();
    }
}
