package com.capitulo0.backend.library.dto;
import java.time.Instant;
import java.math.BigDecimal;
import com.capitulo0.backend.catalog.book.dto.BookResponse;
import com.capitulo0.backend.library.entity.*;
public record LibraryEntryResponse(Long id, Long userId, BookResponse book,
    ReadingStatus status, ReadingFormat readingFormat, int currentPage, Integer totalPages,
    String publisherOverride, BigDecimal progressPercentage, Instant createdAt, Instant updatedAt) {}
