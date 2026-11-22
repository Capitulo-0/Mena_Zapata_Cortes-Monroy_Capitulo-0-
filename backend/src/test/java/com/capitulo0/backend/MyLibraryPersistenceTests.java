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
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class MyLibraryPersistenceTests {
    @Value("${local.server.port}") int port;
    @MockitoBean FirebaseTokenVerifier verifier;
    @Autowired UserRepository users;
    @Autowired BookRepository books;
    final HttpClient client = HttpClient.newHttpClient();
    final JsonMapper json = JsonMapper.builder().build();
    final Map<String, AuthenticatedFirebaseUser> identities = new HashMap<>();
    @BeforeEach void tokens() {
        when(verifier.verify(anyString())).thenAnswer(call -> {
            var identity = identities.get(call.getArgument(0));
            if (identity == null) throw new BadCredentialsException("fixture-only");
            return identity;
        });
    }
    String account() {
        var user = User.create();
        user.setEmail(UUID.randomUUID() + "@example.test");
        user.setFirebaseUid("library-" + UUID.randomUUID());
        users.saveAndFlush(user);
        String token = "fixture-" + UUID.randomUUID();
        identities.put(token, new AuthenticatedFirebaseUser(user.getFirebaseUid(), user.getEmail(), "Fixture", true));
        return token;
    }
    long book() {
        var book = Book.create(); book.setTitle("Library contract fixture"); book.setTotalPages(300);
        return books.saveAndFlush(book).getId();
    }
    HttpResponse<String> request(String method, String path, String token, String body) throws Exception {
        var request = HttpRequest.newBuilder(URI.create("http://127.0.0.1:" + port + path))
            .header("Content-Type", "application/json")
            .method(method, body == null ? HttpRequest.BodyPublishers.noBody() : HttpRequest.BodyPublishers.ofString(body));
        if (token != null) request.header("Authorization", "Bearer " + token);
        return client.send(request.build(), HttpResponse.BodyHandlers.ofString());
    }
    JsonNode data(HttpResponse<String> response, int status) {
        assertThat(response.statusCode()).as(response.body()).isEqualTo(status);
        return json.readTree(response.body());
    }
    @Test void addUpdateAndFreshGetRecoverPagesFormatAndPublisher() throws Exception {
        String token = account(); long book = book();
        data(request("POST", "/api/me/library", token, "{\"bookId\":" + book + "}"), 201);
        data(request("PATCH", "/api/me/library/" + book, token,
            "{\"status\":\"LEYENDO\",\"readingFormat\":\"EBOOK\",\"currentPage\":73,\"totalPages\":300,\"publisherOverride\":\"Personal edition\"}"), 200);
        var restored = data(request("GET", "/api/me/library", token, null), 200).get(0);
        assertThat(restored.get("book").get("id").asLong()).isEqualTo(book);
        assertThat(restored.get("currentPage").asInt()).isEqualTo(73);
        assertThat(restored.get("readingFormat").asText()).isEqualTo("EBOOK");
        assertThat(restored.get("publisherOverride").asText()).isEqualTo("Personal edition");
        assertThat(restored.get("progressPercentage").asDouble()).isEqualTo(24.33);
    }
    @Test void twoUsersHaveIndependentMembershipAndCannotEditEachOthersEntry() throws Exception {
        String first = account(), second = account(); long book = book();
        data(request("POST", "/api/me/library", first, "{\"bookId\":" + book + "}"), 201);
        assertThat(data(request("GET", "/api/me/library", second, null), 200).isEmpty()).isTrue();
        data(request("PATCH", "/api/me/library/" + book, second, "{\"status\":\"LEIDO\"}"), 404);
        assertThat(request("DELETE", "/api/me/library/" + book, second, null).statusCode()).isEqualTo(404);
        assertThat(data(request("GET", "/api/me/library", first, null), 200).get(0).get("status").asText()).isEqualTo("POR_LEER");
        data(request("POST", "/api/me/library", second, "{\"bookId\":" + book + "}"), 201);
        data(request("PATCH", "/api/me/library/" + book, second, "{\"currentPage\":25,\"status\":\"LEYENDO\"}"), 200);
        assertThat(data(request("GET", "/api/me/library", first, null), 200).get(0).get("currentPage").asInt()).isZero();
    }
    @Test void deleteOnlyRemovesOwnMembershipAndCatalogSurvives() throws Exception {
        String token = account(); long book = book();
        data(request("POST", "/api/me/library", token, "{\"bookId\":" + book + "}"), 201);
        assertThat(request("DELETE", "/api/me/library/" + book, token, null).statusCode()).isEqualTo(204);
        assertThat(data(request("GET", "/api/me/library", token, null), 200).isEmpty()).isTrue();
        assertThat(books.findById(book)).isPresent();
        data(request("GET", "/api/books/" + book, null, null), 200);
    }
    @Test void ignoresClientIdentitySelectorsAndRejectsGuestWrites() throws Exception {
        String token = account(); long book = book();
        data(request("POST", "/api/me/library?userId=999&firebaseUid=untrusted", token,
            "{\"bookId\":" + book + ",\"userId\":999,\"firebaseUid\":\"untrusted\"}"), 201);
        for (String method : List.of("GET", "POST", "PATCH", "DELETE")) {
            String path = (method.equals("PATCH") || method.equals("DELETE")) ? "/api/me/library/" + book : "/api/me/library";
            assertThat(request(method, path, null, method.equals("POST") ? "{\"bookId\":" + book + "}" : null).statusCode()).isEqualTo(401);
        }
    }
    @Test void invalidPagesRollBackAndUnknownTotalIsNotInvented() throws Exception {
        String token = account(); long book = book();
        data(request("POST", "/api/me/library", token, "{\"bookId\":" + book + "}"), 201);
        data(request("PATCH", "/api/me/library/" + book, token, "{\"currentPage\":301}"), 400);
        assertThat(data(request("GET", "/api/me/library", token, null), 200).get(0).get("currentPage").asInt()).isZero();
        var unknown = Book.create(); unknown.setTitle("Unknown total fixture"); long unknownId = books.saveAndFlush(unknown).getId();
        var entry = data(request("POST", "/api/me/library", token, "{\"bookId\":" + unknownId + "}"), 201);
        assertThat(entry.get("totalPages").isNull()).isTrue();
        assertThat(entry.get("currentPage").asInt()).isZero();
    }
}
