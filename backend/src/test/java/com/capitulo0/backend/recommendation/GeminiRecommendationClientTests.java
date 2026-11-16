package com.capitulo0.backend.recommendation;

import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.Test;
import java.net.*;
import java.net.http.HttpClient;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.*;
import java.util.concurrent.atomic.AtomicReference;
import tools.jackson.databind.json.JsonMapper;
import static org.assertj.core.api.Assertions.*;
import static com.capitulo0.backend.recommendation.Recommendations.*;

class GeminiRecommendationClientTests {
    final JsonMapper json=JsonMapper.builder().build();
    Input input() { return new Input(List.of(new Preference("Leído",List.of("Autora"),List.of("Fantasía"),"LEIDO")),
        List.of(new Candidate("real","Candidato",List.of("Autora"),List.of("Fantasía"),List.of("AUTHOR:Autora")))); }
    @Test void missingKeyNeverCallsNetwork() {
        var client=new GeminiRecommendationClient("","gemini-4-hydrogen");
        assertThat(client.configured()).isFalse();
        assertThatThrownBy(()->client.select(input())).isInstanceOf(Unavailable.class);
    }
    @Test void officialRestContractIsStatelessBoundedAndDoesNotSendCredentialsInPrompt() throws Exception {
        var request=new AtomicReference<String>();
        var apiKey=new AtomicReference<String>();
        var revision=new AtomicReference<String>();
        var server=HttpServer.create(new InetSocketAddress("127.0.0.1",0),0);
        server.createContext("/",exchange->{
            request.set(new String(exchange.getRequestBody().readAllBytes(),StandardCharsets.UTF_8));
            apiKey.set(exchange.getRequestHeaders().getFirst("x-goog-api-key"));
            revision.set(exchange.getRequestHeaders().getFirst("Api-Revision"));
            String selection=json.writeValueAsString(Map.of("selections",List.of(Map.of("id","real","reasonCode","AUTHOR:Autora"))));
            byte[] body=json.writeValueAsBytes(Map.of("status","completed","steps",List.of(Map.of(
                "type","model_output","content",List.of(Map.of("type","text","text",selection))))));
            exchange.sendResponseHeaders(200,body.length); exchange.getResponseBody().write(body); exchange.close();
        }); server.start();
        try {
            var client=new GeminiRecommendationClient("test-only-key","gemini-4-hydrogen",HttpClient.newHttpClient(),
                URI.create("http://127.0.0.1:"+server.getAddress().getPort()+"/"),Duration.ofSeconds(2));
            assertThat(client.select(input())).containsExactly(new Selection("real","AUTHOR:Autora"));
            var body=json.readTree(request.get());
            assertThat(body.path("store").asBoolean(true)).isFalse();
            assertThat(body.path("generation_config").path("max_output_tokens").asInt()).isEqualTo(1024);
            assertThat(body.path("response_format").path("mime_type").asText()).isEqualTo("application/json");
            assertThat(body.path("input").asText()).contains("Leído","LEIDO","real").doesNotContain("test-only-key","Bearer","firebase");
            assertThat(apiKey.get()).isEqualTo("test-only-key");
            assertThat(revision.get()).isEqualTo("2026-05-20");
        } finally { server.stop(0); }
    }
    @Test void httpQuotaMalformedOversizedAndTimeoutAreSafeFallbackSignals() throws Exception {
        var server=HttpServer.create(new InetSocketAddress("127.0.0.1",0),0);
        var mode=new AtomicReference<>("quota");
        server.createContext("/",exchange->{
            try {
                int status=switch(mode.get()){case "quota"->429;case "http"->500;default->200;};
                if(mode.get().equals("slow")) Thread.sleep(350);
                byte[] body=(mode.get().equals("large")?"x".repeat(70000):"{}").getBytes(StandardCharsets.UTF_8);
                exchange.sendResponseHeaders(status,body.length); exchange.getResponseBody().write(body);
            } catch(Exception ignored) {} finally {exchange.close();}
        }); server.start();
        try {
            var client=new GeminiRecommendationClient("test-only-key","gemini-4-hydrogen",HttpClient.newHttpClient(),
                URI.create("http://127.0.0.1:"+server.getAddress().getPort()+"/"),Duration.ofMillis(150));
            for(var value:List.of("quota","http","invalid","large","slow")) {
                mode.set(value);
                assertThatThrownBy(()->client.select(input())).isInstanceOf(Unavailable.class)
                    .hasMessageNotContaining("test-only-key");
            }
        } finally {server.stop(0);}
    }

    @Test void availabilityChecksAccountModelMetadataOnceAndNeverGenerates() throws Exception {
        var server=HttpServer.create(new InetSocketAddress("127.0.0.1",0),0);
        var mode=new AtomicReference<>("ok");
        var calls=new java.util.concurrent.atomic.AtomicInteger();
        server.createContext("/",exchange->{
            calls.incrementAndGet();
            assertThat(exchange.getRequestMethod()).isEqualTo("GET");
            assertThat(exchange.getRequestURI().getPath()).isEqualTo("/models/gemini-4-hydrogen");
            assertThat(exchange.getRequestURI().getQuery()).isNull();
            int status=mode.get().equals("forbidden")?403:mode.get().equals("missing")?404:200;
            byte[] body=json.writeValueAsBytes(Map.of(
                "name",mode.get().equals("wrong")?"models/other":"models/gemini-4-hydrogen",
                "supportedGenerationMethods",mode.get().equals("unsupported")?List.of():List.of("generateContent")));
            exchange.sendResponseHeaders(status,body.length); exchange.getResponseBody().write(body); exchange.close();
        }); server.start();
        try {
            int expected=0;
            for(var value:List.of("ok","forbidden","missing","wrong","unsupported")) {
                mode.set(value);
                var client=new GeminiRecommendationClient("test-only-key","gemini-4-hydrogen",HttpClient.newHttpClient(),
                    URI.create("http://127.0.0.1:"+server.getAddress().getPort()+"/interactions"),Duration.ofSeconds(2));
                assertThat(client.available()).isEqualTo(value.equals("ok"));
                assertThat(client.available()).isEqualTo(value.equals("ok"));
                assertThat(calls.get()).isEqualTo(++expected);
            }
            var absent=new GeminiRecommendationClient("","gemini-4-hydrogen",HttpClient.newHttpClient(),
                URI.create("http://127.0.0.1:"+server.getAddress().getPort()+"/interactions"),Duration.ofSeconds(2));
            assertThat(absent.available()).isFalse(); assertThat(calls.get()).isEqualTo(expected);
        } finally { server.stop(0); }
    }

}
