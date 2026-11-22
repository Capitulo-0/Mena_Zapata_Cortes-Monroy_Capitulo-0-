package com.capitulo0.backend.user.service;

import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.common.exception.ApiException;
import com.capitulo0.backend.library.mapper.LibraryEntryMapper;
import com.capitulo0.backend.library.repository.LibraryEntryRepository;
import com.capitulo0.backend.readingclub.repository.ClubMembershipRepository;
import com.capitulo0.backend.readingclub.service.ReadingClubService;
import com.capitulo0.backend.user.dto.PublicProfileActivityResponse;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.repository.UserRepository;
import com.capitulo0.backend.writer.WriterDocument;
import com.capitulo0.backend.writer.WriterService;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PublicProfileActivityService {
    private final CurrentUserService current;
    private final UserRepository users;
    private final ProfileAccessPolicy access;
    private final LibraryEntryRepository library;
    private final UserBookFavoritesService favorites;
    private final ClubMembershipRepository memberships;
    private final ReadingClubService clubs;
    private final WriterService writer;

    public PublicProfileActivityService(CurrentUserService current, UserRepository users,
            ProfileAccessPolicy access, LibraryEntryRepository library,
            UserBookFavoritesService favorites, ClubMembershipRepository memberships,
            ReadingClubService clubs, WriterService writer) {
        this.current = current;
        this.users = users;
        this.access = access;
        this.library = library;
        this.favorites = favorites;
        this.memberships = memberships;
        this.clubs = clubs;
        this.writer = writer;
    }

    @Transactional(readOnly = true)
    public PublicProfileActivityResponse forUsername(String username) {
        String viewerUid = current.requireIdentity().uid();
        User owner = users.findByUsername(username)
            .orElseThrow(() -> ApiException.notFound("Usuario"));
        if (!access.canViewContent(owner, viewerUid)) {
            throw new ApiException(HttpStatus.FORBIDDEN,
                "No tienes autorización para consultar la actividad de este perfil.");
        }

        var entries = library.findByUserIdOrderByIdAsc(owner.getId()).stream()
            .map(LibraryEntryMapper::toResponse).toList();
        var ownerClubs = memberships.findByUserIdOrderByCreatedAtDescIdDesc(owner.getId())
            .stream()
            .map(membership -> {
                try {
                    return clubs.clubDetail(membership.getClubId());
                } catch (ApiException removedOrInactiveClub) {
                    if (removedOrInactiveClub.getStatus() == HttpStatus.NOT_FOUND) return null;
                    throw removedOrInactiveClub;
                }
            })
            .filter(java.util.Objects::nonNull)
            .toList();
        var publicWorks = writer.list(owner.getId()).stream()
            .filter(story -> "published".equals(story.status()))
            .map(story -> story.state("published",
                story.chapters().stream().filter(WriterDocument.Chapter::isPublished).toList(),
                story.createdAt(), story.updatedAt(), story.revision() == null ? 0 : story.revision()))
            .toList();
        return new PublicProfileActivityResponse(
            owner.getAnnualReadingGoal(), entries, favorites.forOwner(owner.getId()),
            ownerClubs, publicWorks
        );
    }
}
