package com.capitulo0.backend.readingclub.repository;

import com.capitulo0.backend.readingclub.entity.ReadingClub;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReadingClubRepository
        extends JpaRepository<ReadingClub, Long> {

    List<ReadingClub> findByStatusOrderByCreatedAtDescIdDesc(
            String status
    );

    Page<ReadingClub> findByStatus(
            String status,
            Pageable pageable
    );

    List<ReadingClub> findByOrganizerUserIdOrderByCreatedAtDescIdDesc(
            Long organizerUserId
    );
}
