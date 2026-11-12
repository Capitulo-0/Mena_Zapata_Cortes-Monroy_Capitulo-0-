package com.capitulo0.backend.integration.googlebooks;
import org.springframework.web.bind.annotation.*;
import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.catalog.book.dto.BookResponse;
@RestController
public class GoogleBooksController {
    private final GoogleBooksService service;
    private final GoogleBooksImportService importer;
    private final CurrentUserService current;
    public GoogleBooksController(GoogleBooksService service,GoogleBooksImportService importer,CurrentUserService current) {
        this.service=service; this.importer=importer; this.current=current;
    }
    @GetMapping("/api/catalog/search")
    public GoogleBooksService.Page search(@RequestParam String q,@RequestParam(defaultValue="all") String mode,
        @RequestParam(defaultValue="0") int startIndex,@RequestParam(defaultValue="20") int maxResults,
        @RequestParam(defaultValue="") String language) { return service.search(q,mode,startIndex,maxResults,language); }
    @GetMapping("/api/catalog/google-books/{volumeId}")
    public GoogleBook detail(@PathVariable String volumeId) { return service.detail(volumeId); }
    public record ImportRequest(String volumeId) {}
    @PostMapping("/api/books/import/google-books")
    public BookResponse importBook(@RequestBody ImportRequest request) {
        current.require(); return importer.resolve(request.volumeId());
    }
}
