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

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties={"spring.flyway.enabled=false", "spring.jpa.hibernate.ddl-auto=create-drop", "app.cors.allowed-origins=http://localhost:7357"})
@ActiveProfiles("test")
class WriterPersistenceTests {
    @Value("${local.server.port}") int port;
    @MockitoBean FirebaseTokenVerifier verifier;
    @Autowired UserRepository users;
    @Autowired com.capitulo0.backend.writer.WriterStoryRepository stories;
    @org.junit.jupiter.api.AfterEach void cleanup(){ stories.deleteAll(); }
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
        user.setDisplayName("Autora de prueba");
        user.setUsername("autor"+UUID.randomUUID().toString().substring(0,8));
        user.setFirebaseUid("library-" + UUID.randomUUID());
        users.saveAndFlush(user);
        String token = "fixture-" + UUID.randomUUID();
        identities.put(token, new AuthenticatedFirebaseUser(user.getFirebaseUid(), user.getEmail(), "Fixture", true));
        return token;
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
    String path(String id){return "/api/me/writer/stories/"+id;}
    String draft(String id,long revision,String title,String content){
        var chapter=Map.of("id","chapter-1","title","Capitulo uno","content",content,"order",1,"isPublished",false,"createdAt","2026-11-17T03:00:00Z","updatedAt","2026-11-17T03:00:00Z");
        return json.writeValueAsString(Map.of("id",id,"title",title,"synopsis","Texto original de prueba","genre","Cuento","status","draft","chapters",List.of(chapter),"revision",revision,"createdAt","2026-11-17T03:00:00Z","updatedAt","2026-11-17T03:00:00Z"));
    }
    @Test void createFreshGetEditPublishReadAndDeletePersistAcrossRequests() throws Exception {
        String a=account(),b=account(),id=UUID.randomUUID().toString();
        var created=data(request("POST",path(id),a,draft(id,0,"La casa de papel","Contenido original completo")),200);
        assertThat(created.get("chapters").get(0).get("content").asText()).isEqualTo("Contenido original completo");
        assertThat(created.get("createdAt").isTextual()).isTrue();
        long version=created.get("revision").asLong();
        var loaded=data(request("GET",path(id),a,null),200);
        assertThat(loaded.get("title").asText()).isEqualTo("La casa de papel");
        assertThat(data(request("GET","/api/me/writer/stories",a,null),200).size()).isEqualTo(1);
        var edited=data(request("POST",path(id),a,draft(id,version,"Titulo corregido","Capitulo editado sin perder texto")),200);
        assertThat(edited.get("revision").asLong()).isGreaterThan(version);
        var published=data(request("POST",path(id)+"/publication",a,json.writeValueAsString(Map.of("revision",edited.get("revision").asLong(),"published",true))),200);
        assertThat(published.get("status").asText()).isEqualTo("published");
        assertThat(published.get("chapters").get(0).get("isPublished").asBoolean()).isTrue();
        assertThat(data(request("GET","/api/writer/stories/"+id,b,null),200).get("chapters").get(0).get("content").asText()).isEqualTo("Capitulo editado sin perder texto");
        var withdrawn=data(request("POST",path(id)+"/publication",a,json.writeValueAsString(Map.of("revision",published.get("revision").asLong(),"published",false))),200);
        assertThat(withdrawn.get("status").asText()).isEqualTo("draft");
        data(request("GET","/api/writer/stories/"+id,b,null),404);
        assertThat(request("DELETE",path(id)+"?revision="+withdrawn.get("revision").asLong(),a,null).statusCode()).isEqualTo(204);
        data(request("GET",path(id),a,null),404);
        assertThat(data(request("GET","/api/me/writer/stories",a,null),200).isEmpty()).isTrue();
    }
    @Test void foreignUserCannotReadDraftUpdatePublishOrDelete() throws Exception {
        String a=account(),b=account(),id=UUID.randomUUID().toString();
        data(request("POST",path(id),a,draft(id,0,"Privada","Solo contenido de A")),200);
        assertThat(data(request("GET","/api/me/writer/stories",b,null),200).isEmpty()).isTrue();
        data(request("GET",path(id),b,null),404);
        data(request("GET","/api/writer/stories/"+id,b,null),404);
        data(request("POST",path(id),b,draft(id,0,"Intrusion","No autorizado")),404);
        data(request("POST",path(id)+"/publication",b,"{\"revision\":0,\"published\":true}"),404);
        data(request("DELETE",path(id)+"?revision=0",b,null),404);
        assertThat(data(request("GET",path(id),a,null),200).get("title").asText()).isEqualTo("Privada");
    }
    @Test void staleAggregateCannotEraseSavedChaptersAndValidationRollsBack() throws Exception {
        String a=account(),id=UUID.randomUUID().toString();
        var initial=data(request("POST",path(id),a,draft(id,0,"Borrador","Version primera")),200);
        long v=initial.get("revision").asLong();
        var changed=data(request("POST",path(id),a,draft(id,v,"Borrador editado","Version nueva")),200);
        data(request("POST",path(id),a,draft(id,v,"Obsoleto","Texto obsoleto")),409);
        assertThat(data(request("GET",path(id),a,null),200).get("chapters").get(0).get("content").asText()).isEqualTo("Version nueva");
        data(request("DELETE",path(id)+"?revision="+v,a,null),409);
        data(request("POST",path(id),a,draft(id,changed.get("revision").asLong()," ","No guardar")),400);
        assertThat(data(request("GET",path(id),a,null),200).get("title").asText()).isEqualTo("Borrador editado");
    }
    @Test void cannotPublishEmptyChaptersAndRejectsGuests() throws Exception {
        String a=account(),id=UUID.randomUUID().toString();
        data(request("POST",path(id),a,draft(id,0,"Sin terminar","")),200);
        data(request("POST",path(id)+"/publication",a,"{\"revision\":0,\"published\":true}"),400);
        assertThat(data(request("GET",path(id),a,null),200).get("status").asText()).isEqualTo("draft");
        for(var method:List.of("GET","POST","DELETE"))
            assertThat(request(method,path(id)+(method.equals("DELETE")?"?revision=0":""),null,method.equals("POST")?draft(id,0,"Invitado","No guardar"):null).statusCode()).isEqualTo(401);
        assertThat(request("POST",path(id)+"/publication",null,"{}").statusCode()).isEqualTo(401);
    }
    @Test void twoOrderedChaptersSurviveMetadataEditsAndFreshReads() throws Exception {
        String a=account(),id=UUID.randomUUID().toString();
        var saved=data(request("POST",path(id),a,draft(id,0,"Dos capitulos","Primero")),200);
        var body=json.readValue(draft(id,saved.get("revision").asLong(),"Dos capitulos","Primero"),Map.class);
        var first=((List<?>)body.get("chapters")).get(0);
        var second=Map.of("id","chapter-2","title","Segundo","content","Contenido segundo","order",2,"isPublished",false);
        body.put("chapters",List.of(first,second));
        var chapters=data(request("POST",path(id),a,json.writeValueAsString(body)),200);
        body.put("title","Metadata corregida");body.put("revision",chapters.get("revision").asLong());
        data(request("POST",path(id),a,json.writeValueAsString(body)),200);
        var restored=data(request("GET",path(id),a,null),200);
        assertThat(restored.get("chapters").size()).isEqualTo(2);
        assertThat(restored.get("chapters").get(0).get("id").asText()).isEqualTo("chapter-1");
        assertThat(restored.get("chapters").get(1).get("id").asText()).isEqualTo("chapter-2");
        assertThat(restored.get("chapters").get(1).get("content").asText()).isEqualTo("Contenido segundo");
    }
    @Test void concurrentCreatorsNeverOverwriteOrTransferAnotherOwnersStory() throws Exception {
        String a=account(),b=account(),id=UUID.randomUUID().toString();
        var first=java.util.concurrent.CompletableFuture.supplyAsync(()->{
            try{return request("POST",path(id),a,draft(id,0,"Autora A","Texto de A"));}catch(Exception e){throw new RuntimeException(e);}
        });
        var second=java.util.concurrent.CompletableFuture.supplyAsync(()->{
            try{return request("POST",path(id),b,draft(id,0,"Autora B","Texto de B"));}catch(Exception e){throw new RuntimeException(e);}
        });
        var ra=first.get();var rb=second.get();
        assertThat(List.of(ra.statusCode(),rb.statusCode())).contains(200);
        assertThat(ra.statusCode()==200 && rb.statusCode()==200).isFalse();
        var winner=ra.statusCode()==200?a:b;var loser=ra.statusCode()==200?b:a;
        assertThat(data(request("GET",path(id),winner,null),200).get("title").asText()).isEqualTo(winner.equals(a)?"Autora A":"Autora B");
        assertThat(data(request("GET","/api/me/writer/stories",loser,null),200).isEmpty()).isTrue();
        data(request("GET",path(id),loser,null),404);
    }
    @Test void browserPreflightAllowsAuthenticatedWriterSaveWithoutChangingGlobalCors() throws Exception {
        var req=HttpRequest.newBuilder(URI.create("http://127.0.0.1:"+port+"/api/me/writer/stories/fixture"))
            .header("Origin","http://localhost:7357")
            .header("Access-Control-Request-Method","POST")
            .header("Access-Control-Request-Headers","authorization,content-type")
            .method("OPTIONS",HttpRequest.BodyPublishers.noBody()).build();
        var response=client.send(req,HttpResponse.BodyHandlers.ofString());
        assertThat(response.statusCode()).isEqualTo(200);
        assertThat(response.headers().firstValue("Access-Control-Allow-Origin")).contains("http://localhost:7357");
        assertThat(response.headers().firstValue("Access-Control-Allow-Methods").orElse("")).contains("POST");
    }
    @Test void writerMigrationCreatesOwnTableAndEnforcesOwnerForeignKey() throws Exception {
        String migrationUrl="jdbc:h2:mem:writer-migration-"+UUID.randomUUID()+";MODE=PostgreSQL";
        try(var connection=java.sql.DriverManager.getConnection(migrationUrl,"sa","");var statement=connection.createStatement()){
            statement.execute("CREATE TABLE users(id BIGINT PRIMARY KEY)");
            org.springframework.jdbc.datasource.init.ScriptUtils.executeSqlScript(connection,
                new org.springframework.core.io.FileSystemResource("src/main/resources/db/migration/V10__create_writer_stories.sql"));
            var registry=new org.hibernate.boot.registry.StandardServiceRegistryBuilder()
                .applySetting("hibernate.connection.url",migrationUrl)
                .applySetting("hibernate.connection.username","sa")
                .applySetting("hibernate.connection.password","")
                .applySetting("hibernate.hbm2ddl.auto","validate").build();
            try(var factory=new org.hibernate.boot.MetadataSources(registry)
                .addAnnotatedClass(com.capitulo0.backend.writer.WriterStoryEntity.class)
                .buildMetadata().buildSessionFactory()){
                assertThat(factory.isOpen()).isTrue();
            }finally{org.hibernate.boot.registry.StandardServiceRegistryBuilder.destroy(registry);}
            statement.execute("INSERT INTO users VALUES(1)");
            statement.execute("INSERT INTO writer_stories(story_key,owner_id,payload,created_at,updated_at,revision) VALUES('one',1,'{}',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,0)");
            org.assertj.core.api.Assertions.assertThatThrownBy(()->statement.execute("INSERT INTO writer_stories(story_key,owner_id,payload,created_at,updated_at,revision) VALUES('two',2,'{}',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,0)")).isInstanceOf(java.sql.SQLException.class);
            statement.execute("DELETE FROM users WHERE id=1");
            try(var rows=statement.executeQuery("SELECT COUNT(*) FROM writer_stories")){
                rows.next();assertThat(rows.getInt(1)).isZero();
            }
        }
    }
    @Test void repeatedSaveUsesSameStoryAndChapterIdsAndRejectsDuplicateChapterIds() throws Exception {
        String a=account(),id=UUID.randomUUID().toString();
        var saved=data(request("POST",path(id),a,draft(id,0,"Una historia","Un capitulo")),200);
        var body=json.readValue(draft(id,saved.get("revision").asLong(),"Una historia","Un capitulo"),Map.class);
        var chapter=((List<?>)body.get("chapters")).get(0);
        body.put("chapters",List.of(chapter,chapter));
        data(request("POST",path(id),a,json.writeValueAsString(body)),400);
        assertThat(data(request("GET",path(id),a,null),200).get("chapters").size()).isEqualTo(1);
        data(request("POST",path(id),a,draft(id,saved.get("revision").asLong(),"Una historia","Un capitulo")),200);
        assertThat(data(request("GET","/api/me/writer/stories",a,null),200).size()).isEqualTo(1);
    }

