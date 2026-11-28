package com.capitulo0.backend.social.repository;

import com.capitulo0.backend.social.entity.BookCommentLike;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface BookCommentLikeRepository extends JpaRepository<BookCommentLike, BookCommentLike.Key> {
    long countByCommentId(Long commentId);
    boolean existsByCommentIdAndUserId(Long commentId, Long userId);

    @Modifying
    @Query(value = "INSERT INTO book_comment_likes (comment_id, user_id) VALUES (:commentId, :userId) ON CONFLICT (comment_id, user_id) DO NOTHING", nativeQuery = true)
    int saveIfMissing(@Param("commentId") Long commentId, @Param("userId") Long userId);

    @Modifying
    @Query("DELETE FROM BookCommentLike l WHERE l.commentId = :commentId AND l.userId = :userId")
    int removeLike(@Param("commentId") Long commentId, @Param("userId") Long userId);
}
