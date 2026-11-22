package com.capitulo0.backend;

import com.capitulo0.backend.config.cors.ApiCorsConfiguration;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class CorsConfigurationTests {
    @Test void defaultPolicyDoesNotAllowCrossOriginRequests() {
        var source = new ApiCorsConfiguration().apiCorsConfigurationSource("");
        var cors = source.getCorsConfiguration(new MockHttpServletRequest("GET", "/api/me"));
        assertThat(cors).isNotNull();
        assertThat(cors.getAllowedOrigins()).isEmpty();
        assertThat(cors.checkOrigin("http://localhost:7357")).isNull();
    }
    @Test void parsesExactOriginsAndDoesNotEnableCookiesOrWildcards() {
        var source = new ApiCorsConfiguration().apiCorsConfigurationSource(
            " http://localhost:7357,https://app.example.test,http://localhost:7357 ");
        var cors = source.getCorsConfiguration(new MockHttpServletRequest("GET", "/api/me"));
        assertThat(cors.getAllowedOrigins()).containsExactly("http://localhost:7357", "https://app.example.test");
        assertThat(cors.getAllowedOriginPatterns()).isNull();
        assertThat(cors.getAllowCredentials()).isFalse();
        assertThat(cors.checkOrigin("http://localhost:7358")).isNull();
    }
    @Test void rejectsUnsafeOriginConfigurationWithoutEchoingValues() {
        for (String origin : new String[] {"*", "null", "https://*.example.test", "https://host.example.test/path",
                "https://user:do-not-echo@host.example.test", "http://localhost:0",
                "http://localhost:99999", "https://host.example.test?secret=do-not-echo",
                "file:///tmp/app", "https://host.example.test/"}) {
            assertThatThrownBy(() -> new ApiCorsConfiguration().apiCorsConfigurationSource(origin))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("APP_CORS_ALLOWED_ORIGINS")
                .hasMessageNotContaining("do-not-echo");
        }
    }
    @Test void doesNotRegisterCorsOutsideApiRoutes() {
        var source = new ApiCorsConfiguration().apiCorsConfigurationSource("http://localhost:7357");
        assertThat(source.getCorsConfiguration(new MockHttpServletRequest("GET", "/other"))).isNull();
    }
}
