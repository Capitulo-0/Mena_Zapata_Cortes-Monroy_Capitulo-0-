package com.capitulo0.backend;
import com.capitulo0.backend.integration.googlebooks.*;
import com.capitulo0.backend.common.exception.ApiException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.AfterEach;
import com.sun.net.httpserver.HttpServer;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicReference;
import tools.jackson.databind.json.JsonMapper;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;
class GoogleBooksTests {
    final JsonMapper json=JsonMapper.builder().build();
    GoogleBooksClient client=mock(GoogleBooksClient.class);
    GoogleBooksService service=new GoogleBooksService(client);
    @Test void titleAuthorIsbnAndFreeTextAreTranslated() {
        when(client.search(anyString(),anyInt(),anyInt(),anyString())).thenReturn(json.readTree("{\"totalItems\":0}"));
        for(var mode: new String[]{"title","author","isbn","all"}) service.search("test",mode,0,20,"");
        verify(client).search("intitle:test",0,20,"");
        verify(client).search("inauthor:test",0,20,"");
        verify(client).search("isbn:test",0,20,"");
        verify(client).search("test",0,20,"");
    }
    @Test void invalidParametersNeverCallProvider() {
        assertThatThrownBy(() -> service.search(" ","all",0,20,"")).isInstanceOf(ApiException.class);
        assertThatThrownBy(() -> service.search("a","other",0,20,"")).isInstanceOf(ApiException.class);
        assertThatThrownBy(() -> service.search("a","all",-1,20,"")).isInstanceOf(ApiException.class);
        assertThatThrownBy(() -> service.search("a","all",0,41,"")).isInstanceOf(ApiException.class);
        assertThatThrownBy(() -> service.search("a","all",0,20,"invalid")).isInstanceOf(ApiException.class);
        assertThatThrownBy(() -> service.detail("../secret")).isInstanceOf(ApiException.class);
        verifyNoInteractions(client);
    }
    @Test void optionalMetadataAndHtmlAndUrlsAreSafe() {
        var b=GoogleBooksClient.map(json.readTree("""
            {"id":"fixture","volumeInfo":{"title":"Book","description":"<script>bad()</script><p>Hello &amp; world</p>","imageLinks":{"thumbnail":"javascript:bad"}}}
            """));
        assertThat(b.authors()).isEmpty(); assertThat(b.pageCount()).isNull();
        assertThat(b.coverUrl()).isNull(); assertThat(b.description()).isEqualTo("Hello & world");
        assertThatThrownBy(() -> GoogleBooksClient.map(json.readTree("{}"))).isInstanceOf(ApiException.class);
    }
    @Test void malformedSearchIsNotAnEmptySuccess() {
        when(client.search("invalid",0,20,"")).thenReturn(json.readTree("{}"));
        assertThatThrownBy(() -> service.search("invalid","all",0,20,"")).isInstanceOf(ApiException.class);
        when(client.search("invalid",0,20,"")).thenReturn(json.readTree("{\"totalItems\":12}"));
        assertThatThrownBy(() -> service.search("invalid","all",0,20,"")).isInstanceOf(ApiException.class);
    }
    @Test void pagesAndSpanishPreferenceDoNotExcludeEnglish() {
        when(client.search("q",20,2,"")).thenReturn(json.readTree("""
            {"totalItems":100,"items":[{"id":"en","volumeInfo":{"title":"English","language":"en"}},{"id":"es","volumeInfo":{"title":"Spanish","language":"es"}}]}
            """));
        var page=service.search("q","all",20,2,"");
        assertThat(page.nextStartIndex()).isEqualTo(22);
        assertThat(page.items()).extracting(GoogleBook::volumeId).containsExactly("es","en");
        when(client.search("empty",0,20,"")).thenReturn(json.readTree("{\"totalItems\":0}"));
        assertThat(service.search("empty","all",0,20,"").items()).isEmpty();
    }
    @Test void realHttpTransportEncodesQueryAndMapsFailuresWithoutSecrets() throws Exception {
        var server=HttpServer.create(new InetSocketAddress("127.0.0.1",0),0);
        var request=new AtomicReference<String>();
        server.createContext("/volumes", exchange -> {
            request.set(exchange.getRequestURI().getRawQuery());
            int status=exchange.getRequestURI().getPath().endsWith("/missing")?404:
                exchange.getRequestURI().getPath().endsWith("/quota")?429:
                exchange.getRequestURI().getPath().endsWith("/bad")?500:200;
            byte[] body="{\"totalItems\":0}".getBytes(StandardCharsets.UTF_8);
            exchange.sendResponseHeaders(status,body.length); exchange.getResponseBody().write(body); exchange.close();
        });
        server.start();
        try {
            var transport=new GoogleBooksClient("http://127.0.0.1:"+server.getAddress().getPort(),"fixture-key",500);
            transport.search("autor & título",0,20,"es");
            assertThat(request.get()).contains("%26","startIndex=0","langRestrict=es");
            assertThatThrownBy(() -> transport.volume("missing")).isInstanceOf(ApiException.class).hasMessageNotContaining("fixture-key");
            assertThatThrownBy(() -> transport.volume("quota")).isInstanceOf(ApiException.class);
            assertThatThrownBy(() -> transport.volume("bad")).isInstanceOf(ApiException.class);
            assertThatThrownBy(() -> new GoogleBooksClient("http://127.0.0.1:"+server.getAddress().getPort(),"",100).volume("a")).isInstanceOf(ApiException.class);
        } finally { server.stop(0); }
    }
    @Test void timeoutIsControlled() throws Exception {
        var server=HttpServer.create(new InetSocketAddress("127.0.0.1",0),0);
        server.createContext("/volumes", ex -> {
            try { Thread.sleep(400); ex.sendResponseHeaders(200,0); ex.close(); } catch(Exception ignored) { }
        });
        server.start();
        try {
            var transport=new GoogleBooksClient("http://127.0.0.1:"+server.getAddress().getPort(),"fixture",100);
            assertThatThrownBy(() -> transport.volume("slow")).isInstanceOf(ApiException.class);
        } finally { server.stop(0); }
    }
}
