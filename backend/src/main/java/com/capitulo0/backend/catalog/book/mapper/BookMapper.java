package com.capitulo0.backend.catalog.book.mapper;
import com.capitulo0.backend.catalog.book.dto.BookResponse;
import com.capitulo0.backend.catalog.book.entity.Book;
public final class BookMapper {
    private BookMapper() {}
    public static BookResponse toResponse(Book book) {
        return new BookResponse(book.getId(), book.getTitle(), book.getAuthor(), book.getSynopsis(),
            book.getIsbn(), book.getPublisher(), book.getTotalPages(), book.getPublicationYear(),
            book.getCoverUrl(), book.getCreatedAt(), book.getUpdatedAt());
    }
}
