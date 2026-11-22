package com.capitulo0.backend.catalog.book.entity;
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "books")
public class Book {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, length = 500)
    private String title;
    @Column(length = 300)
    private String author;
    @Column(columnDefinition = "text")
    private String synopsis;
    @Column(length = 32)
    private String isbn;
    @Column(length = 300)
    private String publisher;
    @Column(name = "total_pages")
    private Integer totalPages;
    @Column(name = "publication_year")
    private Integer publicationYear;
    @Column(name = "cover_url", length = 2048)
    private String coverUrl;
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
    @Column(name = "google_volume_id", length = 128, unique = true)
    private String googleVolumeId;
    @Column(name = "external_metadata", columnDefinition = "text")
    private String externalMetadata;
    public String getGoogleVolumeId() { return googleVolumeId; }
    public void setGoogleVolumeId(String value) { googleVolumeId=value; }
    public String getExternalMetadata() { return externalMetadata; }
    public void setExternalMetadata(String value) { externalMetadata=value; }
    protected Book() {}
    public static Book create() { return new Book(); }
    @PrePersist void onCreate() { createdAt = updatedAt = Instant.now(); }
    @PreUpdate void onUpdate() { updatedAt = Instant.now(); }
    public Long getId() { return id; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public String getTitle() { return title; }
    public void setTitle(String value) { this.title = value; }
    public String getAuthor() { return author; }
    public void setAuthor(String value) { this.author = value; }
    public String getSynopsis() { return synopsis; }
    public void setSynopsis(String value) { this.synopsis = value; }
    public String getIsbn() { return isbn; }
    public void setIsbn(String value) { this.isbn = value; }
    public String getPublisher() { return publisher; }
    public void setPublisher(String value) { this.publisher = value; }
    public Integer getTotalPages() { return totalPages; }
    public void setTotalPages(Integer value) { this.totalPages = value; }
    public Integer getPublicationYear() { return publicationYear; }
    public void setPublicationYear(Integer value) { this.publicationYear = value; }
    public String getCoverUrl() { return coverUrl; }
    public void setCoverUrl(String value) { this.coverUrl = value; }
}
