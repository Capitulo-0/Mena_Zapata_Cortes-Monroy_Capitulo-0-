package com.capitulo0.backend.social.dto;

import java.time.Instant;

public record BookCommentResponse(
    Long id,
    Long bookId,
    Long parentId,
    String content,
    String username,
    String avatarUrl,
    boolean anonymous,
    boolean ownComment,
    boolean deleted,
    long likeCount,
    boolean likedByMe,
    long replyCount,
    Instant createdAt,
    Instant updatedAt
) {
    public BookCommentResponse {
        if (deleted) {
            content = null;
            username = null;
            avatarUrl = null;
            ownComment = false;
            likeCount = 0;
            likedByMe = false;
        } else if (anonymous) {
            username = "@anonimo";
            avatarUrl = null;
        }
    }
}
