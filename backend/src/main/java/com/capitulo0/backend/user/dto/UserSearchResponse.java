package com.capitulo0.backend.user.dto;

public record UserSearchResponse(
    String displayName,
    String username,
    String avatarUrl
) {}
