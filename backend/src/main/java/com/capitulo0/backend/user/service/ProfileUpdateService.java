package com.capitulo0.backend.user.service;
import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.common.exception.ApiException;
import com.capitulo0.backend.user.dto.UpdateProfileRequest;
import com.capitulo0.backend.user.dto.UserResponse;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.mapper.UserMapper;
import com.capitulo0.backend.user.repository.UserRepository;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;

@Service
public class ProfileUpdateService {
    private final CurrentUserService current;
    private final UserRepository users;
    private final TransactionTemplate transaction;
    public ProfileUpdateService(
        CurrentUserService current,
        UserRepository users,
        PlatformTransactionManager manager
    ) {
        this.current = current;
        this.users = users;
        this.transaction = new TransactionTemplate(manager);
        this.transaction.setPropagationBehavior(
            TransactionDefinition.PROPAGATION_REQUIRES_NEW
        );
    }
    public UserResponse update(UpdateProfileRequest request) {
        // Obtener la identidad verificada mediante Firebase.
        String firebaseUid = current.requireIdentity().uid();
        try {
            return transaction.execute(status -> {
                // Buscar exclusivamente al usuario autenticado.
                User user = users.findByFirebaseUid(firebaseUid)
                    .orElseThrow(() -> ApiException.notFound("Usuario"));
                // Actualizar nombre visible.
                if (request.displayName() != null) {
                    String name = request.displayName().strip();
                    if (name.isEmpty()) {
                        throw ApiException.invalid(
                            "El nombre no puede estar vacío"
                        );
                    }
                    user.setDisplayName(name);
                }
                // Actualizar username.
                if (request.username() != null) {
                    String username = request.username();
                    if (!username.equals(user.getUsername())) {
                        if (users.existsByUsername(username)) {
                            throw ApiException.usernameConflict();
                        }
                        user.setUsername(username);
                    }
                }
                // Actualizar biografía.
                if (request.biography() != null) {
                    user.setBiography(request.biography().strip());
                }
                // Actualizar meta anual.
                if (request.annualReadingGoal() != null) {
                    user.setAnnualReadingGoal(
                        request.annualReadingGoal()
                    );
                }
                // Guardar y forzar la escritura en la BD.
                return UserMapper.toResponse(
                    users.saveAndFlush(user)
                );
            });
        } catch (DataIntegrityViolationException exception) {
            // La restricción UNIQUE de PostgreSQL sigue
            // protegiendo contra cambios simultáneos.
            //
            // Por ahora dejamos el conflicto como genérico.
            // Más adelante distinguiremos el índice concreto
            // si necesitamos mensajes específicos.
            throw ApiException.conflict(
                "No se pudieron guardar los cambios. " +
                "Comprueba que los datos no estén en uso."
            );
        }
    }
}
