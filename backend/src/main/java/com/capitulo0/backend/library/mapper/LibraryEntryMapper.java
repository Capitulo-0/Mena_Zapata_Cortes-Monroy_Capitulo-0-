package com.capitulo0.backend.library.mapper;
import java.math.BigDecimal;
import java.math.RoundingMode;
import com.capitulo0.backend.library.entity.*;
import com.capitulo0.backend.library.dto.LibraryEntryResponse;
import com.capitulo0.backend.catalog.book.mapper.BookMapper;
public final class LibraryEntryMapper {
    private LibraryEntryMapper() {}
    public static LibraryEntryResponse toResponse(LibraryEntry entry) {
        BigDecimal percentage = entry.getTotalPages() == null ?
            (entry.getStatus() == ReadingStatus.LEIDO ? BigDecimal.valueOf(100) : BigDecimal.ZERO) :
            BigDecimal.valueOf(entry.getCurrentPage()).multiply(BigDecimal.valueOf(100))
                .divide(BigDecimal.valueOf(entry.getTotalPages()), 2, RoundingMode.HALF_UP);
        return new LibraryEntryResponse(entry.getId(), entry.getUser().getId(), BookMapper.toResponse(entry.getBook()),
            entry.getStatus(), entry.getReadingFormat(), entry.getCurrentPage(), entry.getTotalPages(),
            entry.getPublisherOverride(), percentage, entry.getCreatedAt(), entry.getUpdatedAt());
    }
}
