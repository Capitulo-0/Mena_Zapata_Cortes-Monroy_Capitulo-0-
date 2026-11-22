package com.capitulo0.backend.user.dto;

import com.capitulo0.backend.catalog.book.dto.BookResponse;
import com.capitulo0.backend.library.dto.LibraryEntryResponse;
import com.capitulo0.backend.readingclub.dto.ReadingClubResponse;
import com.capitulo0.backend.writer.WriterDocument;
import java.util.List;

/** Datos del propietario accesibles únicamente tras verificar su privacidad. */
public record PublicProfileActivityResponse(
    int annualGoal,
    List<LibraryEntryResponse> library,
    List<BookResponse> favoriteBooks,
    List<ReadingClubResponse> clubs,
    List<WriterDocument> publishedStories
) {}
