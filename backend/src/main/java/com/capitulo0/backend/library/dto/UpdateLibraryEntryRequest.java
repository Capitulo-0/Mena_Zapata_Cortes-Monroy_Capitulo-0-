package com.capitulo0.backend.library.dto;
import jakarta.validation.constraints.*;
import com.capitulo0.backend.library.entity.*;
public record UpdateLibraryEntryRequest(ReadingStatus status,
    ReadingFormat readingFormat, @PositiveOrZero Integer currentPage,
    @Positive Integer totalPages, @Size(max = 300) String publisherOverride) {}
