package com.capitulo0.backend.user.dto;
import jakarta.validation.constraints.*;
public record CreateUserRequest(@NotBlank @Email @Size(max = 320) String email,
                                @Size(max = 120) String displayName) {}
