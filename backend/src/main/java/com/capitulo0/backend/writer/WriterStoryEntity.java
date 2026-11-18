package com.capitulo0.backend.writer;
import jakarta.persistence.*;
import java.time.Instant;
@Entity @Table(name="writer_stories")
public class WriterStoryEntity {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) @Column(name="id") Long internalId;
 @Column(name="story_key",length=64,nullable=false,unique=true) String storyKey;
 @Column(name="owner_id",nullable=false,updatable=false) Long ownerId;
 @Column(nullable=false,columnDefinition="text") String payload;
 @Column(name="created_at",nullable=false) Instant createdAt;
 @Column(name="updated_at",nullable=false) Instant updatedAt;
 @Version @Column(nullable=false) long revision;
 protected WriterStoryEntity() {}
}
