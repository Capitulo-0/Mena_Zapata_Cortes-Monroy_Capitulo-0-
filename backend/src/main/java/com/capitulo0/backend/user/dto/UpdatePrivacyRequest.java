
package com.capitulo0.backend.user.dto;
import jakarta.validation.constraints.NotNull;

public record UpdatePrivacyRequest(
    @NotNull(message = "Debes indicar si la cuenta es privada")
    Boolean isPrivate
) {}
