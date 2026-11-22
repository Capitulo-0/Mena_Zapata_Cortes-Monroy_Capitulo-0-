package com.capitulo0.backend;

import com.capitulo0.backend.auth.model.AuthenticatedFirebaseUser;
import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.common.exception.ApiException;
import com.capitulo0.backend.library.repository.LibraryEntryRepository;
import com.capitulo0.backend.readingclub.repository.ClubMembershipRepository;
import com.capitulo0.backend.readingclub.service.ReadingClubService;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.repository.UserRepository;
import com.capitulo0.backend.user.service.ProfileAccessPolicy;
import com.capitulo0.backend.user.service.PublicProfileActivityService;
import com.capitulo0.backend.user.service.UserBookFavoritesService;
import com.capitulo0.backend.writer.WriterService;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

class PublicProfileActivityAccessTests {
    private final CurrentUserService current = mock(CurrentUserService.class);
    private final UserRepository users = mock(UserRepository.class);
    private final ProfileAccessPolicy policy = mock(ProfileAccessPolicy.class);
    private final LibraryEntryRepository library = mock(LibraryEntryRepository.class);
    private final UserBookFavoritesService favorites = mock(UserBookFavoritesService.class);
    private final ClubMembershipRepository memberships = mock(ClubMembershipRepository.class);
    private final ReadingClubService clubs = mock(ReadingClubService.class);
    private final WriterService writer = mock(WriterService.class);
    private final PublicProfileActivityService service = new PublicProfileActivityService(
        current, users, policy, library, favorites, memberships, clubs, writer
    );

    private User owner() {
        var owner = mock(User.class);
        when(owner.getId()).thenReturn(42L);
        when(owner.getAnnualReadingGoal()).thenReturn(30);
        when(users.findByUsername("maria")).thenReturn(Optional.of(owner));
        when(current.requireIdentity()).thenReturn(
            new AuthenticatedFirebaseUser("edu-firebase", "edu@test.local", "Edu", true));
        return owner;
    }

    @Test
    void privateProfileWithoutApprovedFollowNeverReadsPrivateCollections() {
        var maria = owner();
        when(policy.canViewContent(maria, "edu-firebase")).thenReturn(false);

        assertThatThrownBy(() -> service.forUsername("maria"))
            .isInstanceOf(ApiException.class)
            .satisfies(error -> assertThat(((ApiException)error).getStatus().value()).isEqualTo(403));
        verifyNoInteractions(library, favorites, memberships, clubs, writer);
    }

    @Test
    void authorizedProfileReturnsOnlyOwnersCollections() {
        var maria = owner();
        when(policy.canViewContent(maria, "edu-firebase")).thenReturn(true);
        when(library.findByUserIdOrderByIdAsc(42L)).thenReturn(List.of());
        when(memberships.findByUserIdOrderByCreatedAtDescIdDesc(42L)).thenReturn(List.of());
        when(favorites.forOwner(42L)).thenReturn(List.of());
        when(writer.list(42L)).thenReturn(List.of());

        var response = service.forUsername("maria");
        assertThat(response.annualGoal()).isEqualTo(30);
        assertThat(response.library()).isEmpty();
        assertThat(response.favoriteBooks()).isEmpty();
        assertThat(response.clubs()).isEmpty();
        assertThat(response.publishedStories()).isEmpty();
        verify(library).findByUserIdOrderByIdAsc(42L);
        verify(writer).list(42L);
        verifyNoInteractions(clubs);
    }

    @Test
    void authorizedProfileNeverReturnsDraftStoriesOrUnpublishedChapters() {
        var maria = owner();
        when(policy.canViewContent(maria, "edu-firebase")).thenReturn(true);
        when(library.findByUserIdOrderByIdAsc(42L)).thenReturn(List.of());
        when(memberships.findByUserIdOrderByCreatedAtDescIdDesc(42L)).thenReturn(List.of());
        when(favorites.forOwner(42L)).thenReturn(List.of());
        var chapterPublished = new com.capitulo0.backend.writer.WriterDocument.Chapter(
            "one", "Uno", "Visible", 1, true, null, null);
        var chapterDraft = new com.capitulo0.backend.writer.WriterDocument.Chapter(
            "two", "Dos", "No visible", 2, false, null, null);
        var published = new com.capitulo0.backend.writer.WriterDocument(
            "published", "Obra publicada", "Sinopsis", "Cuento", null,
            "published", List.of(chapterPublished, chapterDraft), null, null, 1L, 0, 0.0);
        var draft = new com.capitulo0.backend.writer.WriterDocument(
            "draft", "Borrador secreto", "", "", null,
            "draft", List.of(), null, null, 0L, 0, 0.0);
        when(writer.list(42L)).thenReturn(List.of(published, draft));

        var response = service.forUsername("maria");
        assertThat(response.publishedStories()).hasSize(1);
        assertThat(response.publishedStories().get(0).title()).isEqualTo("Obra publicada");
        assertThat(response.publishedStories().get(0).chapters()).hasSize(1);
        assertThat(response.publishedStories().get(0).chapters().get(0).content()).isEqualTo("Visible");
    }
}
