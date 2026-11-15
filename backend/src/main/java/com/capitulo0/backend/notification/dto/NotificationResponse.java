package com.capitulo0.backend.notification.dto;

import com.capitulo0.backend.notification.entity.NotificationType;
import java.time.Instant;

/**
 * Public data for one item in the authenticated user's notification inbox.
 *
 * The service resolves actor details from the database. Never accept the
 * recipient ID from the client or expose it in this response.
 */
public record NotificationResponse(
        Long id,
        NotificationType type,
        Long actorId,
        String actorUsername,
        String actorDisplayName,
        String actorAvatarUrl,
        Long followId,
        Instant createdAt,
        Instant occurredAt,
        Instant readAt
) {
}
