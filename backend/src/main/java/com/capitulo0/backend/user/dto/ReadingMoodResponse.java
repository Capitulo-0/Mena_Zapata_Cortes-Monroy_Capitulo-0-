package com.capitulo0.backend.user.dto;

import com.capitulo0.backend.user.entity.User;

public record ReadingMoodResponse(String emoji, String label, String detail) {
    public static ReadingMoodResponse from(User user) {
        if (user.getReadingMoodTitle() == null) return null;
        return new ReadingMoodResponse(user.getReadingMoodEmoji(),
            user.getReadingMoodTitle(), user.getReadingMoodDetail());
    }
}
