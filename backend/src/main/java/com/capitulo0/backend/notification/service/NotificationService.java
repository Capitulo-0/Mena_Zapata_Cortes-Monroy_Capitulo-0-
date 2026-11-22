package com.capitulo0.backend.notification.service;

import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.common.exception.ApiException;
import com.capitulo0.backend.notification.dto.NotificationResponse;
import com.capitulo0.backend.notification.entity.UserNotification;
import com.capitulo0.backend.notification.repository.UserNotificationRepository;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.repository.UserRepository;
import java.time.Instant;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Operations on the authenticated user's in-app notification inbox. */
@Service
public class NotificationService {

    private final CurrentUserService current;
    private final UserNotificationRepository notifications;
    private final UserRepository users;

    public NotificationService(
            CurrentUserService current,
            UserNotificationRepository notifications,
            UserRepository users
    ) {
        this.current = current;
        this.notifications = notifications;
        this.users = users;
    }

    /** The recipient is always obtained from the verified Firebase identity. */
    @Transactional(readOnly = true)
    public Page<NotificationResponse> inbox(Pageable pageable) {
        Long recipientId = current.require().getId();
        Page<UserNotification> page = notifications
                .findByRecipientIdOrderByOccurredAtDescIdDesc(recipientId, pageable);

        // Load all actors of this page at once instead of querying once per notification.
        Set<Long> actorIds = page.getContent().stream()
                .map(UserNotification::getActorId)
                .collect(Collectors.toSet());
        Map<Long, User> actors = users.findAllById(actorIds).stream()
                .collect(Collectors.toMap(User::getId, Function.identity()));

        return page.map(notification -> toResponse(notification, actors.get(notification.getActorId())));
    }

    @Transactional(readOnly = true)
    public long unreadCount() {
        return notifications.countByRecipientIdAndReadAtIsNull(current.require().getId());
    }

    /** Idempotent: marking an already read notification does not change its original read date. */
    @Transactional
    public NotificationResponse markRead(Long notificationId) {
        Long recipientId = current.require().getId();
        UserNotification notification = notifications.findByIdAndRecipientId(notificationId, recipientId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Notificación no encontrada"));
        notification.markRead(Instant.now());
        User actor = users.findById(notification.getActorId()).orElse(null);
        return toResponse(notification, actor);
    }

    private NotificationResponse toResponse(UserNotification notification, User actor) {
        return new NotificationResponse(
                notification.getId(),
                notification.getType(),
                notification.getActorId(),
                actor == null ? null : actor.getUsername(),
                actor == null ? null : actor.getDisplayName(),
                actor == null ? null : actor.getAvatarUrl(),
                notification.getFollowId(),
                notification.getCreatedAt(),
                notification.getOccurredAt(),
                notification.getReadAt()
        );
    }
}
