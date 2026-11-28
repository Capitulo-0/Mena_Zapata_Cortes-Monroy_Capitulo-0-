package com.capitulo0.backend.social.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdateBookCommentRequest(
    @NotBlank @Size(max = 300) String content,
    boolean anonymous
) {}
