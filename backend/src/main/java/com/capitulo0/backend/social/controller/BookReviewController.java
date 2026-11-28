package com.capitulo0.backend.social.controller;

import com.capitulo0.backend.social.dto.BookReviewResponse;
import com.capitulo0.backend.social.dto.BookRatingSummaryResponse;
import com.capitulo0.backend.social.dto.OwnBookReviewResponse;
import com.capitulo0.backend.social.dto.UpsertBookReviewRequest;
import com.capitulo0.backend.social.service.BookReviewService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/books/{bookId}/reviews")
public class BookReviewController {
    private final BookReviewService service;

    public BookReviewController(BookReviewService service) {
        this.service = service;
    }

    @GetMapping
    public List<BookReviewResponse> list(@PathVariable("bookId") Long bookId) {
        return service.list(bookId);
    }

    @GetMapping("/summary")
    public BookRatingSummaryResponse summary(@PathVariable("bookId") Long bookId) {
        return service.summary(bookId);
    }

    @GetMapping("/mine")
    public ResponseEntity<OwnBookReviewResponse> own(@PathVariable("bookId") Long bookId) {
        return ResponseEntity.of(service.own(bookId));
    }

    @PutMapping("/mine")
    public OwnBookReviewResponse upsert(@PathVariable("bookId") Long bookId,
                                        @Valid @RequestBody UpsertBookReviewRequest request) {
        return service.upsert(bookId, request);
    }

    @DeleteMapping("/mine")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable("bookId") Long bookId) {
        service.delete(bookId);
    }
}
