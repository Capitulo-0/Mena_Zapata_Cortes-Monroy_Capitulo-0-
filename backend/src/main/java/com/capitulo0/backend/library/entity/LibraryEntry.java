package com.capitulo0.backend.library.entity;
import jakarta.persistence.*;
import java.time.Instant;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.catalog.book.entity.Book;
@Entity
@Table(name = "library_entries")
public class LibraryEntry {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "user_id", nullable = false)
    private User user;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "book_id", nullable = false)
    private Book book;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20)
    private ReadingStatus status;
    @Enumerated(EnumType.STRING) @Column(name = "reading_format", nullable = false, length = 20)
    private ReadingFormat readingFormat;
    @Column(name = "current_page", nullable = false)
    private int currentPage;
    @Column(name = "total_pages")
    private Integer totalPages;
    @Column(name = "publisher_override", length = 300)
    private String publisherOverride;
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
    protected LibraryEntry() {}
    public static LibraryEntry create() { return new LibraryEntry(); }
    @PrePersist void onCreate() { createdAt = updatedAt = Instant.now(); }
    @PreUpdate void onUpdate() { updatedAt = Instant.now(); }
    public Long getId() { return id; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public User getUser() { return user; }
    public void setUser(User value) { this.user = value; }
    public Book getBook() { return book; }
    public void setBook(Book value) { this.book = value; }
    public ReadingStatus getStatus() { return status; }
    public void setStatus(ReadingStatus value) { this.status = value; }
    public ReadingFormat getReadingFormat() { return readingFormat; }
    public void setReadingFormat(ReadingFormat value) { this.readingFormat = value; }
    public int getCurrentPage() { return currentPage; }
    public void setCurrentPage(int value) { this.currentPage = value; }
    public Integer getTotalPages() { return totalPages; }
    public void setTotalPages(Integer value) { this.totalPages = value; }
    public String getPublisherOverride() { return publisherOverride; }
    public void setPublisherOverride(String value) { this.publisherOverride = value; }
}
