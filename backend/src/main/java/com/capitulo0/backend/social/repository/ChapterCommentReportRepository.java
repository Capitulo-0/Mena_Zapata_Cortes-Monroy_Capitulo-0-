package com.capitulo0.backend.social.repository;

import com.capitulo0.backend.social.entity.ChapterCommentReport;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ChapterCommentReportRepository extends JpaRepository<ChapterCommentReport, Long> {
    boolean existsByCommentIdAndUserId(Long commentId, Long userId);

    @Modifying
    @Query(value = "INSERT INTO chapter_comment_reports (comment_id, user_id, reason) VALUES (:commentId, :userId, :reason) ON CONFLICT (comment_id, user_id) DO NOTHING", nativeQuery = true)
    int saveIfMissing(@Param("commentId") Long commentId, @Param("userId") Long userId, @Param("reason") String reason);
}
