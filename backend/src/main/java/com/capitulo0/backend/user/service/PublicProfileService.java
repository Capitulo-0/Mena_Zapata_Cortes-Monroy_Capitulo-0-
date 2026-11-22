
package com.capitulo0.backend.user.service;

import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.common.exception.ApiException;
import com.capitulo0.backend.follow.entity.UserFollow.Status;
import com.capitulo0.backend.follow.repository.UserFollowRepository;
import com.capitulo0.backend.library.repository.LibraryEntryRepository;
import com.capitulo0.backend.user.dto.PublicProfileResponse;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.repository.UserRepository;
import com.capitulo0.backend.verification.entity.VerificationStatus;
import com.capitulo0.backend.verification.repository.OrganizerVerificationRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PublicProfileService {

    private final CurrentUserService current;
    private final UserRepository users;
    private final LibraryEntryRepository library;
    private final UserFollowRepository follows;
    private final ProfileAccessPolicy accessPolicy;
    private final OrganizerVerificationRepository verifications;

    public PublicProfileService(
            CurrentUserService current,
            UserRepository users,
            LibraryEntryRepository library,
            UserFollowRepository follows,
            ProfileAccessPolicy accessPolicy,
            OrganizerVerificationRepository verifications
    ) {
        this.current = current;
        this.users = users;
        this.library = library;
        this.follows = follows;
        this.accessPolicy = accessPolicy;
        this.verifications = verifications;
    }

    @Transactional(readOnly = true)
    public PublicProfileResponse findByUsername(String username) {
        String viewerUid = current.requireIdentity().uid();

        User owner = users.findByUsername(username)
                .orElseThrow(() -> ApiException.notFound("Usuario"));

        boolean canViewContent = accessPolicy.canViewContent(owner, viewerUid);

        Long followersCount = null;
        Long followingCount = null;
        Long booksCount = null;

        if (canViewContent) {
            followersCount = follows.countByFollowingIdAndStatus(
                    owner.getId(),
                    Status.ACCEPTED
            );

            followingCount = follows.countByFollowerIdAndStatus(
                    owner.getId(),
                    Status.ACCEPTED
            );

            booksCount = library.countByUserId(owner.getId());
        }

        boolean verifiedOrganizer = verifications.existsByUserIdAndStatus(
                owner.getId(),
                VerificationStatus.APPROVED
        );

        return new PublicProfileResponse(
                owner.getId(),
                owner.getDisplayName(),
                owner.getUsername(),
                owner.getBiography(),
                owner.getAvatarUrl(),
                owner.getCreatedAt(),
                owner.getIsPrivate(),
                canViewContent,
                followersCount,
                followingCount,
                booksCount,
                verifiedOrganizer,
                canViewContent ? com.capitulo0.backend.user.dto.ReadingMoodResponse.from(owner) : null
        );
    }
}
