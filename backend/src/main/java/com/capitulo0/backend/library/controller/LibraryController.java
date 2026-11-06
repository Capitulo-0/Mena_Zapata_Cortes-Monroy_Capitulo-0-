package com.capitulo0.backend.library.controller;
import java.util.List;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import com.capitulo0.backend.library.dto.*;
import com.capitulo0.backend.library.service.LibraryService;
@RestController
@RequestMapping("/api/users/{userId}/library")
public class LibraryController {
    private final LibraryService service;
    public LibraryController(LibraryService service) { this.service = service; }
    @GetMapping public List<LibraryEntryResponse> list(@PathVariable Long userId) { return service.list(userId); }
    @PostMapping @ResponseStatus(HttpStatus.CREATED)
    public LibraryEntryResponse add(@PathVariable Long userId, @Valid @RequestBody AddLibraryEntryRequest request) {
        return service.add(userId, request);
    }
    @PatchMapping("/{bookId}")
    public LibraryEntryResponse update(@PathVariable Long userId, @PathVariable Long bookId,
                                       @Valid @RequestBody UpdateLibraryEntryRequest request) {
        return service.update(userId, bookId, request);
    }
    @DeleteMapping("/{bookId}") @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long userId, @PathVariable Long bookId) { service.delete(userId, bookId); }
}
