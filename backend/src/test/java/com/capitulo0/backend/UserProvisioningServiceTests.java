
package com.capitulo0.backend;

import java.util.Optional;
import java.util.Set;

import com.capitulo0.backend.auth.model.AuthenticatedFirebaseUser;
import com.capitulo0.backend.auth.service.UserProvisioningService;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.repository.UserRepository;

import jakarta.validation.Validator;

import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionStatus;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class UserProvisioningServiceTests {

    private static final String UID = "verified-fixture-uid";
    private static final String EMAIL = "reader@example.test";
    private static final String USERNAME = "reader_123";

    private UserProvisioningService service(UserRepository users) {

        var validator = mock(Validator.class);

        when(validator.validate(any())).thenReturn(Set.of());

        var transactions = mock(PlatformTransactionManager.class);

        when(transactions.getTransaction(any()))
            .thenReturn(mock(TransactionStatus.class));

        return new UserProvisioningService(
            users,
            validator,
            transactions
        );
    }

    private AuthenticatedFirebaseUser identity() {
        return new AuthenticatedFirebaseUser(
            UID,
            EMAIL,
            null,
            true
        );
    }

    private User winner() {

        var user = User.create();

        ReflectionTestUtils.setField(user, "id", 42L);

        user.setFirebaseUid(UID);
        user.setEmail(EMAIL);
        user.setUsername(USERNAME);

        return user;
    }

    @Test
    void sameUidCommittedBetweenLookupsReturnsWinner() {

        var users = mock(UserRepository.class);

        // Primera consulta: todavía no existe.
        // Segunda consulta: otra solicitud ya lo creó.
        when(users.findByFirebaseUid(UID))
            .thenReturn(
                Optional.empty(),
                Optional.of(winner())
            );

        var result = service(users).provision(
            identity(),
            USERNAME
        );

        assertThat(result.id()).isEqualTo(42L);
        assertThat(result.username()).isEqualTo(USERNAME);

        // No debemos crear un segundo usuario.
        verify(users, never()).saveAndFlush(any());
    }

    @Test
    void uniqueInsertFailureIsRecoveredAfterFailedTransactionHasRolledBack() {

        var users = mock(UserRepository.class);

        // Primera consulta: no existe.
        // Segunda consulta: todavía no existe.
        // Tras la colisión: recuperamos al ganador.
        when(users.findByFirebaseUid(UID))
            .thenReturn(
                Optional.empty(),
                Optional.empty(),
                Optional.of(winner())
            );

        // Simulamos una colisión con un índice UNIQUE.
        when(users.saveAndFlush(any()))
            .thenThrow(
                new DataIntegrityViolationException(
                    "fixture unique conflict"
                )
            );

        var result = service(users).provision(
            identity(),
            USERNAME
        );

        assertThat(result.id()).isEqualTo(42L);
        assertThat(result.username()).isEqualTo(USERNAME);

        verify(users, times(1)).saveAndFlush(any());

        // Se utiliza una segunda transacción para
        // recuperar el usuario después de la colisión.
    }
}
