package com.capitulo0.backend.follow.service;

import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.common.exception.ApiException;
import com.capitulo0.backend.follow.entity.UserFollow;
import com.capitulo0.backend.follow.entity.UserFollow.Status;
import com.capitulo0.backend.follow.repository.UserFollowRepository;
import com.capitulo0.backend.notification.entity.NotificationType;
import com.capitulo0.backend.notification.entity.UserNotification;
import com.capitulo0.backend.notification.repository.UserNotificationRepository;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.repository.UserRepository;
import java.time.Instant;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.function.Function;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Applies the follow/privacy rules using the authenticated Firebase identity. */
@Service
public class FollowService {

    private final CurrentUserService currentUser;
    private final UserRepository users;
    private final UserFollowRepository follows;
    private final UserNotificationRepository notifications;

    public FollowService(
            CurrentUserService currentUser,
            UserRepository users,
            UserFollowRepository follows,
            UserNotificationRepository notifications
    ) {
        this.currentUser = currentUser;
        this.users = users;
        this.follows = follows;
        this.notifications = notifications;
    }

    /** Public accounts accept instantly; private accounts receive a pending request. */
    @Transactional
    public UserFollow follow(String username) {
        User actor = currentUser.require();
        User target = findTarget(username);
        if (actor.getId().equals(target.getId())) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "No puedes seguirte a ti mismo");
        }
        if (follows.findByFollowerIdAndFollowingId(actor.getId(), target.getId()).isPresent()) {
            throw new ApiException(HttpStatus.CONFLICT, "Ya existe una solicitud o seguimiento");
        }

        boolean privateAccount = Boolean.TRUE.equals(target.getIsPrivate());
        UserFollow relationship = privateAccount
                ? UserFollow.pending(actor.getId(), target.getId())
                : UserFollow.accepted(actor.getId(), target.getId());
        relationship = follows.saveAndFlush(relationship);

        notifications.save(new UserNotification(
                target.getId(),
                actor.getId(),
                relationship.getId(),
                privateAccount ? NotificationType.FOLLOW_REQUEST : NotificationType.NEW_FOLLOWER
        ));
        return relationship;
    }

    /** Only the account receiving the request may approve it. */
    @Transactional
    public UserFollow accept(Long followId) {
        User owner = currentUser.require();
        UserFollow relationship = pendingForOwner(followId, owner.getId());
        relationship.accept();

        notifications.findFirstByFollowIdAndType(
                relationship.getId(), NotificationType.FOLLOW_REQUEST
        ).ifPresent(request -> request.markAsNewFollower(Instant.now()));

        notifications.save(new UserNotification(
                relationship.getFollowerId(),
                owner.getId(),
                relationship.getId(),
                NotificationType.FOLLOW_ACCEPTED
        ));
        return relationship;
    }

    /** Discard a pending request without notifying the requester. */
    @Transactional
    public void reject(Long followId) {
        User owner = currentUser.require();
        UserFollow relationship = pendingForOwner(followId, owner.getId());

        notifications.findFirstByFollowIdAndType(
                relationship.getId(), NotificationType.FOLLOW_REQUEST
        ).ifPresent(notifications::delete);
        notifications.flush();
        follows.delete(relationship);
    }

    /** Cancel a sent request or unfollow a reader; keep historical notifications. */
    @Transactional
    public void unfollow(String username) {
        User actor = currentUser.require();
        User target = findTarget(username);
        UserFollow relationship = follows.findByFollowerIdAndFollowingId(
                actor.getId(), target.getId()
        ).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "No existe ese seguimiento"));

        if (relationship.getStatus() == Status.PENDING) {
            notifications.findFirstByFollowIdAndType(
                    relationship.getId(), NotificationType.FOLLOW_REQUEST
            ).ifPresent(notifications::delete);
            notifications.flush();
        }
        // The V9 foreign key uses ON DELETE SET NULL; historical events remain.
        follows.delete(relationship);
    }

    /** Check a relationship without allowing the client to impersonate another follower. */
    @Transactional(readOnly = true)
    public Status status(String username) {
        User actor = currentUser.require();
        User target = findTarget(username);
        return follows.findByFollowerIdAndFollowingId(actor.getId(), target.getId())
                .map(UserFollow::getStatus)
                .orElse(null);
    }

    /** Only accepted relationships are visible in follower lists. */
    @Transactional(readOnly = true)
    public Page<FollowUser> followers(String username, Pageable pageable) {
        User viewer = currentUser.require();
        User profile = findTarget(username);
        requireListAccess(viewer, profile);

        Page<UserFollow> page = follows.findByFollowingIdAndStatusOrderByAcceptedAtDescIdDesc(
                profile.getId(), Status.ACCEPTED, pageable
        );
        return mapUsers(page, UserFollow::getFollowerId);
    }

    /** Only accepted relationships are visible in following lists. */
    @Transactional(readOnly = true)
    public Page<FollowUser> following(String username, Pageable pageable) {
        User viewer = currentUser.require();
        User profile = findTarget(username);
        requireListAccess(viewer, profile);

        Page<UserFollow> page = follows.findByFollowerIdAndStatusOrderByAcceptedAtDescIdDesc(
                profile.getId(), Status.ACCEPTED, pageable
        );
        return mapUsers(page, UserFollow::getFollowingId);
    }

    /** Counts include accepted relationships only, never pending requests. */
    @Transactional(readOnly = true)
    public FollowCounts counts(String username) {
        User viewer = currentUser.require();
        User profile = findTarget(username);
        requireListAccess(viewer, profile);
        return new FollowCounts(
                follows.countByFollowingIdAndStatus(profile.getId(), Status.ACCEPTED),
                follows.countByFollowerIdAndStatus(profile.getId(), Status.ACCEPTED)
        );
    }

    /** Private lists are visible only to the owner or an accepted follower. */
    private void requireListAccess(User viewer, User profile) {
        if (!Boolean.TRUE.equals(profile.getIsPrivate())
                || viewer.getId().equals(profile.getId())) {
            return;
        }
        boolean accepted = follows.findByFollowerIdAndFollowingId(
                viewer.getId(), profile.getId()
        ).map(relation -> relation.getStatus() == Status.ACCEPTED).orElse(false);
        if (!accepted) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Este perfil es privado");
        }
    }

    /** Resolve each account once per page, preserving follow ordering. */
    private Page<FollowUser> mapUsers(Page<UserFollow> page, Function<UserFollow, Long> idGetter) {
        var userIds = page.getContent().stream().map(idGetter).distinct().toList();
        Map<Long, User> byId = new HashMap<>();
        users.findAllById(userIds).forEach(user -> byId.put(user.getId(), user));
        return page.map(relation -> {
            User user = byId.get(idGetter.apply(relation));
            if (user == null) {
                throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "Usuario relacionado no encontrado");
            }
            return new FollowUser(user.getId(), user.getUsername(), user.getDisplayName(), user.getAvatarUrl());
        });
    }

    public record FollowUser(Long id, String username, String displayName, String avatarUrl) { }

    public record FollowCounts(long followersCount, long followingCount) { }

    private UserFollow pendingForOwner(Long followId, Long ownerId) {
        UserFollow relationship = follows.findByIdAndFollowingId(
                Objects.requireNonNull(followId, "followId"), ownerId
        ).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Solicitud no encontrada"));
        if (relationship.getStatus() != Status.PENDING) {
            throw new ApiException(HttpStatus.CONFLICT, "La solicitud ya no está pendiente");
        }
        return relationship;
    }

    private User findTarget(String username) {
        if (username == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Nombre de usuario requerido");
        }
        String normalized = username.trim().replaceFirst("^@", "")
                .toLowerCase(Locale.ROOT);
        if (normalized.isEmpty()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Nombre de usuario requerido");
        }
        return users.findByUsername(normalized).orElseThrow(
                () -> new ApiException(HttpStatus.NOT_FOUND, "Usuario no encontrado")
        );
    }
}
