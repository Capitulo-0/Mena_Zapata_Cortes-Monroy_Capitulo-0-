package com.capitulo0.backend.readingclub.repository;

import com.capitulo0.backend.readingclub.entity.ClubMembership;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ClubMembershipRepository
        extends JpaRepository<ClubMembership, Long> {

    List<ClubMembership> findByUserIdOrderByCreatedAtDescIdDesc(
            Long userId
    );

    boolean existsByClubIdAndUserId(
            Long clubId,
            Long userId
    );

    Optional<ClubMembership> findByClubIdAndUserId(
            Long clubId,
            Long userId
    );

    long countByClubId(Long clubId);
}
