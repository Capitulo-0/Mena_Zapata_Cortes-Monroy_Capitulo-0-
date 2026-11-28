package com.capitulo0.backend.social.controller;

import com.capitulo0.backend.social.dto.BookCommentReportRequest;
import com.capitulo0.backend.social.dto.BookCommentResponse;
import com.capitulo0.backend.social.dto.CreateBookCommentRequest;
import com.capitulo0.backend.social.dto.UpdateBookCommentRequest;
import com.capitulo0.backend.social.service.BookCommentService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/books/{bookId}/comments")
public class BookCommentController {
    private final BookCommentService service;

    public BookCommentController(BookCommentService service) {
        this.service = service;
    }

    @GetMapping
    public List<BookCommentResponse> list(@PathVariable("bookId") Long bookId) {
        return service.list(bookId);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public BookCommentResponse create(@PathVariable("bookId") Long bookId,
                                      @Valid @RequestBody CreateBookCommentRequest request) {
        return service.create(bookId, request);
    }

    @PatchMapping("/{commentId}")
    public BookCommentResponse update(@PathVariable("bookId") Long bookId,
                                      @PathVariable("commentId") Long commentId,
                                      @Valid @RequestBody UpdateBookCommentRequest request) {
        return service.update(bookId, commentId, request);
    }

    @DeleteMapping("/{commentId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable("bookId") Long bookId,
                       @PathVariable("commentId") Long commentId) {
        service.delete(bookId, commentId);
    }

    @PostMapping("/{commentId}/likes")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void like(@PathVariable("bookId") Long bookId,
                     @PathVariable("commentId") Long commentId) {
        service.like(bookId, commentId);
    }

    @DeleteMapping("/{commentId}/likes")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void unlike(@PathVariable("bookId") Long bookId,
                       @PathVariable("commentId") Long commentId) {
        service.unlike(bookId, commentId);
    }

    @PostMapping("/{commentId}/reports")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void report(@PathVariable("bookId") Long bookId,
                       @PathVariable("commentId") Long commentId,
                       @Valid @RequestBody BookCommentReportRequest request) {
        service.report(bookId, commentId, request);
    }
}
