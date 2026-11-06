package com.capitulo0.backend.catalog.book.dto;
import jakarta.validation.constraints.*;
public record CreateBookRequest(@NotBlank @Size(max = 500) String title,
    @Size(max = 300) String author, String synopsis, @Size(max = 32) String isbn,
    @Size(max = 300) String publisher, @Positive Integer totalPages,
    @Positive Integer publicationYear, @Size(max = 2048) String coverUrl) {}
