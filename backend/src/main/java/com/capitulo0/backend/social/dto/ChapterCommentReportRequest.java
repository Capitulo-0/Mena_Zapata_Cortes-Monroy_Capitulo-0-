package com.capitulo0.backend.social.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ChapterCommentReportRequest(
    @NotBlank @Size(max = 500) String reason
) {}
