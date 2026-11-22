package com.capitulo0.backend.user.controller;

import com.capitulo0.backend.user.dto.ReadingMoodRequest;
import com.capitulo0.backend.user.dto.ReadingMoodResponse;
import com.capitulo0.backend.user.service.ReadingMoodService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/me/reading-mood")
public class ReadingMoodController {
    private final ReadingMoodService service;

    public ReadingMoodController(ReadingMoodService service) { this.service = service; }

    @GetMapping
    public ResponseEntity<ReadingMoodResponse> current() {
        var mood = service.myMood();
        return mood == null ? ResponseEntity.noContent().build() : ResponseEntity.ok(mood);
    }

    @PutMapping
    public ResponseEntity<ReadingMoodResponse> save(@Valid @RequestBody ReadingMoodRequest request) {
        var mood = service.save(request);
        return mood == null ? ResponseEntity.noContent().build() : ResponseEntity.ok(mood);
    }
}
