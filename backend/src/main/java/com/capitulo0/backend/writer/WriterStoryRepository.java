package com.capitulo0.backend.writer;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
public interface WriterStoryRepository extends JpaRepository<WriterStoryEntity,Long> {
 Optional<WriterStoryEntity> findByStoryKey(String storyKey);
 List<WriterStoryEntity> findByOwnerIdNotOrderByUpdatedAtDesc(Long ownerId);
 List<WriterStoryEntity> findByOwnerIdOrderByUpdatedAtDesc(Long ownerId);
 Optional<WriterStoryEntity> findByStoryKeyAndOwnerId(String id,Long ownerId);
}
