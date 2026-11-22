package com.capitulo0.backend.admin.dto;

import com.capitulo0.backend.verification.entity.OrganizerVerificationRequest;
import com.capitulo0.backend.verification.entity.VerificationStatus;
import java.time.Instant;

public record AdminVerificationResponse(
        Long id,
        Long userId,
        String representativeName,
        String organizationName,
        String organizationRut,
        String city,
        String publicAddress,
        String contactEmail,
        String contactPhone,
        String socialUrl,
        String organizationDescription,
        VerificationStatus status,
        Long reviewedBy,
        String reviewReason,
        Instant createdAt,
        Instant reviewedAt
) {
    public static AdminVerificationResponse from(
            OrganizerVerificationRequest request
    ) {
        return new AdminVerificationResponse(
                request.getId(),
                request.getUserId(),
                request.getRepresentativeName(),
                request.getOrganizationName(),
                request.getOrganizationRut(),
                request.getCity(),
                request.getPublicAddress(),
                request.getContactEmail(),
                request.getContactPhone(),
                request.getSocialUrl(),
                request.getOrganizationDescription(),
                request.getStatus(),
                request.getReviewedBy(),
                request.getReviewReason(),
                request.getCreatedAt(),
                request.getReviewedAt()
        );
    }
}
