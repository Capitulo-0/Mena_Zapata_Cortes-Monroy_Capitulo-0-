package com.capitulo0.backend.user.dto;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record UpdateProfileRequest(
    @Size(max = 120, message = "El nombre no puede superar los 120 caracteres")
    String displayName,
    @Pattern(
        regexp = "^[a-z0-9_]{3,30}$",
        message = "El nombre de usuario debe tener entre 3 y 30 caracteres y solo puede contener letras minúsculas, números y guiones bajos"
    )
    String username,
    @Size(max = 500, message = "La biografía no puede superar los 500 caracteres")
    String biography,
    @Min(value = 1, message = "La meta anual debe ser mayor que cero")
    Integer annualReadingGoal
) {}