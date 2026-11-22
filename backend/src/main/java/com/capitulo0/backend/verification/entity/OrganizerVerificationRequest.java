package com.capitulo0.backend.verification.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.Objects;

@Entity
@Table(name = "organizer_verification_requests")
public class OrganizerVerificationRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "representative_name", nullable = false, length = 150)
    private String representativeName;

    @Column(name = "organization_name", nullable = false, length = 200)
    private String organizationName;

    @Column(name = "organization_rut", length = 20)
    private String organizationRut;

    @Column(name = "city", nullable = false, length = 120)
    private String city;

    @Column(name = "public_address", length = 300)
    private String publicAddress;

    @Column(name = "contact_email", nullable = false, length = 320)
    private String contactEmail;

    @Column(name = "contact_phone", nullable = false, length = 40)
    private String contactPhone;

    @Column(name = "social_url", length = 2048)
    private String socialUrl;

    @Column(name = "organization_description", nullable = false, length = 2000)
    private String organizationDescription;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private VerificationStatus status = VerificationStatus.PENDING;

    @Column(name = "reviewed_by")
    private Long reviewedBy;

    @Column(name = "review_reason", length = 1000)
    private String reviewReason;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "reviewed_at")
    private Instant reviewedAt;

    protected OrganizerVerificationRequest() {
    }

    public OrganizerVerificationRequest(
            Long userId,
            String representativeName,
            String organizationName,
            String organizationRut,
            String city,
            String publicAddress,
            String contactEmail,
            String contactPhone,
            String socialUrl,
            String organizationDescription
    ) {
        this.userId = Objects.requireNonNull(userId);
        this.representativeName = Objects.requireNonNull(representativeName);
        this.organizationName = Objects.requireNonNull(organizationName);
        this.organizationRut = organizationRut;
        this.city = Objects.requireNonNull(city);
        this.publicAddress = publicAddress;
        this.contactEmail = Objects.requireNonNull(contactEmail);
        this.contactPhone = Objects.requireNonNull(contactPhone);
        this.socialUrl = socialUrl;
        this.organizationDescription =
                Objects.requireNonNull(organizationDescription);
    }

    @PrePersist
    void beforeInsert() {
        if (createdAt == null) {
            createdAt = Instant.now();
        }
    }

    public void approve(Long adminId) {
        requirePending();
        reviewedBy = Objects.requireNonNull(adminId);
        reviewedAt = Instant.now();
        reviewReason = null;
        status = VerificationStatus.APPROVED;
    }

    public void reject(Long adminId, String reason) {
        requirePending();

        if (reason == null || reason.isBlank()) {
            throw new IllegalArgumentException(
                    "El rechazo requiere un motivo"
            );
        }

        reviewedBy = Objects.requireNonNull(adminId);
        reviewedAt = Instant.now();
        reviewReason = reason.strip();
        status = VerificationStatus.REJECTED;
    }

    private void requirePending() {
        if (status != VerificationStatus.PENDING) {
            throw new IllegalStateException(
                    "La solicitud ya fue revisada"
            );
        }
    }

    public Long getId() { return id; }
    public Long getUserId() { return userId; }
    public String getRepresentativeName() { return representativeName; }
    public String getOrganizationName() { return organizationName; }
    public String getOrganizationRut() { return organizationRut; }
    public String getCity() { return city; }
    public String getPublicAddress() { return publicAddress; }
    public String getContactEmail() { return contactEmail; }
    public String getContactPhone() { return contactPhone; }
    public String getSocialUrl() { return socialUrl; }
    public String getOrganizationDescription() { return organizationDescription; }
    public VerificationStatus getStatus() { return status; }
    public Long getReviewedBy() { return reviewedBy; }
    public String getReviewReason() { return reviewReason; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getReviewedAt() { return reviewedAt; }
}
