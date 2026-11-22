
package com.capitulo0.backend.user.service;

import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.common.exception.ApiException;
import com.capitulo0.backend.user.dto.UpdatePrivacyRequest;
import com.capitulo0.backend.user.dto.UserResponse;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.mapper.UserMapper;
import com.capitulo0.backend.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ProfilePrivacyService {

    private final CurrentUserService current;
    private final UserRepository users;

    public ProfilePrivacyService(
        CurrentUserService current,
        UserRepository users
    ) {
        this.current = current;
        this.users = users;
    }

    @Transactional
    public UserResponse update(UpdatePrivacyRequest request) {
        // Identificar al usuario autenticado mediante Firebase.
        String firebaseUid = current.requireIdentity().uid();

        // Buscar exclusivamente la cuenta del usuario autenticado.
        User user = users.findByFirebaseUid(firebaseUid)
            .orElseThrow(() -> ApiException.notFound("Usuario"));

        // Cambiar únicamente la configuración de privacidad.
        user.setIsPrivate(request.isPrivate());

        // Persistir el cambio y devolver los datos actualizados.
        return UserMapper.toResponse(users.saveAndFlush(user));
    }
}
