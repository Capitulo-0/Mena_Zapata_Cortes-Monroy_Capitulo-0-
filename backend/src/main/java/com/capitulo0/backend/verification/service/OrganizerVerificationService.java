package com.capitulo0.backend.verification.service;

import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.common.exception.ApiException;
import com.capitulo0.backend.verification.dto.CreateVerificationRequest;
import com.capitulo0.backend.verification.dto.VerificationResponse;
import com.capitulo0.backend.verification.entity.OrganizerVerificationRequest;
import com.capitulo0.backend.verification.entity.VerificationStatus;
import com.capitulo0.backend.verification.repository.OrganizerVerificationRepository;
import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OrganizerVerificationService {

    private final CurrentUserService current;
    private final OrganizerVerificationRepository requests;

    public OrganizerVerificationService(
            CurrentUserService current,
            OrganizerVerificationRepository requests
    ) {
        this.current = current;
        this.requests = requests;
    }

    @Transactional(readOnly = true)
    public Optional<VerificationResponse> myLatestRequest() {
        Long userId = current.require().getId();

        return requests
                .findFirstByUserIdOrderByCreatedAtDescIdDesc(userId)
                .map(VerificationResponse::from);
    }

    @Transactional
    public VerificationResponse submit(CreateVerificationRequest form) {
        Long userId = current.require().getId();

        if (requests.existsByUserIdAndStatus(
                userId,
                VerificationStatus.APPROVED
        )) {
            throw ApiException.conflict(
                    "Tu cuenta ya está verificada como organizador"
            );
        }

        if (requests.existsByUserIdAndStatus(
                userId,
                VerificationStatus.PENDING
        )) {
            throw ApiException.conflict(
                    "Ya tienes una solicitud pendiente de revisión"
            );
        }

        OrganizerVerificationRequest request =
                new OrganizerVerificationRequest(
                        userId,
                        form.representativeName().strip(),
                        form.organizationName().strip(),
                        optional(form.organizationRut()),
                        form.city().strip(),
                        optional(form.publicAddress()),
                        form.contactEmail().strip(),
                        form.contactPhone().strip(),
                        optional(form.socialUrl()),
                        form.organizationDescription().strip()
                );

        return VerificationResponse.from(
                requests.saveAndFlush(request)
        );
    }

    private static String optional(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }

        return value.strip();
    }
}
