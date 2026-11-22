package com.capitulo0.backend.notification.controller;

import com.capitulo0.backend.notification.dto.NotificationResponse;
import com.capitulo0.backend.notification.service.NotificationService;
import java.util.Map;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** REST API for the authenticated reader's notification inbox. */
@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationService notifications;

    public NotificationController(NotificationService notifications) {
        this.notifications = notifications;
    }

    /** Most recent notifications first, scoped to the verified Firebase user. */
    @GetMapping
    public Page<NotificationResponse> inbox(
            @PageableDefault(size = 20) Pageable pageable
    ) {
        return notifications.inbox(pageable);
    }

    /** Number of notifications that have not been marked as read. */
    @GetMapping("/unread-count")
    public Map<String, Long> unreadCount() {
        return Map.of("count", notifications.unreadCount());
    }

    /** Mark one of the authenticated user's notifications as read. */
    @PatchMapping("/{id}/read")
    public NotificationResponse markRead(@PathVariable("id") Long id) {
        return notifications.markRead(id);
    }
}
