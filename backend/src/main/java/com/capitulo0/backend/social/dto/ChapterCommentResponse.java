package com.capitulo0.backend.social.dto;

import java.time.Instant;

public record ChapterCommentResponse(
    Long id,
    String storyKey,
    String chapterId,
    Long parentId,
    String content,
    String username,
    String avatarUrl,
    boolean anonymous,
    boolean ownComment,
    boolean deleted,
    boolean hidden,
    boolean canModerate,
    long likeCount,
    boolean likedByMe,
    long replyCount,
    Instant createdAt,
    Instant updatedAt
) {
    public ChapterCommentResponse {
        if (deleted || hidden) {
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
