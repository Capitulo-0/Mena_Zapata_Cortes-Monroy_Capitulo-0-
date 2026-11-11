package com.capitulo0.backend;

import java.util.*;
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
    private UserProvisioningService service(UserRepository users) {
        var validator = mock(Validator.class);
        when(validator.validate(any())).thenReturn(Set.of());
        var transactions = mock(PlatformTransactionManager.class);
        when(transactions.getTransaction(any())).thenReturn(mock(TransactionStatus.class));
        return new UserProvisioningService(users, validator, transactions);
    }
    private User winner() {
        var user = User.create();
        ReflectionTestUtils.setField(user, "id", 42L);
        user.setFirebaseUid("verified-fixture-uid");
        user.setEmail("reader@example.test");
        return user;
    }
    @SuppressWarnings("unchecked")
    @Test void sameUidCommittedBetweenLookupAndEmailCheckReturnsWinner() {
        var users = mock(UserRepository.class);
        when(users.findByFirebaseUid("verified-fixture-uid"))
            .thenReturn(Optional.empty(), Optional.empty(), Optional.of(winner()));
        when(users.existsByEmailIgnoreCase("reader@example.test")).thenReturn(true);
        var result = service(users).provision(new AuthenticatedFirebaseUser(
            "verified-fixture-uid", "reader@example.test", null, true));
        assertThat(result.id()).isEqualTo(42L);
        verify(users, never()).saveAndFlush(any());
    }
    @SuppressWarnings("unchecked")
    @Test void uniqueInsertFailureIsRecoveredAfterFailedTransactionHasRolledBack() {
        var users = mock(UserRepository.class);
        when(users.findByFirebaseUid("verified-fixture-uid"))
            .thenReturn(Optional.empty(), Optional.empty(), Optional.of(winner()));
        when(users.saveAndFlush(any())).thenThrow(new DataIntegrityViolationException("fixture unique conflict"));
        var result = service(users).provision(new AuthenticatedFirebaseUser(
            "verified-fixture-uid", "reader@example.test", null, true));
        assertThat(result.id()).isEqualTo(42L);
    }
}
