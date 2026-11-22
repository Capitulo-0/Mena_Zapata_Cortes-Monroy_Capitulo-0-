package com.capitulo0.backend;
import com.capitulo0.backend.integration.googlebooks.*;
import com.capitulo0.backend.auth.model.AuthenticatedFirebaseUser;
import com.capitulo0.backend.auth.service.FirebaseTokenVerifier;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.repository.UserRepository;
import com.capitulo0.backend.catalog.book.repository.BookRepository;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.*;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import java.net.*; import java.net.http.*; import java.util.*;
import tools.jackson.databind.json.JsonMapper;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.*;
@SpringBootTest(webEnvironment=SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class GoogleBooksEndpointTests {
    @Value("${local.server.port}") int port;
    @MockitoBean GoogleBooksClient google;
    @MockitoBean FirebaseTokenVerifier verifier;
    @Autowired UserRepository users;
    @Autowired BookRepository books;
    @Autowired GoogleBooksImportService importer;
    final JsonMapper json=JsonMapper.builder().build();
    final HttpClient http=HttpClient.newHttpClient();
    @BeforeEach void fixtures() {
        when(google.volume(anyString())).thenAnswer(call -> json.readTree("{\"id\":\""+call.getArgument(0)+"\",\"volumeInfo\":{\"title\":\"Fixture\",\"authors\":[\"One\",\"Two\"],\"language\":\"es\",\"publishedDate\":\"2001-02\",\"pageCount\":300}}"));
        when(google.search(anyString(),anyInt(),anyInt(),anyString())).thenReturn(json.readTree("{\"totalItems\":0}"));
    }
    String account() {
        var u=User.create(); u.setEmail(UUID.randomUUID()+"@example.test");u.setFirebaseUid(UUID.randomUUID().toString());users.saveAndFlush(u);
        String token="fixture-"+UUID.randomUUID();
        when(verifier.verify(token)).thenReturn(new AuthenticatedFirebaseUser(u.getFirebaseUid(),u.getEmail(),"Fixture",true));
        return token;
    }
    HttpResponse<String> call(String method,String path,String token,String body) throws Exception {
        var b=HttpRequest.newBuilder(URI.create("http://127.0.0.1:"+port+path)).header("Content-Type","application/json")
            .method(method,body==null?HttpRequest.BodyPublishers.noBody():HttpRequest.BodyPublishers.ofString(body));
        if(token!=null)b.header("Authorization","Bearer "+token);
        return http.send(b.build(),HttpResponse.BodyHandlers.ofString());
    }
    @Test void publicReadDoesNotPersistAndInvalidQueriesAre400() throws Exception {
        long count=books.count();
        assertThat(call("GET","/api/catalog/search?q=fixture",null,null).statusCode()).isEqualTo(200);
        assertThat(call("GET","/api/catalog/google-books/readfixture",null,null).statusCode()).isEqualTo(200);
        assertThat(call("GET","/api/catalog/search?q=x&maxResults=41",null,null).statusCode()).isEqualTo(400);
        assertThat(books.count()).isEqualTo(count);
        assertThat(call("POST","/api/books/import/google-books",null,"{\"volumeId\":\"x\"}").statusCode()).isEqualTo(401);
    }
    @Test void importIsIdempotentAndProgressIsPrivate() throws Exception {
        var a=account(); var b=account(); var id="fixture_"+UUID.randomUUID();
        String body="{\"volumeId\":\""+id+"\",\"userId\":0}";
        var first=call("POST","/api/books/import/google-books",a,body);
        assertThat(first.statusCode()).isEqualTo(200);
        long book=json.readTree(first.body()).path("id").asLong();
        assertThat(json.readTree(first.body()).path("googleBooks").path("authors").size()).isEqualTo(2);
        assertThat(json.readTree(call("POST","/api/books/import/google-books",b,body).body()).path("id").asLong()).isEqualTo(book);
        verify(google,times(1)).volume(id);
        assertThat(call("POST","/api/me/library",a,"{\"bookId\":"+book+"}").statusCode()).isEqualTo(201);
        assertThat(call("POST","/api/me/library",b,"{\"bookId\":"+book+"}").statusCode()).isEqualTo(201);
        assertThat(call("PATCH","/api/me/library/"+book,a,"{\"status\":\"LEYENDO\",\"currentPage\":73}").statusCode()).isEqualTo(200);
        var entries=json.readTree(call("GET","/api/me/library",b,null).body());
        var own=java.util.stream.StreamSupport.stream(entries.spliterator(),false).filter(e -> e.path("book").path("id").asLong()==book).findFirst().orElseThrow();
        assertThat(own.path("currentPage").asInt()).isZero();
        assertThat(call("DELETE","/api/me/library/"+book,a,null).statusCode()).isEqualTo(204);
        assertThat(books.findById(book)).isPresent();
    }
    @Test void concurrentImportsReuseUniqueReference() throws Exception {
        String id="race_"+UUID.randomUUID();
        try(var pool=java.util.concurrent.Executors.newFixedThreadPool(2)) {
            var one=pool.submit(() -> importer.resolve(id));
            var two=pool.submit(() -> importer.resolve(id));
            assertThat(one.get().id()).isEqualTo(two.get().id());
        }
        assertThat(books.findByGoogleVolumeId(id)).isPresent();
    }
}
