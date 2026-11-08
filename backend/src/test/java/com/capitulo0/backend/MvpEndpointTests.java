package com.capitulo0.backend;

import java.net.URI;
import java.net.http.*;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import com.capitulo0.backend.auth.model.AuthenticatedFirebaseUser;
import com.capitulo0.backend.auth.service.FirebaseTokenVerifier;
import com.capitulo0.backend.user.service.UserService;
import com.capitulo0.backend.user.repository.UserRepository;
import com.capitulo0.backend.user.dto.CreateUserRequest;
import com.capitulo0.backend.common.exception.ApiException;
import jakarta.validation.Validator;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;
import static org.mockito.ArgumentMatchers.anyString;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;
import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class MvpEndpointTests {
    @Value("${local.server.port}") int port;
    @MockitoBean FirebaseTokenVerifier verifier;
    @Autowired UserService users;
    @Autowired UserRepository userRepository;
    @Autowired Validator validator;
    private final java.util.Map<Long,String> identities = new java.util.HashMap<>();
    @BeforeEach void verifiedTokens() {
        when(verifier.verify(anyString())).thenAnswer(call ->
            new AuthenticatedFirebaseUser(call.getArgument(0), null, null));
    }
    private final HttpClient client = HttpClient.newHttpClient();
    private final JsonMapper json = JsonMapper.builder().build();
    private HttpResponse<String> call(String method, String path, String body) throws Exception {
        var owner = java.util.regex.Pattern.compile("^/api/users/([0-9]+)/library").matcher(path);
        String uid = owner.find() ? identities.getOrDefault(Long.parseLong(owner.group(1)), "unlinked-test") : "catalog-test";
        return client.send(HttpRequest.newBuilder(URI.create("http://127.0.0.1:" + port + path))
            .header("Content-Type", "application/json")
            .header("Authorization", "Bearer " + uid)
            .method(method, body == null ? HttpRequest.BodyPublishers.noBody() : HttpRequest.BodyPublishers.ofString(body))
            .build(), HttpResponse.BodyHandlers.ofString());
    }
    private JsonNode data(HttpResponse<String> response, int status) {
        assertThat(response.statusCode()).as(response.body()).isEqualTo(status);
        return json.readTree(response.body());
    }
    private long user() throws Exception {
        var created = users.create(new CreateUserRequest(UUID.randomUUID() + "@example.test", "Demo"));
        var entity = users.require(created.id());
        String uid = "mvp-" + UUID.randomUUID();
        entity.setFirebaseUid(uid);
        userRepository.saveAndFlush(entity);
        identities.put(created.id(), uid);
        return created.id();
    }
    private long book() throws Exception {
        return data(call("POST", "/api/books", "{\"title\":\"Libro demo\",\"author\":\"Autor\",\"totalPages\":300,\"publisher\":\"Editorial\"}"),201).get("id").asLong();
    }
    private String library(long user) { return "/api/users/" + user + "/library"; }
    private JsonNode add(long user, long book) throws Exception {
        return data(call("POST", library(user), "{\"bookId\":" + book + "}"),201);
    }
    @Test void rejectsDuplicateEmailIgnoringCase() throws Exception {
        String email = UUID.randomUUID() + "@example.test";
        var created = users.create(new CreateUserRequest(email, "Demo"));
        assertThatThrownBy(() -> users.create(new CreateUserRequest(email.toUpperCase(), "Demo")))
            .isInstanceOfSatisfying(ApiException.class,
                error -> assertThat(error.getStatus().value()).isEqualTo(409));
        assertThat(users.list()).extracting(response -> response.email()).contains(email);
        assertThat(created.id()).isPositive();
    }
    @Test void createsListsAndGetsBooks() throws Exception {
        long id = book();
        JsonNode result = data(call("GET", "/api/books/" + id, null),200);
        assertThat(result.get("title").asString()).isEqualTo("Libro demo");
        assertThat(result.get("publisher").asString()).isEqualTo("Editorial");
        assertThat(result.hasNonNull("createdAt")).isTrue();
        assertThat(data(call("GET", "/api/books", null),200).toString()).contains("Libro demo");
    }
    @Test void libraryRejectsDuplicatesAndDefaultsToUnread() throws Exception {
        long user=user(), book=book();
        JsonNode entry=add(user,book);
        assertThat(entry.get("status").asString()).isEqualTo("POR_LEER");
        assertThat(entry.get("currentPage").asInt()).isZero();
        assertThat(entry.get("totalPages").asInt()).isEqualTo(300);
        data(call("POST",library(user),"{\"bookId\":"+book+"}"),409);
        assertThat(data(call("GET",library(user),null),200).size()).isEqualTo(1);
    }
    @Test void updatesProgressAndPreservesOmittedTrackingFields() throws Exception {
        long user=user(), book=book(); add(user,book);
        String path=library(user)+"/"+book;
        JsonNode entry=data(call("PATCH",path,"{\"status\":\"LEYENDO\",\"readingFormat\":\"EBOOK\",\"currentPage\":100,\"totalPages\":300,\"publisherOverride\":\"Mi edición\"}"),200);
        assertThat(entry.get("progressPercentage").asDouble()).isEqualTo(33.33);
        entry=data(call("PATCH",path,"{\"status\":\"LEIDO\"}"),200);
        assertThat(entry.get("currentPage").asInt()).isEqualTo(300);
        assertThat(entry.get("progressPercentage").asDouble()).isEqualTo(100);
        assertThat(entry.get("readingFormat").asString()).isEqualTo("EBOOK");
        assertThat(entry.get("publisherOverride").asString()).isEqualTo("Mi edición");
        entry=data(call("PATCH",path,"{\"status\":\"POR_LEER\"}"),200);
        assertThat(entry.get("currentPage").asInt()).isZero();
        assertThat(entry.get("progressPercentage").asDouble()).isZero();
        entry=data(call("PATCH",path,"{\"status\":\"LEYENDO\",\"currentPage\":75}"),200);
        assertThat(entry.get("progressPercentage").asDouble()).isEqualTo(25);
    }
    @Test void deletesOnlyMembershipAndIsolatesUsers() throws Exception {
        long first=user(), second=user(), book=book(); add(first,book); add(second,book);
        data(call("PATCH",library(first)+"/"+book,"{\"status\":\"LEYENDO\",\"currentPage\":80}"),200);
        assertThat(data(call("GET",library(second),null),200).get(0).get("currentPage").asInt()).isZero();
        assertThat(call("DELETE",library(first)+"/"+book,null).statusCode()).isEqualTo(204);
        assertThat(data(call("GET",library(first),null),200).size()).isZero();
        assertThat(data(call("GET",library(second),null),200).size()).isEqualTo(1);
        data(call("GET","/api/books/"+book,null),200);
        data(call("PATCH",library(first)+"/"+book,"{\"status\":\"LEIDO\"}"),404);
    }
    @Test void cannotUpdateOrDeleteAnotherUsersEntry() throws Exception {
        long first=user(), second=user(), book=book(); add(first,book);
        data(call("PATCH",library(second)+"/"+book,"{\"status\":\"LEIDO\"}"),404);
        data(call("DELETE",library(second)+"/"+book,null),404);
        assertThat(data(call("GET",library(first),null),200).size()).isEqualTo(1);
    }
    @Test void rejectsInvalidPagesAndRollsBackUpdates() throws Exception {
        long user=user(), book=book(); add(user,book);
        for (String body : new String[]{"{\"currentPage\":-1}","{\"totalPages\":0}","{\"totalPages\":-5}",
            "{\"status\":\"LEYENDO\",\"currentPage\":301}","{\"status\":\"LEIDO\",\"currentPage\":301}"}) {
            data(call("PATCH",library(user)+"/"+book,body),400);
        }
        JsonNode entry=data(call("GET",library(user),null),200).get(0);
        assertThat(entry.get("status").asString()).isEqualTo("POR_LEER");
        assertThat(entry.get("currentPage").asInt()).isZero();
        assertThat(entry.get("totalPages").asInt()).isEqualTo(300);
    }
    @Test void validatesPagesWhenAdding() throws Exception {
        long user=user(), book=book();
        data(call("POST",library(user),"{\"bookId\":"+book+",\"currentPage\":-1}"),400);
        data(call("POST",library(user),"{\"bookId\":"+book+",\"totalPages\":0}"),400);
        data(call("POST",library(user),"{\"bookId\":"+book+",\"status\":\"LEYENDO\",\"currentPage\":301}"),400);
        assertThat(data(call("GET",library(user),null),200).size()).isZero();
    }
    @Test void normalizesUnreadAndReadPages() throws Exception {
        long user=user(), book=book();
        JsonNode entry=data(call("POST",library(user),"{\"bookId\":"+book+",\"status\":\"POR_LEER\",\"currentPage\":50}"),201);
        assertThat(entry.get("currentPage").asInt()).isZero();
        entry=data(call("PATCH",library(user)+"/"+book,"{\"status\":\"LEIDO\",\"currentPage\":10}"),200);
        assertThat(entry.get("currentPage").asInt()).isEqualTo(300);
    }
    @Test void supportsUnknownTotalWithoutInventingPages() throws Exception {
        long user=user();
        long book=data(call("POST","/api/books","{\"title\":\"Sin páginas\"}"),201).get("id").asLong();
        add(user,book);
        JsonNode entry=data(call("PATCH",library(user)+"/"+book,"{\"status\":\"LEYENDO\",\"currentPage\":10}"),200);
        assertThat(entry.get("totalPages").isNull()).isTrue();
        assertThat(entry.get("progressPercentage").asDouble()).isZero();
        entry=data(call("PATCH",library(user)+"/"+book,"{\"status\":\"LEIDO\"}"),200);
        assertThat(entry.get("currentPage").asInt()).isEqualTo(10);
        assertThat(entry.get("progressPercentage").asDouble()).isEqualTo(100);
    }
    @Test void reportsMissingResourcesAndInvalidInputsConsistently() throws Exception {
        data(call("GET","/api/books/9223372036854775807",null),404);
        data(call("GET","/api/users/9223372036854775807/library",null),404);
        long user=user();
        data(call("POST",library(user),"{\"bookId\":9223372036854775807}"),404);
        for (String email : new String[]{null, "bad", " "})
            assertThat(validator.validate(new CreateUserRequest(email, null))).isNotEmpty();
        for (String body : new String[]{"{}","{\"title\":\" \"}","{\"title\":\"Demo\",\"totalPages\":0}"})
            data(call("POST","/api/books",body),400);
        long book=book(); add(user,book);
        JsonNode error=data(call("PATCH",library(user)+"/"+book,"{\"status\":\"INVALIDO\"}"),400);
        assertThat(error.hasNonNull("message")).isTrue();
        assertThat(error.hasNonNull("timestamp")).isTrue();
        data(call("GET","/api/books/not-a-number",null),400);
    }
}
