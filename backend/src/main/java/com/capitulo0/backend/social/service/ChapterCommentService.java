package com.capitulo0.backend.social.service;

import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.writer.WriterService;
import com.capitulo0.backend.writer.WriterStoryRepository;
import com.capitulo0.backend.common.exception.ApiException;
import com.capitulo0.backend.social.dto.*;
import com.capitulo0.backend.social.entity.ChapterComment;
import com.capitulo0.backend.social.repository.*;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Service
public class ChapterCommentService {
    private final ChapterCommentRepository comments;
    private final ChapterCommentLikeRepository likes;
    private final ChapterCommentReportRepository reports;
    private final WriterService writer;
    private final WriterStoryRepository stories;
    private final UserRepository users;
    private final CurrentUserService current;

    public ChapterCommentService(ChapterCommentRepository comments, ChapterCommentLikeRepository likes,
                              ChapterCommentReportRepository reports, WriterService writer, WriterStoryRepository stories,
                              UserRepository users, CurrentUserService current) {
        this.comments = comments;
        this.likes = likes;
        this.reports = reports;
        this.writer = writer;
        this.stories = stories;
        this.users = users;
        this.current = current;
    }

    @Transactional(readOnly = true)
    public List<ChapterCommentResponse> list(String storyKey, String chapterId) {
        Long viewer = current.require().getId();
        requireChapter(storyKey, chapterId);
        boolean moderator = canModerate(storyKey, viewer);
        List<ChapterComment> visible = moderator
                ? comments.findByStoryKeyAndChapterIdOrderByCreatedAtAscIdAsc(storyKey, chapterId)
                : visibleComments(storyKey, chapterId);
        Map<Long, Long> replyCounts = new HashMap<>();
        for (ChapterComment comment : visible) {
            if (comment.getParentId() != null) {
                replyCounts.merge(comment.getParentId(), 1L, Long::sum);
            }
        }
        Map<Long, User> authors = new HashMap<>();
        return visible.stream().map(comment -> response(comment, viewer,
                replyCounts.getOrDefault(comment.getId(), 0L), authors, moderator)).toList();
    }

    @Transactional
    public ChapterCommentResponse create(String storyKey, String chapterId, CreateChapterCommentRequest request) {
        Long owner = current.require().getId();
        requireChapter(storyKey, chapterId);
        String content = validatedText(request.content(), 220);
        if (request.parentId() != null) {
            requireActive(storyKey, chapterId, request.parentId());
        }
        ChapterComment saved = comments.saveAndFlush(new ChapterComment(storyKey, chapterId, owner,
                request.parentId(), content, request.anonymous()));
        return response(saved, owner, 0, new HashMap<>(), canModerate(storyKey, owner));
    }

    @Transactional
    public ChapterCommentResponse update(String storyKey, String chapterId, Long commentId, UpdateChapterCommentRequest request) {
        Long owner = current.require().getId();
        requireChapter(storyKey, chapterId);
        ChapterComment comment = requireActive(storyKey, chapterId, commentId);
        requireOwner(comment, owner);
        comment.edit(validatedText(request.content(), 220), request.anonymous());
        comments.saveAndFlush(comment);
        return response(comment, owner, replyCount(storyKey, chapterId, commentId), new HashMap<>(), canModerate(storyKey, owner));
    }

    @Transactional
    public void delete(String storyKey, String chapterId, Long commentId) {
        Long owner = current.require().getId();
        requireChapter(storyKey, chapterId);
        ChapterComment comment = requireComment(storyKey, chapterId, commentId);
        requireOwner(comment, owner);
        if (!comment.isDeleted()) {
            comment.markDeleted();
            comments.saveAndFlush(comment);
        }
    }

    @Transactional
    public void like(String storyKey, String chapterId, Long commentId) {
        Long owner = current.require().getId();
        requireChapter(storyKey, chapterId);
        requireActive(storyKey, chapterId, commentId);
        likes.saveIfMissing(commentId, owner);
    }

    @Transactional
    public void unlike(String storyKey, String chapterId, Long commentId) {
        Long owner = current.require().getId();
        requireChapter(storyKey, chapterId);
        requireActive(storyKey, chapterId, commentId);
        likes.removeLike(commentId, owner);
    }

