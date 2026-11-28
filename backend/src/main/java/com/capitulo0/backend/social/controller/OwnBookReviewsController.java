package com.capitulo0.backend.social.controller;

import com.capitulo0.backend.social.dto.OwnBookReviewEntryResponse;
import com.capitulo0.backend.social.service.BookReviewService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;

@RestController
@RequestMapping("/api/me/book-reviews")
public class OwnBookReviewsController {
    private final BookReviewService service;

    public OwnBookReviewsController(BookReviewService service) {
        this.service = service;
    }

    @GetMapping
    public List<OwnBookReviewEntryResponse> listOwn() {
        return service.listOwn();
    }
}
