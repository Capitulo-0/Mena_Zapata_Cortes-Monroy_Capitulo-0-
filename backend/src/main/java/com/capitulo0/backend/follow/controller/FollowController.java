package com.capitulo0.backend.follow.controller;

import com.capitulo0.backend.follow.entity.UserFollow;
import com.capitulo0.backend.follow.service.FollowService;
import java.time.Instant;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Follow actions are always performed as the authenticated Firebase user. */
@RestController
@RequestMapping("/api/follows")
public class FollowController {

    private final FollowService follows;

    public FollowController(FollowService follows) {
        this.follows = follows;
    }

    /** Follow a public reader or send a request to a private reader. */
    @PostMapping("/{username}")
    @ResponseStatus(HttpStatus.CREATED)
    public FollowResponse follow(@PathVariable String username) {
        return FollowResponse.from(follows.follow(username));
    }

    /** Cancel your pending request or stop following another reader. */
    @DeleteMapping("/{username}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void unfollow(@PathVariable String username) {
        follows.unfollow(username);
    }

    /** Returns null status when there is no relationship. */
    @GetMapping("/{username}/status")
    public FollowStatusResponse status(@PathVariable String username) {
        UserFollow.Status value = follows.status(username);
        return new FollowStatusResponse(value == null ? null : value.name());
    }

    /** Accepted followers, with private-profile access enforced by the service. */
    @GetMapping("/{username}/followers")
    public Page<FollowService.FollowUser> followers(
            @PathVariable String username,
            @PageableDefault(size = 20) Pageable pageable
    ) {
        return follows.followers(username, pageable);
    }

    /** Accepted accounts followed by this reader. */
    @GetMapping("/{username}/following")
    public Page<FollowService.FollowUser> following(
            @PathVariable String username,
            @PageableDefault(size = 20) Pageable pageable
    ) {
        return follows.following(username, pageable);
    }

    /** Real counts, excluding pending follow requests. */
    @GetMapping("/{username}/counts")
    public FollowService.FollowCounts counts(@PathVariable String username) {
        return follows.counts(username);
    }

    /** Only the recipient of a pending request can authorize it. */
    @PatchMapping("/requests/{followId}/accept")
    public FollowResponse accept(@PathVariable Long followId) {
        return FollowResponse.from(follows.accept(followId));
    }

    /** Only the recipient of a pending request can discard it. */
    @DeleteMapping("/requests/{followId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void reject(@PathVariable Long followId) {
        follows.reject(followId);
    }

    public record FollowStatusResponse(String status) { }

    public record FollowResponse(
            Long id,
            String status,
            Instant createdAt,
            Instant acceptedAt
    ) {
        public static FollowResponse from(UserFollow follow) {
            return new FollowResponse(
                    follow.getId(),
                    follow.getStatus().name(),
                    follow.getCreatedAt(),
                    follow.getAcceptedAt()
            );
        }
    }
}
