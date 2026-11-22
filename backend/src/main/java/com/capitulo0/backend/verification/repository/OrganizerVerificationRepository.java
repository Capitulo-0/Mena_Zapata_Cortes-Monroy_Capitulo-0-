package com.capitulo0.backend.verification.repository;

import com.capitulo0.backend.verification.entity.OrganizerVerificationRequest;
import com.capitulo0.backend.verification.entity.VerificationStatus;
import jakarta.persistence.LockModeType;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface OrganizerVerificationRepository
        extends JpaRepository<OrganizerVerificationRequest, Long> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT r FROM OrganizerVerificationRequest r WHERE r.id = :id")
    Optional<OrganizerVerificationRequest> findByIdForUpdate(
            @Param("id") Long id
    );

    Optional<OrganizerVerificationRequest>
            findFirstByUserIdOrderByCreatedAtDescIdDesc(Long userId);

    boolean existsByUserIdAndStatus(
            Long userId,
            VerificationStatus status
    );

    List<OrganizerVerificationRequest>
            findByStatusOrderByCreatedAtAscIdAsc(
                    VerificationStatus status
            );
}
