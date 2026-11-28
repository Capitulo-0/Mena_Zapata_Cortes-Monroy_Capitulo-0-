package com.capitulo0.backend.social.service;

import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.catalog.book.repository.BookRepository;
import com.capitulo0.backend.common.exception.ApiException;
import com.capitulo0.backend.social.dto.*;
import com.capitulo0.backend.social.entity.BookReview;
import com.capitulo0.backend.social.entity.ReviewVisibility;
import com.capitulo0.backend.social.repository.BookReviewRepository;
import com.capitulo0.backend.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.HashMap;
import com.capitulo0.backend.catalog.book.entity.Book;
import java.util.Objects;
import java.util.Optional;

@Service
public class BookReviewService {
    private final BookReviewRepository reviews;
    private final BookRepository books;
    private final UserRepository users;
    private final CurrentUserService current;

    public BookReviewService(BookReviewRepository reviews, BookRepository books,
                             UserRepository users, CurrentUserService current) {
        this.reviews = reviews;
        this.books = books;
        this.users = users;
        this.current = current;
    }

    @Transactional(readOnly = true)
    public List<BookReviewResponse> list(Long bookId) {
        Long viewer = current.require().getId();
        requireBook(bookId);
        return reviews.findByBookIdAndVisibilityInAndReviewTextIsNotNullOrderByUpdatedAtDescIdDesc(
                bookId, List.of(ReviewVisibility.PUBLIC, ReviewVisibility.ANONYMOUS))
                .stream().filter(r -> r.getReviewText() != null && !r.getReviewText().isBlank())
                .map(r -> publicResponse(r, viewer)).toList();
    }

    @Transactional(readOnly = true)
    public BookRatingSummaryResponse summary(Long bookId) {
        current.require();
        requireBook(bookId);
        Double average = reviews.averageRating(bookId);
        return new BookRatingSummaryResponse(bookId, average == null ? 0.0 : average,
                reviews.countByBookId(bookId));
    }

    @Transactional(readOnly = true)
    public Optional<OwnBookReviewResponse> own(Long bookId) {
        Long owner = current.require().getId();
        requireBook(bookId);
        return reviews.findByBookIdAndUserId(bookId, owner).map(this::ownResponse);
    }

    @Transactional(readOnly = true)
    public List<OwnBookReviewEntryResponse> listOwn() {
        Long owner = current.require().getId();
        var entries = reviews.findByUserIdOrderByUpdatedAtDescIdDesc(owner);
        if (entries.isEmpty()) return List.of();
        var byId = new HashMap<Long, Book>();
        books.findAllById(entries.stream().map(BookReview::getBookId).distinct().toList())
                .forEach(book -> byId.put(book.getId(), book));
        return entries.stream().map(review -> {
            Book book = byId.get(review.getBookId());
            if (book == null) throw ApiException.notFound("Libro");
            return new OwnBookReviewEntryResponse(ownResponse(review), book.getTitle(),
                    book.getAuthor(), book.getCoverUrl(), book.getGoogleVolumeId());
        }).toList();
    }

    @Transactional
    public OwnBookReviewResponse upsert(Long bookId, UpsertBookReviewRequest request) {
        Long owner = current.require().getId();
        requireBook(bookId);
        if (request == null || request.rating() == null || request.rating() < 1
                || request.rating() > 5 || request.visibility() == null) {
            throw ApiException.invalid("Calificacion o visibilidad no valida");
        }
        String text = request.reviewText();
        if (text != null) {
            if (text.length() > 500 || text.indexOf(0) >= 0) {
                throw ApiException.invalid("Resena no valida");
            }
            text = text.isBlank() ? null : text.strip();
        }
        reviews.upsert(bookId, owner, request.rating(), text, request.visibility().name());
        return reviews.findByBookIdAndUserId(bookId, owner).map(this::ownResponse)
                .orElseThrow(() -> ApiException.notFound("Resena"));
    }

    @Transactional
    public void delete(Long bookId) {
        Long owner = current.require().getId();
        requireBook(bookId);
        reviews.removeOwnReview(bookId, owner);
    }

    private void requireBook(Long bookId) {
        if (bookId == null || !books.existsById(bookId)) {
            throw ApiException.notFound("Libro");
        }
    }

    private OwnBookReviewResponse ownResponse(BookReview r) {
        return new OwnBookReviewResponse(r.getId(), r.getBookId(), r.getRating(),
                r.getReviewText(), r.getVisibility(), r.getCreatedAt(), r.getUpdatedAt());
    }

    private BookReviewResponse publicResponse(BookReview r, Long viewer) {
        String username = null;
        String avatar = null;
        if (r.getVisibility() == ReviewVisibility.PUBLIC) {
            var author = users.findById(r.getUserId()).orElse(null);
            if (author != null) {
                username = author.getUsername();
                avatar = author.getAvatarUrl();
            }
        }
        return new BookReviewResponse(r.getId(), r.getBookId(), r.getRating(),
                r.getReviewText(), r.getVisibility(), username, avatar,
                Objects.equals(r.getUserId(), viewer), r.getCreatedAt(), r.getUpdatedAt());
    }
}
