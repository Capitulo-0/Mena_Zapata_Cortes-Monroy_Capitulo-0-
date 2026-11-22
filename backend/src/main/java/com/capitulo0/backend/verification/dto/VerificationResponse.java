package com.capitulo0.backend.verification.dto;

import com.capitulo0.backend.verification.entity.OrganizerVerificationRequest;
import com.capitulo0.backend.verification.entity.VerificationStatus;
import java.time.Instant;

public record VerificationResponse(
        Long id,
        String organizationName,
        VerificationStatus status,
        String reviewReason,
        Instant createdAt,
        Instant reviewedAt
) {
    public static VerificationResponse from(
            OrganizerVerificationRequest request
    ) {
        return new VerificationResponse(
                request.getId(),
                request.getOrganizationName(),
                request.getStatus(),
                request.getReviewReason(),
                request.getCreatedAt(),
                request.getReviewedAt()
        );
    }
}
