package com.capitulo0.backend.user.entity;
import jakarta.persistence.*;
import java.time.Instant;
@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "firebase_uid", unique = true, length = 128)
    private String firebaseUid;
    @Column(nullable = false, unique = true, length = 320)
    private String email;
    @Column(name = "display_name", length = 120)
    private String displayName;
    @Column(length = 30)
    private String username;
    @Column(length = 500)
    private String biography;
    @Column(name = "avatar_url", length = 2048)
    private String avatarUrl;
    @Column(name = "annual_reading_goal", nullable = false)
    private Integer annualReadingGoal = 25;
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
    protected User() {}
    public static User create() {
        return new User();
    }
    @PrePersist
    void onCreate() {
        createdAt = updatedAt = Instant.now();
    }
    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }
    public Long getId() {
        return id;
    }
    public String getFirebaseUid() {
        return firebaseUid;
    }
    public void setFirebaseUid(String value) {
        this.firebaseUid = value;
    }
    public Instant getCreatedAt() {
        return createdAt;
    }
    public Instant getUpdatedAt() {
        return updatedAt;
    }
    public String getEmail() {
        return email;
    }
    public void setEmail(String value) {
        this.email = value;
    }
    public String getDisplayName() {
        return displayName;
    }
    public void setDisplayName(String value) {
        this.displayName = value;
    }
    public void setUsername(String username) {
        this.username = username;
    }
    public String getUsername() {
        return username;
    }
    public String getBiography() {
        return biography;
    }
    public void setBiography(String biography) {
        this.biography = biography;
    }
    public String getAvatarUrl() {
        return avatarUrl;
    }
    public void setAvatarUrl(String avatarUrl) {
        this.avatarUrl = avatarUrl;
    }
    public Integer getAnnualReadingGoal() {
        return annualReadingGoal;
    }
    public void setAnnualReadingGoal(Integer annualReadingGoal) {
        this.annualReadingGoal = annualReadingGoal;
    }
}
