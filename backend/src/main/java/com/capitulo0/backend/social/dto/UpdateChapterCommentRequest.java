package com.capitulo0.backend.social.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdateChapterCommentRequest(
    @NotBlank @Size(max = 220) String content,
    boolean anonymous
) {}
