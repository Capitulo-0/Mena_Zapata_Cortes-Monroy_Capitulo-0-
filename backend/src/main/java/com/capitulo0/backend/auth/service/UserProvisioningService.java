package com.capitulo0.backend.auth.service;

import java.util.Locale;
import com.capitulo0.backend.auth.model.AuthenticatedFirebaseUser;
import com.capitulo0.backend.common.exception.ApiException;
import com.capitulo0.backend.user.dto.UserResponse;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.mapper.UserMapper;
import com.capitulo0.backend.user.repository.UserRepository;
import jakarta.validation.Validator;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;

@Service
public class UserProvisioningService {
    private record InitialEmail(@NotBlank @Email @Size(max = 320) String value) {}
    private final UserRepository users;
    private final Validator validator;
    private final TransactionTemplate transaction;

    public UserProvisioningService(UserRepository users, Validator validator, PlatformTransactionManager manager) {
        this.users = users;
        this.validator = validator;
        transaction = new TransactionTemplate(manager);
        transaction.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
    }

    // No request DTO: all identity attributes originate in the verified principal.
    public UserResponse provision(AuthenticatedFirebaseUser identity) {
        var existing = users.findByFirebaseUid(identity.uid());
        if (existing.isPresent()) return UserMapper.toResponse(existing.get());
        if (identity.email() == null || !identity.emailVerified()) {
            throw ApiException.invalid("Se requiere un correo de Firebase verificado para preparar la cuenta");
        }
        String email = identity.email().strip().toLowerCase(Locale.ROOT);
        if (!validator.validate(new InitialEmail(email)).isEmpty()) {
            throw ApiException.invalid("El correo verificado no es utilizable");
        }
        try {
            return transaction.execute(status -> {
                var found = users.findByFirebaseUid(identity.uid());
                if (found.isPresent()) return UserMapper.toResponse(found.get());
                if (users.existsByEmailIgnoreCase(email)) {
                    // The UID may have been committed between our first lookup and this email query.
                    // Re-read by UID, never claim an account merely because its email matches.
                    return users.findByFirebaseUid(identity.uid())
                        .map(UserMapper::toResponse).orElseThrow(UserProvisioningService::emailConflict);
                }
                User user = User.create();
                user.setFirebaseUid(identity.uid());
                user.setEmail(email);
                String name = identity.displayName();
                user.setDisplayName(name == null ? null : name.strip().substring(0, Math.min(name.strip().length(), 120)));
                return UserMapper.toResponse(users.saveAndFlush(user));
            });
        } catch (DataIntegrityViolationException conflict) {
            // The failed insert has rolled back before this independent lookup.
            // A competing request with our UID is success; an email owned by anyone else is never linked.
            return transaction.execute(status -> users.findByFirebaseUid(identity.uid())
                .map(UserMapper::toResponse).orElseThrow(UserProvisioningService::emailConflict));
        }
    }

    private static ApiException emailConflict() {
        return ApiException.conflict("El correo ya pertenece a una cuenta interna. Se requiere una vinculación segura; no se vinculó automáticamente");
    }
}
