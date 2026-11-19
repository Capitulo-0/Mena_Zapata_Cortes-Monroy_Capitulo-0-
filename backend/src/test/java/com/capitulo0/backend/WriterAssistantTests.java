package com.capitulo0.backend;

import com.capitulo0.backend.auth.model.AuthenticatedFirebaseUser;
import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.common.exception.ApiExceptionHandler;
import com.capitulo0.backend.recommendation.GeminiRecommendationClient;
import com.capitulo0.backend.recommendation.Recommendations.Unavailable;
import com.capitulo0.backend.user.service.UserService;
import com.capitulo0.backend.writer.*;
import org.junit.jupiter.api.*;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import tools.jackson.databind.json.JsonMapper;
import java.util.*;
import java.util.concurrent.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class WriterAssistantTests {
    private final GeminiRecommendationClient gemini = mock(GeminiRecommendationClient.class);
    private final UserService users = mock(UserService.class);
    private final JsonMapper json = JsonMapper.builder().build();
    private final org.springframework.test.web.servlet.MockMvc mvc = MockMvcBuilders.standaloneSetup(
        new WriterAssistantController(new CurrentUserService(users), new WriterAssistantService(gemini)))
        .setControllerAdvice(new ApiExceptionHandler()).build();

    @BeforeEach void configured() { when(gemini.configured()).thenReturn(true); }

    @AfterEach void clearIdentity() {
        SecurityContextHolder.clearContext();
        verifyNoInteractions(users);
    }

    private void login(String uid) {
        var principal = new AuthenticatedFirebaseUser(uid, null, "Prueba", true);
        SecurityContextHolder.getContext().setAuthentication(
            new UsernamePasswordAuthenticationToken(principal, null, List.of()));
    }

    private org.springframework.test.web.servlet.ResultActions send(String body) throws Exception {
        return mvc.perform(post("/api/me/writer/assistant").contentType("application/json").content(body));
    }

    private String request(String task) {
        return json.writeValueAsString(Map.of("task", task, "genre", "Misterio",
            "context", "La bibliotecaria encontró una llave.", "direction", "Una pista discreta", "tone", "Sobrio"));
    }

    private void response(List<String> values) {
        doReturn(json.valueToTree(Map.of("suggestions", values)))
            .when(gemini).generate(anyString(), anyMap(), anyMap(), anyInt(), anyString());
    }

    @Test void authenticationIsRequiredBeforeInputOrProvider() throws Exception {
        send(request("IDEAS")).andExpect(status().isUnauthorized());
        verifyNoInteractions(gemini);
    }

    @Test void rejectsUnknownFieldsMissingTextAndBodyLimit() throws Exception {
        login("uid-A");
        for (var value : List.of("{}", "{\"task\":\"UNKNOWN\"}",
                "{\"task\":\"IDEAS\",\"context\":\"Biblioteca\",\"storyId\":\"de-otro-autor\"}",
                "{\"task\":\"SYNOPSIS\",\"direction\":\"sin sinopsis\"}",
                "{\"task\":\"IDEAS\",\"context\":\"" + "x".repeat(4001) + "\"}")) {
            send(value).andExpect(status().isBadRequest());
        }
        send("x".repeat(32769)).andExpect(status().is(413));
        verifyNoInteractions(gemini);
    }

    @Test void generatesEachTaskWithStructuredOutputUsingOnlyExplicitLiteraryFields() throws Exception {
        response(List.of("Apuntes de la biblioteca."));
        int taskNumber = 0;
        for (var task : List.of("IDEAS", "SYNOPSIS", "CONTINUE", "NEXT", "STYLE", "CORRECT", "DIALOGUE", "BLOCK")) {
            login("private-firebase-uid-" + taskNumber++);
            send(request(task)).andExpect(status().isOk())
                .andExpect(jsonPath("$.suggestions[0]").value("Apuntes de la biblioteca."));
        }
        verify(gemini, times(8)).generate(contains("español"),
            eq(Map.of("género", "Misterio", "fragmento", "La bibliotecaria encontró una llave.",
                "dirección", "Una pista discreta", "tono", "Sobrio")), anyMap(), eq(2304), eq("low"));
        login("private-title-uid");
        response(List.of("La puerta cerrada", "El índice perdido", "La llave del silencio"));
        send(request("TITLES")).andExpect(status().isOk())
            .andExpect(jsonPath("$.suggestions.length()").value(3));
    }

    @Test void rejectsDuplicateTitlesMalformedAndEmptyResults() throws Exception {
        login("uid-A");
        response(List.of("Una llave", "UNA LLAVE", "La noche"));
        send(request("TITLES")).andExpect(status().isBadGateway())
            .andExpect(jsonPath("$.code").value("WRITER_AI_INVALID"));
        response(List.of(" "));
        send(request("IDEAS")).andExpect(status().isBadGateway())
            .andExpect(jsonPath("$.code").value("WRITER_AI_EMPTY"));
        when(gemini.generate(anyString(), anyMap(), anyMap(), anyInt(), anyString()))
            .thenReturn(json.readTree("{\"suggestions\":\"texto\"}"));
        send(request("IDEAS")).andExpect(status().isBadGateway())
            .andExpect(jsonPath("$.code").value("WRITER_AI_INVALID"));
    }

    @Test void mapsProviderErrorsAndQuotaSeparatelyForEachIdentity() throws Exception {
        login("uid-A");
        when(gemini.configured()).thenReturn(false);
        send(request("IDEAS")).andExpect(status().isServiceUnavailable())
            .andExpect(jsonPath("$.code").value("WRITER_AI_NOT_CONFIGURED"));
        when(gemini.configured()).thenReturn(true);
        for (var failure : Map.of("TIMEOUT", 504, "QUOTA", 429, "HTTP_ERROR", 502).entrySet()) {
            doThrow(new Unavailable(failure.getKey())).when(gemini)
                .generate(anyString(), anyMap(), anyMap(), anyInt(), anyString());
            send(request("IDEAS")).andExpect(status().is(failure.getValue()));
        }
        doReturn(json.valueToTree(Map.of("suggestions", List.of("Una pista"))))
            .when(gemini).generate(anyString(), anyMap(), anyMap(), anyInt(), anyString());
        for (int index = 0; index < 2; index++) send(request("IDEAS")).andExpect(status().isOk());
        send(request("IDEAS")).andExpect(status().isTooManyRequests());
        login("uid-B");
        send(request("IDEAS")).andExpect(status().isOk());
        verify(gemini, times(6)).generate(anyString(), anyMap(), anyMap(), anyInt(), anyString());
    }

    @Test void suppressesConcurrentDuplicateFromSameIdentity() throws Exception {
        var entered = new CountDownLatch(1);
        var release = new CountDownLatch(1);
        when(gemini.generate(anyString(), anyMap(), anyMap(), anyInt(), anyString())).thenAnswer(invocation -> {
            entered.countDown();
            if (!release.await(5, TimeUnit.SECONDS)) throw new IllegalStateException("Test deadline");
            return json.valueToTree(Map.of("suggestions", List.of("Una pista")));
        });
        try (var executor = Executors.newSingleThreadExecutor()) {
            var running = executor.submit(() -> {
                login("uid-A");
                try {
                    return send(request("IDEAS")).andReturn().getResponse().getStatus();
                } finally {
                    SecurityContextHolder.clearContext();
                }
            });
            try {
                assertThat(entered.await(5, TimeUnit.SECONDS)).isTrue();
                login("uid-A");
                send(request("IDEAS")).andExpect(status().isTooManyRequests());
            } finally {
                release.countDown();
            }
            assertThat(running.get(5, TimeUnit.SECONDS)).isEqualTo(200);
        }
        verify(gemini).generate(anyString(), anyMap(), anyMap(), anyInt(), anyString());
    }
}
