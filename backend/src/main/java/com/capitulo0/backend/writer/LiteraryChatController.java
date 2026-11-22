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
@RequestMapping("/api/me/assistant")
public class LiteraryChatController {
    private final CurrentUserService current;
    private final LiteraryChatService chat;
    private final WriterService writer;
    private final JsonMapper json = JsonMapper.builder()
        .enable(StreamReadFeature.STRICT_DUPLICATE_DETECTION)
        .enable(DeserializationFeature.FAIL_ON_TRAILING_TOKENS)
        .enable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES).build();

    public LiteraryChatController(CurrentUserService current, LiteraryChatService chat, WriterService writer) {
        this.current = current;
        this.chat = chat;
        this.writer = writer;
    }

    @GetMapping("/stories")
    public Object stories() { return writer.assistantStories(current.require().getId()); }

    @GetMapping("/stories/{storyId}/chapters")
    public Object chapters(@PathVariable String storyId) {
        return writer.get(current.require().getId(), storyId).chapters().stream()
            .map(c -> new WriterService.AssistantChoice(c.id(), c.title())).toList();
    }

    @PostMapping(consumes = "application/json")
    public LiteraryChatService.Reply send(HttpServletRequest request) {
        String uid = current.requireIdentity().uid();
        long owner = current.require().getId();
        LiteraryChatService.Message input;
        try {
            var bytes = request.getInputStream().readNBytes(32769);
            if (bytes.length > 32768) throw new ApiException(HttpStatus.CONTENT_TOO_LARGE,
                "WRITER_AI_INPUT_TOO_LARGE", "Acorta el texto antes de enviarlo.");
            input = json.readValue(bytes, LiteraryChatService.Message.class);
        } catch (ApiException e) {
            throw e;
        } catch (Exception ignored) {
            throw ApiException.invalid("Mensaje de asistencia inválido.");
        }
        return chat.send(uid, owner, input);
    }
}
