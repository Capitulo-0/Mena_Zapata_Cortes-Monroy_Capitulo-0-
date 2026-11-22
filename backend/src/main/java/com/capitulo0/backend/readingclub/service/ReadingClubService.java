
package com.capitulo0.backend.readingclub.service;

import com.capitulo0.backend.auth.model.AuthenticatedFirebaseUser;
import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.common.exception.ApiException;
import com.capitulo0.backend.readingclub.dto.CreateReadingClubRequest;
import com.capitulo0.backend.readingclub.dto.ReadingClubResponse;
import com.capitulo0.backend.readingclub.entity.ReadingClub;
import com.capitulo0.backend.readingclub.repository.ClubMembershipRepository;
import com.capitulo0.backend.readingclub.repository.ReadingClubRepository;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.repository.UserRepository;
import com.capitulo0.backend.verification.entity.VerificationStatus;
import com.capitulo0.backend.verification.repository.OrganizerVerificationRepository;
import com.capitulo0.backend.readingclub.entity.ClubMembership;

import java.util.List;
import java.util.Locale;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ReadingClubService {

    private final CurrentUserService current;
    private final ReadingClubRepository clubs;
    private final OrganizerVerificationRepository verifications;
    private final ClubMembershipRepository memberships;
    private final UserRepository users;

    public ReadingClubService(
            CurrentUserService current,
            ReadingClubRepository clubs,
            OrganizerVerificationRepository verifications,
            ClubMembershipRepository memberships,
            UserRepository users
    ) {
        this.current = current;
        this.clubs = clubs;
        this.verifications = verifications;
        this.memberships = memberships;
        this.users = users;
    }

    // =====================================================
    // CREAR CLUB - SOLO ORGANIZADORES VERIFICADOS
    // =====================================================

    @Transactional
    public ReadingClubResponse create(
            CreateReadingClubRequest form
    ) {
        User organizer = current.require();

        boolean approved = verifications.existsByUserIdAndStatus(
                organizer.getId(),
                VerificationStatus.APPROVED
        );

        if (!approved) {
            throw new ApiException(
                    HttpStatus.FORBIDDEN,
                    "Debes ser un organizador verificado "
                    + "por el equipo de Capítulo 0 para crear clubes"
            );
        }

        if (form == null) {
            throw ApiException.invalid(
                    "Los datos del club son obligatorios"
            );
        }

        String name = required(
                form.name(),
                "El nombre del club es obligatorio"
        );

        String description = required(
                form.description(),
                "La biografía del club es obligatoria"
        );

        if (name.length() > 150) {
            throw ApiException.invalid(
                    "El nombre no puede superar 150 caracteres"
            );
        }

        if (description.length() > 2000) {
            throw ApiException.invalid(
                    "La biografía no puede superar 2000 caracteres"
            );
        }

        if (form.meetingDate() == null ||
                form.meetingTime() == null) {
            throw ApiException.invalid(
                    "La fecha y hora son obligatorias"
            );
        }

        String modality = required(
                form.modality(),
                "La modalidad es obligatoria"
        ).toUpperCase(Locale.ROOT);

        if (!modality.equals("ONLINE") &&
                !modality.equals("PRESENCIAL")) {
            throw ApiException.invalid(
                    "La modalidad debe ser ONLINE o PRESENCIAL"
            );
        }

        String meetingPlace = optional(form.meetingPlace());

        if (modality.equals("PRESENCIAL") &&
                meetingPlace == null) {
            throw ApiException.invalid(
                    "Debes indicar el lugar de reunión presencial"
            );
        }

        if (meetingPlace != null &&
                meetingPlace.length() > 300) {
            throw ApiException.invalid(
                    "El lugar no puede superar 300 caracteres"
            );
        }

        if (modality.equals("ONLINE")) {
            meetingPlace = null;
        }

        String instagram = optional(form.instagram());
        String facebook = optional(form.facebook());
        String xHandle = optional(form.xHandle());

        validateSocial(instagram, "Instagram");
        validateSocial(facebook, "Facebook");
        validateSocial(xHandle, "X");

        ReadingClub club = new ReadingClub(
                organizer.getId(),
                name,
                description,
                form.meetingDate(),
                form.meetingTime(),
                modality,
                meetingPlace,
                instagram,
                facebook,
                xHandle
        );

        ReadingClub saved = clubs.saveAndFlush(club);

        return new ReadingClubResponse(
                saved.getId(),
                saved.getName(),
                saved.getDescription(),
                organizer.getId(),
                organizer.getUsername(),
                saved.getMeetingDate(),
                saved.getMeetingTime(),
                saved.getModality(),
                saved.getMeetingPlace(),
                saved.getInstagram(),
                saved.getFacebook(),
                saved.getXHandle(),
                0L,
                false,
                saved.getStatus()
        );
    }

    // =====================================================
    // HOME - MOSTRAR MAXIMO 3 CLUBES ACTIVOS
    // =====================================================

    @Transactional(readOnly = true)
    public List<ReadingClubResponse> homeClubs() {
        Long viewerId = optionalViewerId();

        var page = PageRequest.of(
                0,
                3,
                Sort.by(
                        Sort.Order.desc("createdAt"),
                        Sort.Order.desc("id")
                )
        );

        return clubs.findByStatus("ACTIVE", page)
                .getContent()
                .stream()
                .map(club -> toResponse(club, viewerId))
                .toList();
    }

    // =====================================================
    // VER TODOS - LISTADO PAGINADO DE CLUBES ACTIVOS
    // =====================================================

    @Transactional(readOnly = true)
    public Page<ReadingClubResponse> allClubs(
            int page,
            int size
    ) {
        if (page < 0) {
            throw ApiException.invalid(
                    "La página no puede ser negativa"
            );
        }

        if (size < 1 || size > 30) {
            throw ApiException.invalid(
                    "La cantidad por página debe estar entre 1 y 30"
            );
        }

        Long viewerId = optionalViewerId();

        Pageable pageable = PageRequest.of(
                page,
                size,
                Sort.by(
                        Sort.Order.desc("createdAt"),
                        Sort.Order.desc("id")
                )
        );

        return clubs.findByStatus("ACTIVE", pageable)
                .map(club -> toResponse(club, viewerId));
    }

    // =====================================================
    // DETALLE PUBLICO DE UN CLUB
    // =====================================================

    @Transactional(readOnly = true)
    public ReadingClubResponse clubDetail(Long clubId) {
        if (clubId == null || clubId <= 0) {
            throw ApiException.invalid(
                    "Identificador de club no válido"
            );
        }

        ReadingClub club = clubs.findById(clubId)
                .orElseThrow(() ->
                        ApiException.notFound("Club")
                );

        if (!"ACTIVE".equals(club.getStatus())) {
            throw ApiException.notFound("Club");
        }

        return toResponse(club, optionalViewerId());
    }

    // =====================================================
    // UNIRSE A UN CLUB - MEMBRESIA PERSISTENTE
    // =====================================================

    @Transactional
    public ReadingClubResponse joinClub(Long clubId) {
        User user = current.require();

        ReadingClub club = requireActiveClub(clubId);

        if (memberships.existsByClubIdAndUserId(
                club.getId(),
                user.getId()
        )) {
            throw ApiException.conflict(
                    "Ya perteneces a este club de lectura"
            );
        }

        ClubMembership membership = new ClubMembership(
                club.getId(),
                user.getId()
        );

        memberships.saveAndFlush(membership);

        return toResponse(club, user.getId());
    }

    // =====================================================
    // ABANDONAR CLUB - ELIMINAR MEMBRESIA PERSONAL
    // =====================================================

    @Transactional
    public ReadingClubResponse leaveClub(Long clubId) {
        User user = current.require();

        ReadingClub club = requireActiveClub(clubId);

        ClubMembership membership = memberships
                .findByClubIdAndUserId(
                        club.getId(),
                        user.getId()
                )
                .orElseThrow(() ->
                        ApiException.conflict(
                                "No perteneces a este club de lectura"
                        )
                );

        memberships.delete(membership);
        memberships.flush();

        return toResponse(club, user.getId());
    }

    // =====================================================
    // VALIDAR QUE EL CLUB EXISTA Y ESTE ACTIVO
    // =====================================================

    private ReadingClub requireActiveClub(Long clubId) {
        if (clubId == null || clubId <= 0) {
            throw ApiException.invalid(
                    "Identificador de club no válido"
            );
        }

        ReadingClub club = clubs.findById(clubId)
                .orElseThrow(() ->
                        ApiException.notFound("Club")
                );

        if (!"ACTIVE".equals(club.getStatus())) {
            throw ApiException.notFound("Club");
        }

        return club;
    }


    // =====================================================
    // MIS CLUBES - MEMBRESIAS DEL USUARIO AUTENTICADO
    // =====================================================

    @Transactional(readOnly = true)
    public List<ReadingClubResponse> myClubs() {
        Long userId = current.require().getId();

        return memberships
                .findByUserIdOrderByCreatedAtDescIdDesc(userId)
                .stream()
                .map(membership -> clubs.findById(
                        membership.getClubId()
                ).orElseThrow(() ->
                        ApiException.notFound("Club")
                ))
                .filter(club -> "ACTIVE".equals(club.getStatus()))
                .map(club -> toResponse(club, userId))
                .toList();
    }



    // =====================================================
    // IDENTIDAD OPCIONAL - INVITADOS Y AUTENTICADOS
    // =====================================================

    private Long optionalViewerId() {
        var authentication = SecurityContextHolder
                .getContext()
                .getAuthentication();

        if (authentication == null ||
                !authentication.isAuthenticated() ||
                !(authentication.getPrincipal()
                        instanceof AuthenticatedFirebaseUser principal)) {
            return null;
        }

        return users.findByFirebaseUid(principal.uid())
                .map(User::getId)
                .orElse(null);
    }

    // =====================================================
    // CONVERTIR ENTIDAD A RESPUESTA PARA FLUTTER
    // =====================================================

    private ReadingClubResponse toResponse(
            ReadingClub club,
            Long viewerId
    ) {
        User organizer = users.findById(
                club.getOrganizerUserId()
        ).orElseThrow(() ->
                ApiException.notFound("Organizador")
        );

        long membersCount = memberships.countByClubId(
                club.getId()
        );

        boolean joined = viewerId != null &&
                memberships.existsByClubIdAndUserId(
                        club.getId(),
                        viewerId
                );

        return new ReadingClubResponse(
                club.getId(),
                club.getName(),
                club.getDescription(),
                organizer.getId(),
                organizer.getUsername(),
                club.getMeetingDate(),
                club.getMeetingTime(),
                club.getModality(),
                club.getMeetingPlace(),
                club.getInstagram(),
                club.getFacebook(),
                club.getXHandle(),
                membersCount,
                joined,
                club.getStatus()
        );
    }

    // =====================================================
    // VALIDACIONES Y NORMALIZACION DE CAMPOS
    // =====================================================

    private static String required(
            String value,
            String message
    ) {
        if (value == null || value.isBlank()) {
            throw ApiException.invalid(message);
        }

        return value.strip();
    }

    private static String optional(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }

        return value.strip();
    }

    private static void validateSocial(
            String value,
            String network
    ) {
        if (value != null && value.length() > 200) {
            throw ApiException.invalid(
                    network + " no puede superar 200 caracteres"
            );
        }
    }
}