    @Test void communityShowsOnlyOtherPublishedWorksAndWithdrawalsDisappear() throws Exception {
        String author=account(), reader=account(), id=UUID.randomUUID().toString();
        data(request("POST",path(id),author,draft(id,0,"Obra visible","Texto de lectura")),200);
        data(request("POST",path("private-"+id),author,draft("private-"+id,0,"SECRETO","PRIVADO")),200);
        assertThat(data(request("GET","/api/writer/stories",reader,null),200).isEmpty()).isTrue();
        var published=data(request("POST",path(id)+"/publication",author,"{\"revision\":0,\"published\":true}"),200);
        var catalogue=data(request("GET","/api/writer/stories",reader,null),200);
        assertThat(catalogue.size()).isEqualTo(1);
        assertThat(catalogue.get(0).get("title").asText()).isEqualTo("Obra visible");
        assertThat(catalogue.get(0).get("authorName").asText()).isEqualTo("Autora de prueba");
        assertThat(catalogue.get(0).get("authorUsername").asText()).startsWith("autor");
        assertThat(catalogue.get(0).has("chapters")).isFalse();
        assertThat(catalogue.get(0).has("ownerId")).isFalse();
        assertThat(catalogue.toString()).doesNotContain("SECRETO","PRIVADO","@example.test");
        assertThat(data(request("GET","/api/writer/stories",author,null),200).isEmpty()).isTrue();
        assertThat(request("GET","/api/writer/stories",null,null).statusCode()).isEqualTo(401);
        var withdrawn=data(request("POST",path(id)+"/publication",author,json.writeValueAsString(Map.of("revision",published.get("revision").asLong(),"published",false))),200);
        assertThat(withdrawn.get("chapters").get(0).get("isPublished").asBoolean()).isFalse();
        assertThat(data(request("GET","/api/writer/stories",reader,null),200).isEmpty()).isTrue();
        data(request("GET","/api/writer/stories/"+id,reader,null),404);
    }
    @Test void publishedEditsAreLiveAndCannotLeaveEmptyOrMixedChapters() throws Exception {
        String author=account(), reader=account(), id=UUID.randomUUID().toString();
        data(request("POST",path(id),author,draft(id,0,"Obra","Texto inicial")),200);
        var published=data(request("POST",path(id)+"/publication",author,"{\"revision\":0,\"published\":true}"),200);
        var body=json.readValue(draft(id,published.get("revision").asLong(),"Obra editada","Texto actualizado"),Map.class);
        body.put("status","published"); // client flag false is normalized to true by the server
        var changed=data(request("POST",path(id),author,json.writeValueAsString(body)),200);
        assertThat(changed.get("chapters").get(0).get("isPublished").asBoolean()).isTrue();
        assertThat(data(request("GET","/api/writer/stories/"+id,reader,null),200).get("chapters").get(0).get("content").asText()).isEqualTo("Texto actualizado");
        body=json.readValue(draft(id,changed.get("revision").asLong(),"Obra editada",""),Map.class);
        body.put("status","published");
        data(request("POST",path(id),author,json.writeValueAsString(body)),400);
        body.put("chapters",List.of());
        data(request("POST",path(id),author,json.writeValueAsString(body)),400);
        var unchanged=data(request("GET",path(id),author,null),200);
        assertThat(unchanged.get("revision").asLong()).isEqualTo(changed.get("revision").asLong());
        assertThat(unchanged.get("chapters").size()).isEqualTo(1);
        var withdrawn=data(request("POST",path(id)+"/publication",author,json.writeValueAsString(Map.of("revision",unchanged.get("revision").asLong(),"published",false))),200);
        body.put("status","draft");body.put("revision",withdrawn.get("revision").asLong());
        assertThat(data(request("POST",path(id),author,json.writeValueAsString(body)),200).get("chapters").isEmpty()).isTrue();
    }
}
