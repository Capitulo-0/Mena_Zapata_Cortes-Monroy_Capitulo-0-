package com.capitulo0.backend;

import com.capitulo0.backend.auth.model.AuthenticatedFirebaseUser;
import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.follow.repository.UserFollowRepository;
import com.capitulo0.backend.library.repository.LibraryEntryRepository;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.repository.UserRepository;
import com.capitulo0.backend.user.service.ProfileAccessPolicy;
import com.capitulo0.backend.user.service.PublicProfileService;
import com.capitulo0.backend.verification.repository.OrganizerVerificationRepository;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class PublicReadingMoodPrivacyTests {
    private final CurrentUserService current = mock(CurrentUserService.class);
    private final UserRepository users = mock(UserRepository.class);
    private final LibraryEntryRepository library = mock(LibraryEntryRepository.class);
    private final UserFollowRepository follows = mock(UserFollowRepository.class);
    private final ProfileAccessPolicy access = mock(ProfileAccessPolicy.class);
    private final OrganizerVerificationRepository verifications = mock(OrganizerVerificationRepository.class);
    private final PublicProfileService profiles = new PublicProfileService(
        current, users, library, follows, access, verifications);

    private User setup() {
        var maria = User.create();
        maria.setUsername("maria");
        maria.setFirebaseUid("maria-id");
        maria.setReadingMoodEmoji("📖");
        maria.setReadingMoodTitle("Leyendo");
        maria.setReadingMoodDetail("Con entusiasmo");
        when(current.requireIdentity()).thenReturn(
            new AuthenticatedFirebaseUser("edu-id", "edu@test.local", "Edu", true));
        when(users.findByUsername("maria")).thenReturn(Optional.of(maria));
        return maria;
    }

    @Test
    void neverExposesMoodWhenViewerLacksPermission() {
        var maria = setup();
        when(access.canViewContent(maria, "edu-id")).thenReturn(false);
        var response = profiles.findByUsername("maria");
        assertThat(response.readingMood()).isNull();
        assertThat(response.canViewContent()).isFalse();
    }

    @Test
    void authorizedViewerReceivesCurrentMood() {
        var maria = setup();
        when(access.canViewContent(maria, "edu-id")).thenReturn(true);
        var response = profiles.findByUsername("maria");
        assertThat(response.readingMood().emoji()).isEqualTo("📖");
        assertThat(response.readingMood().label()).isEqualTo("Leyendo");
        assertThat(response.readingMood().detail()).isEqualTo("Con entusiasmo");
    }
}
