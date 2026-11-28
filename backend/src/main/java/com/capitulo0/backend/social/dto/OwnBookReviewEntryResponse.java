package com.capitulo0.backend.social.dto;

public record OwnBookReviewEntryResponse(
    OwnBookReviewResponse review,
    String title,
    String author,
    String coverUrl,
    String googleVolumeId
) {}
