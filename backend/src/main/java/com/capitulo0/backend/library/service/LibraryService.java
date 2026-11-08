package com.capitulo0.backend.library.service;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.capitulo0.backend.library.dto.*;
import com.capitulo0.backend.library.entity.*;
import com.capitulo0.backend.library.mapper.LibraryEntryMapper;
import com.capitulo0.backend.library.repository.LibraryEntryRepository;
import com.capitulo0.backend.user.service.UserService;
import com.capitulo0.backend.catalog.book.service.BookService;
import com.capitulo0.backend.common.exception.ApiException;
@Service
@Transactional(readOnly = true)
public class LibraryService {
    private final LibraryEntryRepository entries;
    private final UserService users;
    private final BookService books;
    public LibraryService(LibraryEntryRepository entries, UserService users, BookService books) {
        this.entries = entries; this.users = users; this.books = books;
    }
    public List<LibraryEntryResponse> list(Long userId) {
        users.require(userId);
        return entries.findByUserIdOrderByIdAsc(userId).stream().map(LibraryEntryMapper::toResponse).toList();
    }
    @Transactional
    public LibraryEntryResponse add(Long userId, AddLibraryEntryRequest request) {
        var user = users.require(userId);
        var book = books.require(request.bookId());
        if (entries.existsByUserIdAndBookId(userId, book.getId())) throw ApiException.conflict("El libro ya está en la biblioteca");
        LibraryEntry entry = LibraryEntry.create(); entry.setUser(user); entry.setBook(book);
        entry.setStatus(request.status() == null ? ReadingStatus.POR_LEER : request.status());
        entry.setReadingFormat(request.readingFormat() == null ? ReadingFormat.FISICO : request.readingFormat());
        entry.setCurrentPage(request.currentPage() == null ? 0 : request.currentPage());
        entry.setTotalPages(request.totalPages() == null ? book.getTotalPages() : request.totalPages());
        entry.setPublisherOverride(request.publisherOverride());
        normalize(entry);
        return LibraryEntryMapper.toResponse(entries.saveAndFlush(entry));
    }
    @Transactional
    public LibraryEntryResponse update(Long userId, Long bookId, UpdateLibraryEntryRequest request) {
        LibraryEntry entry = require(userId, bookId);
        if (request.status() != null) entry.setStatus(request.status());
        if (request.readingFormat() != null) entry.setReadingFormat(request.readingFormat());
        if (request.currentPage() != null) entry.setCurrentPage(request.currentPage());
        if (request.totalPages() != null) entry.setTotalPages(request.totalPages());
        if (request.publisherOverride() != null) entry.setPublisherOverride(request.publisherOverride());
        normalize(entry);
        return LibraryEntryMapper.toResponse(entries.saveAndFlush(entry));
    }
    @Transactional
    public void delete(Long userId, Long bookId) { entries.delete(require(userId, bookId)); }
    private LibraryEntry require(Long userId, Long bookId) {
        users.require(userId);
        return entries.findByUserIdAndBookId(userId, bookId).orElseThrow(() -> ApiException.notFound("Entrada de biblioteca"));
    }
    private void normalize(LibraryEntry entry) {
        Integer total = entry.getTotalPages();
        if (entry.getCurrentPage() < 0 || (total != null && total <= 0)) throw ApiException.invalid("Páginas no válidas");
        if (total != null && entry.getCurrentPage() > total) throw ApiException.invalid("La página actual supera el total de páginas");
        if (entry.getStatus() == ReadingStatus.POR_LEER) entry.setCurrentPage(0);
        if (entry.getStatus() == ReadingStatus.LEIDO && total != null) entry.setCurrentPage(total);
    }
}
