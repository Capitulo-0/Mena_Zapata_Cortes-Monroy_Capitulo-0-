
package com.capitulo0.backend.auth.service;

import java.util.Locale;
import java.util.regex.Pattern;

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

    private static final Pattern USERNAME_PATTERN =
        Pattern.compile("^[a-z0-9_]{3,30}$");

    private record InitialEmail(
        @NotBlank @Email @Size(max = 320) String value
    ) {}

    private final UserRepository users;
    private final Validator validator;
    private final TransactionTemplate transaction;

    public UserProvisioningService(
        UserRepository users,
        Validator validator,
        PlatformTransactionManager manager
    ) {
        this.users = users;
        this.validator = validator;

        this.transaction = new TransactionTemplate(manager);
        this.transaction.setPropagationBehavior(
            TransactionDefinition.PROPAGATION_REQUIRES_NEW
        );
    }

    // Firebase proporciona la identidad autenticada.
    // El username se elige durante el registro inicial.
    public UserResponse provision(
        AuthenticatedFirebaseUser identity,
        String username
    ) {

        // Las cuentas existentes nunca se modifican
        // automáticamente durante la provisión.
        var existing = users.findByFirebaseUid(identity.uid());

        if (existing.isPresent()) {
            return UserMapper.toResponse(existing.get());
        }

        // Validar formato del username.
        if (username != null &&
            !USERNAME_PATTERN.matcher(username).matches()) {

            throw ApiException.invalid(
                "El nombre de usuario debe tener entre 3 y 30 " +
                "caracteres y solo puede contener letras minúsculas, " +
                "números y guiones bajos"
            );
        }

        // Exigir un correo verificado de Firebase.
        if (identity.email() == null || !identity.emailVerified()) {

            throw ApiException.invalid(
                "Se requiere un correo de Firebase verificado " +
                "para preparar la cuenta"
            );
        }

        String email = identity.email()
            .strip()
            .toLowerCase(Locale.ROOT);

        if (!validator.validate(new InitialEmail(email)).isEmpty()) {

            throw ApiException.invalid(
                "El correo verificado no es utilizable"
            );
        }

        try {

            return transaction.execute(status -> {

                // Segunda comprobación por Firebase UID.
                var found = users.findByFirebaseUid(identity.uid());

                if (found.isPresent()) {
                    return UserMapper.toResponse(found.get());
                }

                // Toda cuenta nueva debe tener username.
                if (username == null) {
                    throw ApiException.usernameRequired();
                }

                // No se hacen comprobaciones previas de
                // disponibilidad de email o username.
                //
                // Los índices UNIQUE de la base de datos
                // resolverán las inserciones concurrentes.

                User user = User.create();

                user.setFirebaseUid(identity.uid());
                user.setEmail(email);
                user.setUsername(username);

                String name = identity.displayName();

                if (name == null) {
                    user.setDisplayName(null);
                } else {
                    String cleanName = name.strip();

                    user.setDisplayName(
                        cleanName.substring(
                            0,
                            Math.min(cleanName.length(), 120)
                        )
                    );
                }

                return UserMapper.toResponse(
                    users.saveAndFlush(user)
                );
            });

        } catch (DataIntegrityViolationException conflict) {

            // La transacción de inserción ya terminó
            // con rollback.
            //
            // Consultar en una transacción nueva para
            // recuperar el registro ganador.

            return transaction.execute(status -> {

                // Prioridad: recuperar el mismo Firebase UID.
                // Esto mantiene la idempotencia incluso
                // cuando llegan solicitudes simultáneas.

                var found = users.findByFirebaseUid(identity.uid());

                if (found.isPresent()) {
                    return UserMapper.toResponse(found.get());
                }

                // Si el UID no existe, comprobar si el
                // username pertenece a otra cuenta.

                if (username != null &&
                    users.existsByUsername(username)) {

                    throw ApiException.usernameConflict();
                }

                // Si no fue un conflicto de UID ni username,
                // conservar la protección del correo.

                throw emailConflict();
            });
        }
    }

    private static ApiException emailConflict() {

        return ApiException.conflict(
            "El correo ya pertenece a una cuenta interna. " +
            "Se requiere una vinculación segura; " +
            "no se vinculó automáticamente"
        );
    }
}
