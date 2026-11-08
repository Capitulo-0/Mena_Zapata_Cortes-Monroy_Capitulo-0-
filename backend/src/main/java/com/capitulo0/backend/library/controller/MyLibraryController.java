package com.capitulo0.backend.library.controller;

import java.util.List;
import jakarta.validation.Valid;
import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.library.dto.*;
import com.capitulo0.backend.library.service.LibraryService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/me/library")
public class MyLibraryController {
    private final LibraryService service;
    private final CurrentUserService current;
    public MyLibraryController(LibraryService service, CurrentUserService current) {
        this.service = service; this.current = current;
    }
    @GetMapping public List<LibraryEntryResponse> list() { return service.list(current.require().getId()); }
    @PostMapping @ResponseStatus(HttpStatus.CREATED)
    public LibraryEntryResponse add(@Valid @RequestBody AddLibraryEntryRequest request) {
        return service.add(current.require().getId(), request);
    }
    @PatchMapping("/{bookId}")
    public LibraryEntryResponse update(@PathVariable Long bookId, @Valid @RequestBody UpdateLibraryEntryRequest request) {
        return service.update(current.require().getId(), bookId, request);
    }
    @DeleteMapping("/{bookId}") @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long bookId) { service.delete(current.require().getId(), bookId); }
}
