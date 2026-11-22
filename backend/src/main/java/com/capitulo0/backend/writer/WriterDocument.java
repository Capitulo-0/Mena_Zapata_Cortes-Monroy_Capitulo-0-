package com.capitulo0.backend.writer;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.time.Instant;
import java.util.List;
public record WriterDocument(
 @NotBlank @Pattern(regexp="[A-Za-z0-9_-]{1,64}") String id,
 @NotBlank @Size(max=300) String title,
 @Size(max=10000) String synopsis,
 @Size(max=100) String genre,
 @Size(max=2048) String coverPath,
 @NotNull @Pattern(regexp="draft|published") String status,
 @NotNull @Size(max=200) List<@NotNull @Valid Chapter> chapters,
 Instant createdAt, Instant updatedAt, Long revision,
 Integer followers, Double rating
) {
 public record Chapter(
  @NotBlank @Pattern(regexp="[A-Za-z0-9_-]{1,64}") String id,
  @NotNull @Size(max=300) String title,
  @NotNull @Size(max=200000) String content,
  @Min(1) int order, boolean isPublished, Instant createdAt, Instant updatedAt
 ) {}
 public WriterDocument state(String nextStatus,List<Chapter> nextChapters,Instant created,Instant updated,long version) {
  return new WriterDocument(id,title.trim(),synopsis==null?"":synopsis,genre==null?"":genre,
   coverPath,nextStatus,List.copyOf(nextChapters),created,updated,version,0,0.0);
 }
}
