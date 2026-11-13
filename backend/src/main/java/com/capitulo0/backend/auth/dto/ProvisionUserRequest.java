package com.capitulo0.backend.auth.dto;

import jakarta.validation.constraints.Pattern;

public record ProvisionUserRequest(
    @Pattern(
        regexp = "^[a-z0-9_]{3,30}$",
        message = "El nombre de usuario debe tener entre 3 y 30 caracteres y solo puede contener letras minúsculas, números y guiones bajos"
    )
    String username
) {}