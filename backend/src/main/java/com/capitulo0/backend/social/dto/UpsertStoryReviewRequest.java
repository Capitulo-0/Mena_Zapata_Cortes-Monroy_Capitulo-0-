package com.capitulo0.backend.social.dto;

import com.capitulo0.backend.social.entity.ReviewVisibility;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record UpsertStoryReviewRequest(
    @NotNull @Min(1) @Max(5) Integer rating,
    @Size(max = 500) String reviewText,
    @NotNull ReviewVisibility visibility
) {}
