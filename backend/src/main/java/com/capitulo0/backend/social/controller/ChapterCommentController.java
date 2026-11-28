package com.capitulo0.backend.social.controller;

import com.capitulo0.backend.social.dto.ChapterCommentReportRequest;
import com.capitulo0.backend.social.dto.ChapterCommentResponse;
import com.capitulo0.backend.social.dto.CreateChapterCommentRequest;
import com.capitulo0.backend.social.dto.UpdateChapterCommentRequest;
import com.capitulo0.backend.social.service.ChapterCommentService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/writer/stories/{storyKey}/chapters/{chapterId}/comments")
public class ChapterCommentController {
    private final ChapterCommentService service;

    public ChapterCommentController(ChapterCommentService service) {
        this.service = service;
    }

    @GetMapping
    public List<ChapterCommentResponse> list(@PathVariable("storyKey") String storyKey,
                                      @PathVariable("chapterId") String chapterId) {
        return service.list(storyKey, chapterId);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ChapterCommentResponse create(@PathVariable("storyKey") String storyKey,
                                      @PathVariable("chapterId") String chapterId,
                                      @Valid @RequestBody CreateChapterCommentRequest request) {
        return service.create(storyKey, chapterId, request);
    }

    @PatchMapping("/{commentId}")
    public ChapterCommentResponse update(@PathVariable("storyKey") String storyKey,
                                      @PathVariable("chapterId") String chapterId,
                                      @PathVariable("commentId") Long commentId,
                                      @Valid @RequestBody UpdateChapterCommentRequest request) {
        return service.update(storyKey, chapterId, commentId, request);
    }

    @DeleteMapping("/{commentId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable("storyKey") String storyKey,
                                      @PathVariable("chapterId") String chapterId,
                       @PathVariable("commentId") Long commentId) {
        service.delete(storyKey, chapterId, commentId);
    }

    @PostMapping("/{commentId}/likes")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void like(@PathVariable("storyKey") String storyKey,
                                      @PathVariable("chapterId") String chapterId,
                     @PathVariable("commentId") Long commentId) {
        service.like(storyKey, chapterId, commentId);
    }

    @DeleteMapping("/{commentId}/likes")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void unlike(@PathVariable("storyKey") String storyKey,
                                      @PathVariable("chapterId") String chapterId,
                       @PathVariable("commentId") Long commentId) {
        service.unlike(storyKey, chapterId, commentId);
    }

    @PostMapping("/{commentId}/reports")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void report(@PathVariable("storyKey") String storyKey,
                                      @PathVariable("chapterId") String chapterId,
                       @PathVariable("commentId") Long commentId,
                       @Valid @RequestBody ChapterCommentReportRequest request) {
        service.report(storyKey, chapterId, commentId, request);
    }
    @PatchMapping("/{commentId}/visibility")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void setVisibility(@PathVariable("storyKey") String storyKey,
                              @PathVariable("chapterId") String chapterId,
                              @PathVariable("commentId") Long commentId,
                              @Valid @RequestBody VisibilityRequest request) {
        service.setVisibility(storyKey, chapterId, commentId, request.hidden());
    }

    public record VisibilityRequest(@jakarta.validation.constraints.NotNull Boolean hidden) {}
}
