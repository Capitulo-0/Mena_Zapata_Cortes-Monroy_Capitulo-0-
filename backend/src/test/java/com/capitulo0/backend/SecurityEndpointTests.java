package com.capitulo0.backend;

import java.net.URI;
import java.net.http.*;
import java.util.*;
import com.capitulo0.backend.auth.model.AuthenticatedFirebaseUser;
import com.capitulo0.backend.auth.service.FirebaseTokenVerifier;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.repository.UserRepository;
import com.capitulo0.backend.catalog.book.entity.Book;
import com.capitulo0.backend.catalog.book.repository.BookRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.AuthenticationServiceException;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class SecurityEndpointTests {
    @Value("${local.server.port}") int port;
    @MockitoBean FirebaseTokenVerifier verifier;
    @Autowired UserRepository users;
    @Autowired BookRepository books;
    private final HttpClient client = HttpClient.newHttpClient();
    private final JsonMapper json = JsonMapper.builder().build();
    private final Map<String, AuthenticatedFirebaseUser> tokens = new HashMap<>();

    @BeforeEach void tokens() {
        when(verifier.verify(anyString())).thenAnswer(call -> {
            String token = call.getArgument(0);
            if (token.equals("service-unavailable")) throw new AuthenticationServiceException("sensitive internal detail");
            var identity = tokens.get(token);
            if (identity == null) throw new BadCredentialsException("sensitive token detail");
            return identity;
        });
    }
    private User user() {
        User user = User.create();
        user.setEmail(UUID.randomUUID() + "@example.test");
        user.setDisplayName("Domain name");
        user.setFirebaseUid("uid-" + UUID.randomUUID());
        return users.saveAndFlush(user);
    }
    private String token(User user) {
        String token = "test-" + UUID.randomUUID();
        tokens.put(token, new AuthenticatedFirebaseUser(user.getFirebaseUid(), "different@example.test", "Token name"));
        return "Bearer " + token;
    }
    private long book() {
        Book book = Book.create(); book.setTitle("Security test book"); book.setTotalPages(100);
        return books.saveAndFlush(book).getId();
    }
    private HttpResponse<String> call(String method, String path, String authorization, String body) throws Exception {
        var request = HttpRequest.newBuilder(URI.create("http://127.0.0.1:" + port + path))
            .header("Content-Type", "application/json")
            .method(method, body == null ? HttpRequest.BodyPublishers.noBody() : HttpRequest.BodyPublishers.ofString(body));
        if (authorization != null) request.header("Authorization", authorization);
        return client.send(request.build(), HttpResponse.BodyHandlers.ofString());
    }
    private JsonNode data(HttpResponse<String> response, int status) {
        assertThat(response.statusCode()).as(response.body()).isEqualTo(status);
        return json.readTree(response.body());
    }
    @Test void healthAndCatalogArePublicAndIgnoreTokens() throws Exception {
        data(call("GET", "/api/health", null, null), 200);
        data(call("GET", "/api/books", null, null), 200);
        data(call("GET", "/api/books/" + book(), "Bearer invalid", null), 200);
        verifyNoInteractions(verifier);
    }
    @Test void protectedRoutesRejectMissingAndMalformedCredentials() throws Exception {
        for (String path : List.of("/api/me", "/api/me/library", "/api/users", "/api/users/1/library")) {
            var response = call("GET", path, null, null);
            JsonNode error = data(response, 401);
            assertThat(error.hasNonNull("timestamp")).isTrue();
            assertThat(error.has("details")).isTrue();
            assertThat(response.headers().firstValue("WWW-Authenticate")).hasValue("Bearer");
            assertThat(response.headers().firstValue("Set-Cookie")).isEmpty();
        }
        for (String authorization : List.of("Bearer", "Bearer ", "Basic abc", "Bearer one two", "Bearer a,b")) {
            data(call("GET", "/api/me", authorization, null), 401);
        }
        verifyNoInteractions(verifier);
    }
    @Test void invalidOrExpiredTokensHaveSanitized401() throws Exception {
        for (String token : List.of("invalid", "expired")) {
            var response = call("GET", "/api/me", "Bearer " + token, null);
            data(response, 401);
            assertThat(response.body()).doesNotContain("sensitive", "stackTrace", "private_key");
        }
    }
    @Test void unavailableIdentityServiceReturns503WithoutDetails() throws Exception {
        var response = call("GET", "/api/me", "Bearer service-unavailable", null);
        data(response, 503);
        assertThat(response.body()).doesNotContain("sensitive internal detail");
    }
    @Test void meUsesVerifiedUidNotClientSuppliedIdsOrEmail() throws Exception {
        User first = user(), second = user();
        String authorization = token(first);
        var response = call("GET", "/api/me?firebaseUid=" + second.getFirebaseUid() + "&userId=" + second.getId(),
            authorization, null);
        JsonNode result = data(response, 200);
        assertThat(result.get("id").asLong()).isEqualTo(first.getId());
        assertThat(result.get("email").asString()).isEqualTo(first.getEmail());
        assertThat(result.get("displayName").asString()).isEqualTo("Domain name");
        assertThat(result.has("firebaseUid")).isFalse();
        assertThat(result.has("firebase_uid")).isFalse();
        assertThat(response.headers().firstValue("Set-Cookie")).isEmpty();
        verify(verifier, times(1)).verify(authorization.substring(7));
        data(call("GET", "/api/me", null, null), 401); // no security context leaked to another request
    }
    @Test void unlinkedUidDoesNotAutoLinkByMatchingEmail() throws Exception {
        User legacy = User.create(); legacy.setEmail(UUID.randomUUID() + "@example.test");
        users.saveAndFlush(legacy);
        String raw = "unlinked-" + UUID.randomUUID();
        tokens.put(raw, new AuthenticatedFirebaseUser("new-uid", legacy.getEmail(), "Not linked"));
        data(call("GET", "/api/me", "Bearer " + raw, null), 404);
        assertThat(users.findById(legacy.getId()).orElseThrow().getFirebaseUid()).isNull();
        assertThat(users.existsByFirebaseUid("new-uid")).isFalse();
    }
    @Test void legacyUserManagementIsDisabledEvenForValidIdentity() throws Exception {
        String authorization = token(user());
        data(call("GET", "/api/users", authorization, null), 403);
        data(call("POST", "/api/users", authorization,
            "{\"email\":\"spoof@example.test\",\"firebase_uid\":\"spoof\"}"), 403);
        assertThat(users.existsByEmailIgnoreCase("spoof@example.test")).isFalse();
        data(call("POST", "/api/users", null, "{}"), 401);
    }
    @Test void ownLibraryWorksAndLegacyPathCannotBeUsedToAccessAnotherUser() throws Exception {
        User first = user(), second = user();
        String authFirst = token(first), authSecond = token(second);
        long book = book();
        JsonNode entry = data(call("POST", "/api/me/library?userId=" + second.getId(), authFirst,
            "{\"bookId\":" + book + ",\"firebaseUid\":\"" + second.getFirebaseUid() + "\",\"userId\":" + second.getId() + "}"), 201);
        assertThat(entry.get("userId").asLong()).isEqualTo(first.getId());
        assertThat(data(call("GET", "/api/me/library", authSecond, null), 200).size()).isZero();
        String otherPath = "/api/users/" + first.getId() + "/library";
        for (String method : List.of("GET", "POST", "PATCH", "DELETE")) {
            String path = method.equals("PATCH") || method.equals("DELETE") ? otherPath + "/" + book : otherPath;
            String body = method.equals("POST") ? "{\"bookId\":" + book + "}" : method.equals("PATCH") ? "{\"currentPage\":50}" : null;
            data(call(method, path, authSecond, body), 403);
        }
        data(call("PATCH", otherPath + "/" + book, authFirst,
            "{\"status\":\"LEYENDO\",\"currentPage\":25}"), 200);
        assertThat(data(call("GET", "/api/me/library", authFirst, null), 200).get(0).get("currentPage").asInt()).isEqualTo(25);
        data(call("PATCH", "/api/me/library/" + book, authFirst, "{\"status\":\"LEIDO\"}"), 200);
        assertThat(call("DELETE", "/api/me/library/" + book, authFirst, null).statusCode()).isEqualTo(204);
        assertThat(data(call("GET", otherPath, authFirst, null), 200).size()).isZero();
    }
    @Test void bookCreationRequiresToken() throws Exception {
        data(call("POST", "/api/books", null, "{\"title\":\"Book\"}"), 401);
        data(call("POST", "/api/books", token(user()), "{\"title\":\"Book\"}"), 201);
    }
}
