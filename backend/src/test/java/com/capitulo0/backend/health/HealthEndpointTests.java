package com.capitulo0.backend.health;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class HealthEndpointTests {

    @org.springframework.beans.factory.annotation.Autowired
    private org.springframework.context.ApplicationContext context;

    @Value("${local.server.port}")
    private int port;

    @Test
    void healthIsAvailableOverHttp() throws Exception {
        var request = HttpRequest.newBuilder(URI.create("http://127.0.0.1:" + port + "/api/health"))
                .timeout(Duration.ofSeconds(5)).GET().build();
        try (HttpClient client = HttpClient.newHttpClient()) {
            var response = client.send(request, HttpResponse.BodyHandlers.ofString());
            assertThat(response.statusCode()).isEqualTo(200);
            assertThat(response.headers().firstValue("Content-Type").orElse(""))
                    .startsWith("application/json");
            assertThat(response.body()).contains("\"status\":\"UP\"", "\"service\":\"capitulo-0-backend\"",
                    "\"database\":\"UP\"");
        }
    }
    @Test
    void missingFirebaseConfigFailsClosedWithoutAccessingAdc() throws Exception {
        var request = HttpRequest.newBuilder(URI.create("http://127.0.0.1:" + port + "/api/me"))
            .timeout(Duration.ofSeconds(5)).header("Authorization", "Bearer offline-test").GET().build();
        try (HttpClient client = HttpClient.newHttpClient()) {
            var response = client.send(request, HttpResponse.BodyHandlers.ofString());
            assertThat(response.statusCode()).isEqualTo(503);
            assertThat(response.body()).contains("\"status\":503")
                .doesNotContain("private_key", "GOOGLE_APPLICATION_CREDENTIALS", "stackTrace");
        }
    }

    @Test
    void noPasswordUserServiceIsAutoConfigured() {
        assertThat(context.getBeansOfType(org.springframework.security.core.userdetails.UserDetailsService.class))
            .isEmpty();
    }

}
