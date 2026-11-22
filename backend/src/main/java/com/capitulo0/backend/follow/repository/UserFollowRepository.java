package com.capitulo0.backend.follow.repository;

import com.capitulo0.backend.follow.entity.UserFollow;
import com.capitulo0.backend.follow.entity.UserFollow.Status;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

/** Database access for directional follow relationships. */
public interface UserFollowRepository extends JpaRepository<UserFollow, Long> {

    /** A pair is unique, regardless of whether the request is pending or accepted. */
    Optional<UserFollow> findByFollowerIdAndFollowingId(Long followerId, Long followingId);

    /** Only the recipient of a follow request may authorize or reject it. */
    Optional<UserFollow> findByIdAndFollowingId(Long id, Long followingId);

    /** Pending requests addressed to an account, newest first. */
    Page<UserFollow> findByFollowingIdAndStatusOrderByCreatedAtDescIdDesc(
            Long followingId, Status status, Pageable pageable);

    /** Accepted followers of an account. */
    Page<UserFollow> findByFollowingIdAndStatusOrderByAcceptedAtDescIdDesc(
            Long followingId, Status status, Pageable pageable);

    /** Accounts followed by a reader, limited to accepted relationships. */
    Page<UserFollow> findByFollowerIdAndStatusOrderByAcceptedAtDescIdDesc(
            Long followerId, Status status, Pageable pageable);

    long countByFollowingIdAndStatus(Long followingId, Status status);

    long countByFollowerIdAndStatus(Long followerId, Status status);
}
