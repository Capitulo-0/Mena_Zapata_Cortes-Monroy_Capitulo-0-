package com.capitulo0.backend.catalog.book.dto;
import java.time.Instant;
public record BookResponse(Long id, String title, String author, String synopsis,
    String isbn, String publisher, Integer totalPages, Integer publicationYear,
    String coverUrl, Instant createdAt, Instant updatedAt, String googleVolumeId, com.capitulo0.backend.integration.googlebooks.GoogleBook googleBooks) {}
