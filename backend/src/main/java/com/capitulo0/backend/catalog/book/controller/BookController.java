package com.capitulo0.backend.catalog.book.controller;
import java.util.List;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import com.capitulo0.backend.catalog.book.dto.*;
import com.capitulo0.backend.catalog.book.service.BookService;
@RestController
@RequestMapping("/api/books")
public class BookController {
    private final BookService service;
    public BookController(BookService service) { this.service = service; }
    @PostMapping @ResponseStatus(HttpStatus.CREATED)
    public BookResponse create(@Valid @RequestBody CreateBookRequest request) { return service.create(request); }
    @GetMapping public List<BookResponse> list() { return service.list(); }
    @GetMapping("/{id}") public BookResponse get(@PathVariable Long id) { return service.get(id); }
}
