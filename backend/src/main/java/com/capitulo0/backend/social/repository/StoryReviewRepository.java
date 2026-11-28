package com.capitulo0.backend.social.repository;

import com.capitulo0.backend.social.entity.StoryReview;
import com.capitulo0.backend.social.entity.ReviewVisibility;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface StoryReviewRepository extends JpaRepository<StoryReview, Long> {
    Optional<StoryReview> findByStoryKeyAndUserId(String storyKey, Long userId);
    List<StoryReview> findByStoryKeyAndVisibilityInAndReviewTextIsNotNullOrderByUpdatedAtDescIdDesc(
            String storyKey, Collection<ReviewVisibility> visibilities);
    long countByStoryKey(String storyKey);

    @Query("SELECT AVG(r.rating) FROM StoryReview r WHERE r.storyKey = :storyKey")
    Double averageRating(@Param("storyKey") String storyKey);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query(value = """
            INSERT INTO story_reviews (story_key, user_id, rating, review_text, visibility)
            VALUES (:storyKey, :userId, :rating, :reviewText, :visibility)
            ON CONFLICT (story_key, user_id) DO UPDATE SET
                rating = EXCLUDED.rating,
                review_text = EXCLUDED.review_text,
                visibility = EXCLUDED.visibility,
                updated_at = NOW()
            """, nativeQuery = true)
    int upsert(@Param("storyKey") String storyKey, @Param("userId") Long userId,
               @Param("rating") int rating, @Param("reviewText") String reviewText,
               @Param("visibility") String visibility);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("DELETE FROM StoryReview r WHERE r.storyKey = :storyKey AND r.userId = :userId")
    int removeOwnReview(@Param("storyKey") String storyKey, @Param("userId") Long userId);
}
