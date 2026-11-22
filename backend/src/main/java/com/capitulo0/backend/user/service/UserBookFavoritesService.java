package com.capitulo0.backend.user.service;

import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.catalog.book.dto.BookResponse;
import com.capitulo0.backend.catalog.book.mapper.BookMapper;
import com.capitulo0.backend.catalog.book.repository.BookRepository;
import com.capitulo0.backend.common.exception.ApiException;
import com.capitulo0.backend.user.entity.User;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserBookFavoritesService {
    private final JdbcTemplate jdbc;
    private final BookRepository books;
    private final CurrentUserService current;

    public UserBookFavoritesService(JdbcTemplate jdbc, BookRepository books, CurrentUserService current) {
        this.jdbc = jdbc;
        this.books = books;
        this.current = current;
    }

    @Transactional(readOnly = true)
    public List<BookResponse> forOwner(Long ownerId) {
        List<Long> ids = jdbc.queryForList(
            "SELECT book_id FROM user_book_favorites WHERE user_id = ? ORDER BY created_at DESC, book_id DESC",
            Long.class, ownerId
        );
        return ids.stream().map(books::findById).filter(java.util.Optional::isPresent)
            .map(value -> BookMapper.toResponse(value.orElseThrow())).toList();
    }

    @Transactional(readOnly = true)
    public List<Long> mine() {
        User user = current.require();
        return jdbc.queryForList(
            "SELECT book_id FROM user_book_favorites WHERE user_id = ? ORDER BY created_at DESC, book_id DESC",
            Long.class, user.getId()
        );
    }

    @Transactional
    public void add(Long bookId) {
        if (bookId == null || bookId <= 0 || !books.existsById(bookId)) {
            throw ApiException.notFound("Libro");
        }
        jdbc.update(
            "INSERT INTO user_book_favorites (user_id, book_id) VALUES (?, ?) ON CONFLICT DO NOTHING",
            current.require().getId(), bookId
        );
    }

    @Transactional
    public void remove(Long bookId) {
        jdbc.update("DELETE FROM user_book_favorites WHERE user_id = ? AND book_id = ?",
            current.require().getId(), bookId);
    }
}
