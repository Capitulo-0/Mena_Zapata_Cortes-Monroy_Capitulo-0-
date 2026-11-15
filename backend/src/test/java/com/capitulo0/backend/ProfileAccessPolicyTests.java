package com.capitulo0.backend;

import com.capitulo0.backend.follow.entity.UserFollow;
import com.capitulo0.backend.follow.repository.UserFollowRepository;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.repository.UserRepository;
import com.capitulo0.backend.user.service.ProfileAccessPolicy;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class ProfileAccessPolicyTests {

    private final UserRepository users = mock(UserRepository.class);
    private final UserFollowRepository follows = mock(UserFollowRepository.class);
    private final ProfileAccessPolicy policy = new ProfileAccessPolicy(users, follows);

    private User profile(boolean isPrivate) {
        User owner = User.create();
        owner.setFirebaseUid("owner-uid");
        owner.setIsPrivate(isPrivate);
        return owner;
    }

    @Test
    void publicProfileAllowsOtherUsers() {
        assertThat(policy.canViewContent(profile(false), "visitor-uid")).isTrue();
    }

    @Test
    void publicProfileAllowsAnonymousVisitors() {
        assertThat(policy.canViewContent(profile(false), null)).isTrue();
    }

    @Test
    void privateProfileAllowsItsOwner() {
        assertThat(policy.canViewContent(profile(true), "owner-uid")).isTrue();
    }

    @Test
    void privateProfileRejectsUnknownUsers() {
        assertThat(policy.canViewContent(profile(true), "visitor-uid")).isFalse();
    }

    @Test
    void privateProfileRejectsAnonymousVisitors() {
        assertThat(policy.canViewContent(profile(true), null)).isFalse();
    }

    @Test
    void privateProfileAllowsAcceptedFollowers() {
        User owner = profile(true);
        User visitor = mock(User.class);
        UserFollow relation = mock(UserFollow.class);

        when(users.findByFirebaseUid("visitor-uid")).thenReturn(Optional.of(visitor));
        when(follows.findByFollowerIdAndFollowingId(visitor.getId(), owner.getId()))
            .thenReturn(Optional.of(relation));
        when(relation.getStatus()).thenReturn(UserFollow.Status.ACCEPTED);

        assertThat(policy.canViewContent(owner, "visitor-uid")).isTrue();
    }

    @Test
    void privateProfileRejectsPendingFollowers() {
        User owner = profile(true);
        User visitor = mock(User.class);
        UserFollow relation = mock(UserFollow.class);

        when(users.findByFirebaseUid("visitor-uid")).thenReturn(Optional.of(visitor));
        when(follows.findByFollowerIdAndFollowingId(visitor.getId(), owner.getId()))
            .thenReturn(Optional.of(relation));
        when(relation.getStatus()).thenReturn(UserFollow.Status.PENDING);

        assertThat(policy.canViewContent(owner, "visitor-uid")).isFalse();
    }

    @Test
    void privateProfileRejectsUsersWithoutFollowRelationship() {
        User owner = profile(true);
        User visitor = mock(User.class);

        when(users.findByFirebaseUid("visitor-uid")).thenReturn(Optional.of(visitor));
        when(follows.findByFollowerIdAndFollowingId(visitor.getId(), owner.getId()))
            .thenReturn(Optional.empty());

        assertThat(policy.canViewContent(owner, "visitor-uid")).isFalse();
    }
}
