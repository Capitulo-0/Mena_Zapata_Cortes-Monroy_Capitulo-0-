package com.capitulo0.backend.social.repository;

import com.capitulo0.backend.social.entity.BookReview;
import com.capitulo0.backend.social.entity.ReviewVisibility;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface BookReviewRepository extends JpaRepository<BookReview, Long> {
    Optional<BookReview> findByBookIdAndUserId(Long bookId, Long userId);
    List<BookReview> findByBookIdAndVisibilityInAndReviewTextIsNotNullOrderByUpdatedAtDescIdDesc(
            Long bookId, Collection<ReviewVisibility> visibilities);
    List<BookReview> findByUserIdOrderByUpdatedAtDescIdDesc(Long userId);
    long countByBookId(Long bookId);

    @Query("SELECT AVG(r.rating) FROM BookReview r WHERE r.bookId = :bookId")
    Double averageRating(@Param("bookId") Long bookId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query(value = """
            INSERT INTO book_reviews (book_id, user_id, rating, review_text, visibility)
            VALUES (:bookId, :userId, :rating, :reviewText, :visibility)
            ON CONFLICT (book_id, user_id) DO UPDATE SET
                rating = EXCLUDED.rating,
                review_text = EXCLUDED.review_text,
                visibility = EXCLUDED.visibility,
                updated_at = NOW()
            """, nativeQuery = true)
    int upsert(@Param("bookId") Long bookId, @Param("userId") Long userId,
               @Param("rating") int rating, @Param("reviewText") String reviewText,
               @Param("visibility") String visibility);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("DELETE FROM BookReview r WHERE r.bookId = :bookId AND r.userId = :userId")
    int removeOwnReview(@Param("bookId") Long bookId, @Param("userId") Long userId);
}
