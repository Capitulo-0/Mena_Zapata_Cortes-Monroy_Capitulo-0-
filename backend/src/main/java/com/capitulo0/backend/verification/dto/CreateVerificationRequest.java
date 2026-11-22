package com.capitulo0.backend.verification.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateVerificationRequest(
        @NotBlank
        @Size(max = 150)
        String representativeName,

        @NotBlank
        @Size(max = 200)
        String organizationName,

        @Size(max = 20)
        String organizationRut,

        @NotBlank
        @Size(max = 120)
        String city,

        @Size(max = 300)
        String publicAddress,

        @NotBlank
        @Email
        @Size(max = 320)
        String contactEmail,

        @NotBlank
        @Size(max = 40)
        String contactPhone,

        @Size(max = 2048)
        String socialUrl,

        @NotBlank
        @Size(max = 2000)
        String organizationDescription
) {
}
