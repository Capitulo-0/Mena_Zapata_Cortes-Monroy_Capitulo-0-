package com.capitulo0.backend.library.repository;

import com.capitulo0.backend.library.entity.SavedCommunityStory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

public interface SavedCommunityStoryRepository extends JpaRepository<SavedCommunityStory, SavedCommunityStory.Key> {
    List<SavedCommunityStory> findByUserId(Long userId);

    @Modifying
    @Query(value = "INSERT INTO saved_community_stories (user_id, story_key) VALUES (:userId, :storyKey) ON CONFLICT DO NOTHING", nativeQuery = true)
    void saveIfMissing(@Param("userId") Long userId, @Param("storyKey") String storyKey);
}
