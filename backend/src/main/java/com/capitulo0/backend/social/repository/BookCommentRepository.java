package com.capitulo0.backend.social.repository;

import com.capitulo0.backend.social.entity.BookComment;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface BookCommentRepository extends JpaRepository<BookComment, Long> {
    List<BookComment> findByBookIdOrderByCreatedAtAscIdAsc(Long bookId);
    Optional<BookComment> findByIdAndBookId(Long id, Long bookId);
}
