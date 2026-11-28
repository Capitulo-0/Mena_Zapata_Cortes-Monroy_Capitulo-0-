package com.capitulo0.backend.social.controller;

import com.capitulo0.backend.social.dto.StoryReviewResponse;
import com.capitulo0.backend.social.dto.StoryRatingSummaryResponse;
import com.capitulo0.backend.social.dto.OwnStoryReviewResponse;
import com.capitulo0.backend.social.dto.UpsertStoryReviewRequest;
import com.capitulo0.backend.social.service.StoryReviewService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/writer/stories/{storyKey}/reviews")
public class StoryReviewController {
    private final StoryReviewService service;

    public StoryReviewController(StoryReviewService service) {
        this.service = service;
    }

    @GetMapping
    public List<StoryReviewResponse> list(@PathVariable("storyKey") String storyKey) {
        return service.list(storyKey);
    }

    @GetMapping("/summary")
    public StoryRatingSummaryResponse summary(@PathVariable("storyKey") String storyKey) {
        return service.summary(storyKey);
    }

    @GetMapping("/mine")
    public ResponseEntity<OwnStoryReviewResponse> own(@PathVariable("storyKey") String storyKey) {
        return ResponseEntity.of(service.own(storyKey));
    }

    @PutMapping("/mine")
    public OwnStoryReviewResponse upsert(@PathVariable("storyKey") String storyKey,
                                        @Valid @RequestBody UpsertStoryReviewRequest request) {
        return service.upsert(storyKey, request);
    }

    @DeleteMapping("/mine")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable("storyKey") String storyKey) {
        service.delete(storyKey);
    }
}
