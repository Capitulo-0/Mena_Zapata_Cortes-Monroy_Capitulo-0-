package com.capitulo0.backend.user.service;

import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.common.exception.ApiException;
import com.capitulo0.backend.user.dto.ReadingMoodRequest;
import com.capitulo0.backend.user.dto.ReadingMoodResponse;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ReadingMoodService {
    private final CurrentUserService current;
    private final UserRepository users;

    public ReadingMoodService(CurrentUserService current, UserRepository users) {
        this.current = current;
        this.users = users;
    }

    @Transactional(readOnly = true)
    public ReadingMoodResponse myMood() {
        return ReadingMoodResponse.from(current.require());
    }

    @Transactional
    public ReadingMoodResponse save(ReadingMoodRequest request) {
        User user = users.findByFirebaseUid(current.requireIdentity().uid())
            .orElseThrow(() -> ApiException.notFound("Usuario"));
        if (request.label() == null && request.emoji() == null && request.detail() == null) {
            user.setReadingMoodEmoji(null);
            user.setReadingMoodTitle(null);
            user.setReadingMoodDetail(null);
        } else {
            String label = request.label() == null ? "" : request.label().strip();
            String emoji = request.emoji() == null ? "" : request.emoji().strip();
            String detail = request.detail() == null ? "" : request.detail().strip();
            if (label.isEmpty() || emoji.isEmpty()) {
                throw ApiException.invalid("El estado lector requiere emoji y nombre.");
            }
            user.setReadingMoodEmoji(emoji);
            user.setReadingMoodTitle(label);
            user.setReadingMoodDetail(detail);
        }
        return ReadingMoodResponse.from(users.saveAndFlush(user));
    }
}
