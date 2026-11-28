package com.capitulo0.backend.social.repository;

import com.capitulo0.backend.social.entity.ChapterComment;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface ChapterCommentRepository extends JpaRepository<ChapterComment, Long> {
    List<ChapterComment> findByStoryKeyAndChapterIdOrderByCreatedAtAscIdAsc(String storyKey, String chapterId);
    Optional<ChapterComment> findByIdAndStoryKeyAndChapterId(Long id, String storyKey, String chapterId);
}