    @Transactional
    public void report(String storyKey, String chapterId, Long commentId, ChapterCommentReportRequest request) {
        Long owner = current.require().getId();
        requireChapter(storyKey, chapterId);
        requireActive(storyKey, chapterId, commentId);
        reports.saveIfMissing(commentId, owner, validatedText(request.reason(), 500));
    }

    private void requireChapter(String storyKey, String chapterId) {
        if (writer.published(storyKey).chapters().stream().noneMatch(c -> Objects.equals(c.id(), chapterId))) {
            throw ApiException.notFound("Capitulo");
        }
    }

    private boolean canModerate(String storyKey, Long viewer) {
        return stories.findByStoryKeyAndOwnerId(storyKey, viewer).isPresent();
    }

    @Transactional
    public void setVisibility(String storyKey, String chapterId, Long commentId, boolean hidden) {
        Long viewer = current.require().getId();
        requireChapter(storyKey, chapterId);
        if (!canModerate(storyKey, viewer)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Acceso denegado");
        }
        ChapterComment comment = requireComment(storyKey, chapterId, commentId);
        if (comment.isDeleted()) throw ApiException.notFound("Comentario");
        comment.setHidden(hidden);
        comments.saveAndFlush(comment);
    }

    private ChapterComment requireComment(String storyKey, String chapterId, Long commentId) {
        return comments.findByIdAndStoryKeyAndChapterId(commentId, storyKey, chapterId)
                .orElseThrow(() -> ApiException.notFound("Comentario"));
    }

    private ChapterComment requireActive(String storyKey, String chapterId, Long commentId) {
        ChapterComment comment = requireComment(storyKey, chapterId, commentId);
        if (comment.isDeleted() || comment.isHidden()) {
            throw ApiException.notFound("Comentario");
        }
        Set<Long> visited = new HashSet<>();
        ChapterComment ancestor = comment;
        while (ancestor.getParentId() != null) {
            if (!visited.add(ancestor.getId())) {
                throw ApiException.notFound("Comentario");
            }
            ancestor = requireComment(storyKey, chapterId, ancestor.getParentId());
            if (ancestor.isHidden()) {
                throw ApiException.notFound("Comentario");
            }
        }
        return comment;
    }

    private void requireOwner(ChapterComment comment, Long owner) {
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

    private List<ChapterComment> visibleComments(String storyKey, String chapterId) {
        List<ChapterComment> all = comments.findByStoryKeyAndChapterIdOrderByCreatedAtAscIdAsc(storyKey, chapterId);
        Map<Long, ChapterComment> byId = new HashMap<>();
        for (ChapterComment comment : all) byId.put(comment.getId(), comment);
        return all.stream().filter(comment -> {
            Set<Long> visited = new HashSet<>();
            ChapterComment node = comment;
            while (node != null) {
                if (node.isHidden() || !visited.add(node.getId())) return false;
                if (node.getParentId() == null) return true;
                node = byId.get(node.getParentId());
            }
            return false;
        }).toList();
    }

    private long replyCount(String storyKey, String chapterId, Long commentId) {
        return visibleComments(storyKey, chapterId).stream()
                .filter(comment -> Objects.equals(comment.getParentId(), commentId)).count();
    }

    private ChapterCommentResponse response(ChapterComment comment, Long viewer, long replies,
                                         Map<Long, User> authors, boolean canModerate) {
        boolean deleted = comment.isDeleted();
        boolean anonymous = comment.isAnonymous();
        String username = null;
        String avatar = null;
        if (!deleted && !comment.isHidden() && !anonymous) {
            User author = authors.computeIfAbsent(comment.getUserId(),
                    id -> users.findById(id).orElse(null));
            if (author != null) {
                username = author.getUsername();
                avatar = author.getAvatarUrl();
            }
        }
        return new ChapterCommentResponse(comment.getId(), comment.getStoryKey(), comment.getChapterId(), comment.getParentId(),
                deleted ? null : comment.getContent(), username, avatar, anonymous,
                !deleted && Objects.equals(comment.getUserId(), viewer), deleted, comment.isHidden(), canModerate,
                deleted ? 0 : likes.countByCommentId(comment.getId()),
                !deleted && likes.existsByCommentIdAndUserId(comment.getId(), viewer),
                replies, comment.getCreatedAt(), comment.getUpdatedAt());
    }
}
