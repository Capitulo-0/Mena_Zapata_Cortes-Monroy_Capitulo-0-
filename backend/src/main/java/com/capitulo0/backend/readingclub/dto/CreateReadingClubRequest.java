package com.capitulo0.backend.readingclub.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.time.LocalTime;

public record CreateReadingClubRequest(

        @NotBlank
        @Size(max = 150)
        String name,

        @NotBlank
        @Size(max = 2000)
        String description,

        @NotNull
        LocalDate meetingDate,

        @NotNull
        LocalTime meetingTime,

        @NotBlank
        String modality,

        @Size(max = 300)
        String meetingPlace,

        @Size(max = 200)
        String instagram,

        @Size(max = 200)
        String facebook,

        @Size(max = 200)
        String xHandle

) {
}
