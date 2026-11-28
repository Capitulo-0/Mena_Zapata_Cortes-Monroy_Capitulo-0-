package com.capitulo0.backend.social.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record CreateChapterCommentRequest(
    @NotBlank @Size(max = 220) String content,
    @Positive Long parentId,
    boolean anonymous
) {}
