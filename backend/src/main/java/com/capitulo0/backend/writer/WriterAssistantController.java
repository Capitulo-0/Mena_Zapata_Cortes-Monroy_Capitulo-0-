package com.capitulo0.backend.writer;

import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.common.exception.ApiException;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import tools.jackson.core.StreamReadFeature;
import tools.jackson.databind.DeserializationFeature;
import tools.jackson.databind.json.JsonMapper;

@RestController
public class WriterAssistantController {
    private static final int MAX_BYTES = 32768;
    private final CurrentUserService current;
    private final WriterAssistantService assistant;
    private final JsonMapper json = JsonMapper.builder()
        .enable(StreamReadFeature.STRICT_DUPLICATE_DETECTION)
        .enable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES)
        .enable(DeserializationFeature.FAIL_ON_TRAILING_TOKENS).build();

    public WriterAssistantController(CurrentUserService current, WriterAssistantService assistant) {
        this.current = current;
        this.assistant = assistant;
    }

    @PostMapping(value = "/api/me/writer/assistant", consumes = "application/json")
    public WriterAssistantService.Result generate(HttpServletRequest request) {
        var uid = current.requireIdentity().uid();
        if (request.getContentLengthLong() > MAX_BYTES) throw tooLarge();
        WriterAssistantService.Request input;
        try {
            var bytes = request.getInputStream().readNBytes(MAX_BYTES + 1);
            if (bytes.length > MAX_BYTES) throw tooLarge();
            var fields = json.readTree(bytes);
            if (!fields.isObject()) throw ApiException.invalid("Solicitud de asistencia inválida.");
            for (var field : fields) {
                if (!field.isString() && !field.isNull())
                    throw ApiException.invalid("Los campos deben contener texto.");
            }
            input = json.treeToValue(fields, WriterAssistantService.Request.class);
        } catch (ApiException e) {
            throw e;
        } catch (Exception ignored) {
            throw ApiException.invalid("Solicitud de asistencia inválida.");
        }
        return assistant.generate(uid, input);
    }

    private static ApiException tooLarge() {
        return new ApiException(HttpStatus.CONTENT_TOO_LARGE, "WRITER_AI_INPUT_TOO_LARGE",
            "El texto enviado es demasiado largo.");
    }
}
