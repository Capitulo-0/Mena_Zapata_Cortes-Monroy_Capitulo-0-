package com.capitulo0.backend.user.service;

import com.capitulo0.backend.follow.entity.UserFollow.Status;
import com.capitulo0.backend.follow.repository.UserFollowRepository;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.repository.UserRepository;
import org.springframework.stereotype.Component;

@Component
public class ProfileAccessPolicy {

    private final UserRepository users;
    private final UserFollowRepository follows;

    public ProfileAccessPolicy(UserRepository users, UserFollowRepository follows) {
        this.users = users;
        this.follows = follows;
    }

    public boolean canViewContent(User profileOwner, String viewerFirebaseUid) {
        // Los perfiles públicos son visibles para cualquier visitante autenticado.
        if (!Boolean.TRUE.equals(profileOwner.getIsPrivate())) {
            return true;
        }

        if (viewerFirebaseUid == null || viewerFirebaseUid.isBlank()) {
            return false;
        }

        // El propietario conserva siempre acceso a su contenido.
        if (viewerFirebaseUid.equals(profileOwner.getFirebaseUid())) {
            return true;
        }

        // Las solicitudes pendientes NO conceden acceso al perfil privado.
        return users.findByFirebaseUid(viewerFirebaseUid)
                .flatMap(viewer -> follows.findByFollowerIdAndFollowingId(
                        viewer.getId(), profileOwner.getId()))
                .map(relationship -> relationship.getStatus() == Status.ACCEPTED)
                .orElse(false);
    }
}
