package com.capitulo0.backend.library.controller;

import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.library.entity.SavedCommunityStory;
import com.capitulo0.backend.library.repository.SavedCommunityStoryRepository;
import com.capitulo0.backend.common.exception.ApiException;
import com.capitulo0.backend.writer.WriterService;
import org.springframework.http.HttpStatus;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/me/library/stories")
public class SavedCommunityStoryController {
    private final SavedCommunityStoryRepository saved;
    private final WriterService writer;
    private final CurrentUserService current;
    public SavedCommunityStoryController(SavedCommunityStoryRepository saved,
                                         WriterService writer, CurrentUserService current) {
        this.saved = saved; this.writer = writer; this.current = current;
    }

    @GetMapping
    @Transactional(readOnly = true)
    public List<WriterService.PublicationSummary> list() {
        Long userId = current.require().getId();
        Set<String> ids = saved.findByUserId(userId).stream().map(SavedCommunityStory::getStoryKey).collect(Collectors.toSet());
        // Only return currently published stories; withdrawn publications must not be readable.
        return writer.community(userId).stream().filter(p -> ids.contains(p.id())).toList();
    }

    @PostMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Transactional
    public void add(@PathVariable String id) {
        if (!id.matches("[a-zA-Z0-9_-]{1,64}")) throw ApiException.invalid("Identificador de historia no valido");
        Long userId = current.require().getId();
        writer.published(id); // Reject drafts, deleted or unpublished stories.
        saved.saveIfMissing(userId, id);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Transactional
    public void remove(@PathVariable String id) {
        if (!id.matches("[a-zA-Z0-9_-]{1,64}")) throw ApiException.invalid("Identificador de historia no valido");
        saved.deleteById(new SavedCommunityStory.Key(current.require().getId(), id));
    }
}
