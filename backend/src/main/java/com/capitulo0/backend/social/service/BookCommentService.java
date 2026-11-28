package com.capitulo0.backend.social.service;

import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.catalog.book.repository.BookRepository;
import com.capitulo0.backend.common.exception.ApiException;
import com.capitulo0.backend.social.dto.*;
import com.capitulo0.backend.social.entity.BookComment;
import com.capitulo0.backend.social.repository.*;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Service
public class BookCommentService {
    private final BookCommentRepository comments;
    private final BookCommentLikeRepository likes;
    private final BookCommentReportRepository reports;
    private final BookRepository books;
    private final UserRepository users;
    private final CurrentUserService current;

    public BookCommentService(BookCommentRepository comments, BookCommentLikeRepository likes,
                              BookCommentReportRepository reports, BookRepository books,
                              UserRepository users, CurrentUserService current) {
        this.comments = comments;
        this.likes = likes;
        this.reports = reports;
        this.books = books;
        this.users = users;
        this.current = current;
    }

    @Transactional(readOnly = true)
    public List<BookCommentResponse> list(Long bookId) {
        Long viewer = current.require().getId();
        requireBook(bookId);
        List<BookComment> visible = visibleComments(bookId);
        Map<Long, Long> replyCounts = new HashMap<>();
        for (BookComment comment : visible) {
            if (comment.getParentId() != null) {
                replyCounts.merge(comment.getParentId(), 1L, Long::sum);
            }
        }
        Map<Long, User> authors = new HashMap<>();
        return visible.stream().map(comment -> response(comment, viewer,
                replyCounts.getOrDefault(comment.getId(), 0L), authors)).toList();
    }

    @Transactional
    public BookCommentResponse create(Long bookId, CreateBookCommentRequest request) {
        Long owner = current.require().getId();
        requireBook(bookId);
        String content = validatedText(request.content(), 300);
        if (request.parentId() != null) {
            requireActive(bookId, request.parentId());
        }
        BookComment saved = comments.saveAndFlush(new BookComment(bookId, owner,
                request.parentId(), content, request.anonymous()));
        return response(saved, owner, 0, new HashMap<>());
    }

    @Transactional
    public BookCommentResponse update(Long bookId, Long commentId, UpdateBookCommentRequest request) {
        Long owner = current.require().getId();
        BookComment comment = requireActive(bookId, commentId);
        requireOwner(comment, owner);
        comment.edit(validatedText(request.content(), 300), request.anonymous());
        comments.saveAndFlush(comment);
        return response(comment, owner, replyCount(bookId, commentId), new HashMap<>());
    }

    @Transactional
    public void delete(Long bookId, Long commentId) {
        Long owner = current.require().getId();
        BookComment comment = requireComment(bookId, commentId);
        requireOwner(comment, owner);
        if (!comment.isDeleted()) {
            comment.markDeleted();
            comments.saveAndFlush(comment);
        }
    }

    @Transactional
    public void like(Long bookId, Long commentId) {
        Long owner = current.require().getId();
        requireActive(bookId, commentId);
        likes.saveIfMissing(commentId, owner);
    }

    @Transactional
    public void unlike(Long bookId, Long commentId) {
        Long owner = current.require().getId();
        requireActive(bookId, commentId);
        likes.removeLike(commentId, owner);
    }

    @Transactional
    public void report(Long bookId, Long commentId, BookCommentReportRequest request) {
        Long owner = current.require().getId();
        requireActive(bookId, commentId);
        reports.saveIfMissing(commentId, owner, validatedText(request.reason(), 500));
    }

    private void requireBook(Long bookId) {
        if (bookId == null || !books.existsById(bookId)) {
            throw ApiException.notFound("Libro");
        }
    }

    private BookComment requireComment(Long bookId, Long commentId) {
        return comments.findByIdAndBookId(commentId, bookId)
                .orElseThrow(() -> ApiException.notFound("Comentario"));
    }

    private BookComment requireActive(Long bookId, Long commentId) {
        BookComment comment = requireComment(bookId, commentId);
        if (comment.isDeleted() || comment.isHidden()) {
            throw ApiException.notFound("Comentario");
        }
        Set<Long> visited = new HashSet<>();
        BookComment ancestor = comment;
        while (ancestor.getParentId() != null) {
            if (!visited.add(ancestor.getId())) {
                throw ApiException.notFound("Comentario");
            }
            ancestor = requireComment(bookId, ancestor.getParentId());
            if (ancestor.isHidden()) {
                throw ApiException.notFound("Comentario");
            }
        }
        return comment;
    }

    private void requireOwner(BookComment comment, Long owner) {
        if (!Objects.equals(comment.getUserId(), owner)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Acceso denegado");
        }
    }

    private String validatedText(String text, int maxLength) {
        if (text == null || text.isBlank() || text.length() > maxLength || text.indexOf('\0') >= 0) {
            throw ApiException.invalid("Contenido no valido");
        }
        return text.strip();
    }

    private List<BookComment> visibleComments(Long bookId) {
        List<BookComment> all = comments.findByBookIdOrderByCreatedAtAscIdAsc(bookId);
        Map<Long, BookComment> byId = new HashMap<>();
        for (BookComment comment : all) byId.put(comment.getId(), comment);
        return all.stream().filter(comment -> {
            Set<Long> visited = new HashSet<>();
            BookComment node = comment;
            while (node != null) {
                if (node.isHidden() || !visited.add(node.getId())) return false;
                if (node.getParentId() == null) return true;
                node = byId.get(node.getParentId());
            }
            return false;
        }).toList();
    }

    private long replyCount(Long bookId, Long commentId) {
        return visibleComments(bookId).stream()
                .filter(comment -> Objects.equals(comment.getParentId(), commentId)).count();
    }

    private BookCommentResponse response(BookComment comment, Long viewer, long replies,
                                         Map<Long, User> authors) {
        boolean deleted = comment.isDeleted();
        boolean anonymous = comment.isAnonymous();
        String username = null;
        String avatar = null;
        if (!deleted && !anonymous) {
            User author = authors.computeIfAbsent(comment.getUserId(),
                    id -> users.findById(id).orElse(null));
            if (author != null) {
                username = author.getUsername();
                avatar = author.getAvatarUrl();
            }
        }
        return new BookCommentResponse(comment.getId(), comment.getBookId(), comment.getParentId(),
                deleted ? null : comment.getContent(), username, avatar, anonymous,
                !deleted && Objects.equals(comment.getUserId(), viewer), deleted,
                deleted ? 0 : likes.countByCommentId(comment.getId()),
                !deleted && likes.existsByCommentIdAndUserId(comment.getId(), viewer),
                replies, comment.getCreatedAt(), comment.getUpdatedAt());
    }
}
