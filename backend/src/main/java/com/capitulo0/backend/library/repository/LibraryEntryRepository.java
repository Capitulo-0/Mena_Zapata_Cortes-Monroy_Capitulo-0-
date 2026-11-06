package com.capitulo0.backend.library.repository;
import java.util.List;
import java.util.Optional;
import com.capitulo0.backend.library.entity.LibraryEntry;
import org.springframework.data.jpa.repository.JpaRepository;
public interface LibraryEntryRepository extends JpaRepository<LibraryEntry, Long> {
    boolean existsByUserIdAndBookId(Long userId, Long bookId);
    Optional<LibraryEntry> findByUserIdAndBookId(Long userId, Long bookId);
    List<LibraryEntry> findByUserIdOrderByIdAsc(Long userId);
}
