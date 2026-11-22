package com.capitulo0.backend.user.dto;

import jakarta.validation.constraints.Size;

public record ReadingMoodRequest(
    @Size(max = 32) String emoji,
    @Size(max = 120) String label,
    @Size(max = 500) String detail
) {}
