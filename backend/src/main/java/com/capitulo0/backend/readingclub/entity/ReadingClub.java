package com.capitulo0.backend.readingclub.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Objects;

@Entity
@Table(name = "reading_clubs")
public class ReadingClub {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "organizer_user_id", nullable = false)
    private Long organizerUserId;

    @Column(nullable = false, length = 150)
    private String name;

    @Column(nullable = false, length = 2000)
    private String description;

    @Column(name = "meeting_date", nullable = false)
    private LocalDate meetingDate;

    @Column(name = "meeting_time", nullable = false)
    private LocalTime meetingTime;

    @Column(nullable = false, length = 20)
    private String modality;

    @Column(name = "meeting_place", length = 300)
    private String meetingPlace;

    @Column(length = 200)
    private String instagram;

    @Column(length = 200)
    private String facebook;

    @Column(name = "x_handle", length = 200)
    private String xHandle;

    @Column(nullable = false, length = 20)
    private String status = "ACTIVE";

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected ReadingClub() {
    }

    public ReadingClub(
            Long organizerUserId,
            String name,
            String description,
            LocalDate meetingDate,
            LocalTime meetingTime,
            String modality,
            String meetingPlace,
            String instagram,
            String facebook,
            String xHandle
    ) {
        this.organizerUserId = Objects.requireNonNull(organizerUserId);
        this.name = Objects.requireNonNull(name);
        this.description = Objects.requireNonNull(description);
        this.meetingDate = Objects.requireNonNull(meetingDate);
        this.meetingTime = Objects.requireNonNull(meetingTime);
        this.modality = Objects.requireNonNull(modality);
        this.meetingPlace = meetingPlace;
        this.instagram = instagram;
        this.facebook = facebook;
        this.xHandle = xHandle;
    }

    @PrePersist
    void beforeInsert() {
        Instant now = Instant.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void beforeUpdate() {
        updatedAt = Instant.now();
    }

    public Long getId() {
        return id;
    }

    public Long getOrganizerUserId() {
        return organizerUserId;
    }

    public String getName() {
        return name;
    }

    public String getDescription() {
        return description;
    }

    public LocalDate getMeetingDate() {
        return meetingDate;
    }

    public LocalTime getMeetingTime() {
        return meetingTime;
    }

    public String getModality() {
        return modality;
    }

    public String getMeetingPlace() {
        return meetingPlace;
    }

    public String getInstagram() {
        return instagram;
    }

    public String getFacebook() {
        return facebook;
    }

    public String getXHandle() {
        return xHandle;
    }

    public String getStatus() {
        return status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
