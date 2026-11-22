package com.capitulo0.backend.admin.service;

import com.capitulo0.backend.admin.dto.AdminVerificationResponse;
import com.capitulo0.backend.common.exception.ApiException;
import com.capitulo0.backend.notification.entity.NotificationType;
import com.capitulo0.backend.notification.entity.UserNotification;
import com.capitulo0.backend.notification.repository.UserNotificationRepository;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.verification.entity.OrganizerVerificationRequest;
import com.capitulo0.backend.verification.entity.VerificationStatus;
import com.capitulo0.backend.verification.repository.OrganizerVerificationRepository;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminVerificationService {

    private final AdminAuthorizationService authorization;
    private final OrganizerVerificationRepository requests;
    private final UserNotificationRepository notifications;

    public AdminVerificationService(
            AdminAuthorizationService authorization,
            OrganizerVerificationRepository requests,
            UserNotificationRepository notifications
    ) {
        this.authorization = authorization;
        this.requests = requests;
        this.notifications = notifications;
    }

    @Transactional(readOnly = true)
    public List<AdminVerificationResponse> pendingRequests() {
        authorization.requireAdmin();

        return requests
                .findByStatusOrderByCreatedAtAscIdAsc(
                        VerificationStatus.PENDING
                )
                .stream()
                .map(AdminVerificationResponse::from)
                .toList();
    }

    @Transactional
    public AdminVerificationResponse approve(Long requestId) {
        User admin = authorization.requireAdmin();

        OrganizerVerificationRequest request =
                requirePendingRequest(requestId);

        requireDifferentReviewer(admin.getId(), request.getUserId());

        if (requests.existsByUserIdAndStatus(
                request.getUserId(),
                VerificationStatus.APPROVED
        )) {
            throw ApiException.conflict(
                    "Este usuario ya tiene una verificación aprobada"
            );
        }

        request.approve(admin.getId());

        requests.saveAndFlush(request);

        createNotification(
                request.getUserId(),
                admin.getId(),
                NotificationType.ORGANIZER_APPROVED
        );

        return AdminVerificationResponse.from(request);
    }

    @Transactional
    public AdminVerificationResponse reject(
            Long requestId,
            String reason
    ) {
        User admin = authorization.requireAdmin();

        String cleanReason = reason == null
                ? ""
                : reason.strip();

        if (cleanReason.isEmpty() || cleanReason.length() > 1000) {
            throw new ApiException(
                    HttpStatus.BAD_REQUEST,
                    "Debes indicar un motivo de rechazo válido"
            );
        }

        OrganizerVerificationRequest request =
                requirePendingRequest(requestId);

        requireDifferentReviewer(admin.getId(), request.getUserId());

        request.reject(admin.getId(), cleanReason);

        requests.saveAndFlush(request);

        createNotification(
                request.getUserId(),
                admin.getId(),
                NotificationType.ORGANIZER_REJECTED
        );

        return AdminVerificationResponse.from(request);
    }

    private OrganizerVerificationRequest requirePendingRequest(
            Long requestId
    ) {
        OrganizerVerificationRequest request =
                requests.findByIdForUpdate(requestId)
                        .orElseThrow(
                                () -> new ApiException(
                                        HttpStatus.NOT_FOUND,
                                        "La solicitud no existe"
                                )
                        );

        if (request.getStatus() != VerificationStatus.PENDING) {
            throw ApiException.conflict(
                    "Esta solicitud ya fue revisada"
            );
        }

        return request;
    }

    private void requireDifferentReviewer(
            Long adminId,
            Long applicantId
    ) {
        if (adminId.equals(applicantId)) {
            throw new ApiException(
                    HttpStatus.FORBIDDEN,
                    "No puedes revisar tu propia solicitud"
            );
        }
    }

    private void createNotification(
            Long recipientId,
            Long actorId,
            NotificationType type
    ) {
        UserNotification notification = new UserNotification(
                recipientId,
                actorId,
                null,
                type
        );

        notifications.saveAndFlush(notification);
    }
}
