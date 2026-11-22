package com.capitulo0.backend.readingclub.dto;

import java.time.LocalDate;
import java.time.LocalTime;

public record ReadingClubResponse(
        Long id,
        String name,
        String description,
        Long organizerUserId,
        String organizerUsername,
        LocalDate meetingDate,
        LocalTime meetingTime,
        String modality,
        String meetingPlace,
        String instagram,
        String facebook,
        String xHandle,
        long membersCount,
        boolean joined,
        String status
) {
}
