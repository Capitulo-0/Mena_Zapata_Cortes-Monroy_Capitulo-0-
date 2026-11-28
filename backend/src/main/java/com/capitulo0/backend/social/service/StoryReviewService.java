package com.capitulo0.backend.social.service;

import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.writer.WriterService;
import com.capitulo0.backend.common.exception.ApiException;
import com.capitulo0.backend.social.dto.*;
import com.capitulo0.backend.social.entity.StoryReview;
import com.capitulo0.backend.social.entity.ReviewVisibility;
import com.capitulo0.backend.social.repository.StoryReviewRepository;
import com.capitulo0.backend.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Objects;
import java.util.Optional;

@Service
public class StoryReviewService {
    private final StoryReviewRepository reviews;
    private final WriterService writer;
    private final UserRepository users;
    private final CurrentUserService current;

    public StoryReviewService(StoryReviewRepository reviews, WriterService writer,
                             UserRepository users, CurrentUserService current) {
        this.reviews = reviews;
        this.writer = writer;
        this.users = users;
        this.current = current;
    }

    @Transactional(readOnly = true)
    public List<StoryReviewResponse> list(String storyKey) {
        Long viewer = current.require().getId();
        requireStory(storyKey);
        return reviews.findByStoryKeyAndVisibilityInAndReviewTextIsNotNullOrderByUpdatedAtDescIdDesc(
                storyKey, List.of(ReviewVisibility.PUBLIC, ReviewVisibility.ANONYMOUS))
                .stream().filter(r -> r.getReviewText() != null && !r.getReviewText().isBlank())
                .map(r -> publicResponse(r, viewer)).toList();
    }

    @Transactional(readOnly = true)
    public StoryRatingSummaryResponse summary(String storyKey) {
        current.require();
        requireStory(storyKey);
        Double average = reviews.averageRating(storyKey);
        return new StoryRatingSummaryResponse(storyKey, average == null ? 0.0 : average,
                reviews.countByStoryKey(storyKey));
    }

    @Transactional(readOnly = true)
    public Optional<OwnStoryReviewResponse> own(String storyKey) {
        Long owner = current.require().getId();
        requireStory(storyKey);
        return reviews.findByStoryKeyAndUserId(storyKey, owner).map(this::ownResponse);
    }

    @Transactional
    public OwnStoryReviewResponse upsert(String storyKey, UpsertStoryReviewRequest request) {
        Long owner = current.require().getId();
        requireStory(storyKey);
        if (request == null || request.rating() == null || request.rating() < 1
                || request.rating() > 5 || request.visibility() == null) {
            throw ApiException.invalid("Calificacion o visibilidad no valida");
        }
        String text = request.reviewText();
        if (text != null) {
            if (text.length() > 500 || text.indexOf(0) >= 0) {
                throw ApiException.invalid("Resena no valida");
            }
            text = text.isBlank() ? null : text.strip();
        }
        reviews.upsert(storyKey, owner, request.rating(), text, request.visibility().name());
        return reviews.findByStoryKeyAndUserId(storyKey, owner).map(this::ownResponse)
                .orElseThrow(() -> ApiException.notFound("Resena"));
    }

    @Transactional
    public void delete(String storyKey) {
        Long owner = current.require().getId();
        requireStory(storyKey);
        reviews.removeOwnReview(storyKey, owner);
    }

    private void requireStory(String storyKey) {
        if (storyKey == null || storyKey.isBlank()) {
            throw ApiException.notFound("Historia");
        }
        writer.published(storyKey);
    }

    private OwnStoryReviewResponse ownResponse(StoryReview r) {
        return new OwnStoryReviewResponse(r.getId(), r.getStoryKey(), r.getRating(),
                r.getReviewText(), r.getVisibility(), r.getCreatedAt(), r.getUpdatedAt());
    }

    private StoryReviewResponse publicResponse(StoryReview r, Long viewer) {
        String username = null;
        String avatar = null;
        if (r.getVisibility() == ReviewVisibility.PUBLIC) {
            var author = users.findById(r.getUserId()).orElse(null);
            if (author != null) {
                username = author.getUsername();
                avatar = author.getAvatarUrl();
            }
        }
        return new StoryReviewResponse(r.getId(), r.getStoryKey(), r.getRating(),
                r.getReviewText(), r.getVisibility(), username, avatar,
                Objects.equals(r.getUserId(), viewer), r.getCreatedAt(), r.getUpdatedAt());
    }
}
