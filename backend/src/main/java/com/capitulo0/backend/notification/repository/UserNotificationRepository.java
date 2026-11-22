package com.capitulo0.backend.notification.repository;

import com.capitulo0.backend.notification.entity.NotificationType;
import com.capitulo0.backend.notification.entity.UserNotification;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Persistence operations for the in-app notification inbox.
 *
 * All inbox reads must be scoped to the authenticated recipient's user ID,
 * obtained in the service from CurrentUserService.require().getId().
 */
@Repository
public interface UserNotificationRepository extends JpaRepository<UserNotification, Long> {

    Page<UserNotification> findByRecipientIdOrderByOccurredAtDescIdDesc(
            Long recipientId,
            Pageable pageable
    );

    long countByRecipientIdAndReadAtIsNull(Long recipientId);

    Optional<UserNotification> findByIdAndRecipientId(Long id, Long recipientId);

    Optional<UserNotification> findFirstByFollowIdAndType(
            Long followId,
            NotificationType type
    );
}
