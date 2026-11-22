package com.capitulo0.backend.catalog.book.service;
import java.util.List;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.capitulo0.backend.catalog.book.repository.BookRepository;
import com.capitulo0.backend.catalog.book.entity.Book;
import com.capitulo0.backend.catalog.book.dto.*;
import com.capitulo0.backend.catalog.book.mapper.BookMapper;
import com.capitulo0.backend.common.exception.ApiException;
@Service
@Transactional(readOnly = true)
public class BookService {
    private final BookRepository books;
    public BookService(BookRepository books) { this.books = books; }
    public Book require(Long id) { return books.findById(id).orElseThrow(() -> ApiException.notFound("Libro")); }
    public BookResponse get(Long id) { return BookMapper.toResponse(require(id)); }
    public List<BookResponse> list() { return books.findAll(Sort.by("id")).stream().map(BookMapper::toResponse).toList(); }
    @Transactional
    public BookResponse create(CreateBookRequest request) {
        Book book = Book.create();
        book.setTitle(request.title().strip()); book.setAuthor(request.author()); book.setSynopsis(request.synopsis());
        book.setIsbn(request.isbn()); book.setPublisher(request.publisher()); book.setTotalPages(request.totalPages());
        book.setPublicationYear(request.publicationYear()); book.setCoverUrl(request.coverUrl());
        return BookMapper.toResponse(books.saveAndFlush(book));
    }
}
