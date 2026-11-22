package com.capitulo0.backend;

import com.capitulo0.backend.auth.model.AuthenticatedFirebaseUser;
import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.common.exception.ApiException;
import com.capitulo0.backend.user.dto.ReadingMoodRequest;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.repository.UserRepository;
import com.capitulo0.backend.user.service.ReadingMoodService;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.same;
import static org.mockito.Mockito.*;

class ReadingMoodServiceTests {
    private final CurrentUserService current = mock(CurrentUserService.class);
    private final UserRepository users = mock(UserRepository.class);
    private final ReadingMoodService service = new ReadingMoodService(current, users);

    private User authenticated() {
        var user = User.create();
        user.setFirebaseUid("maria-id");
        when(current.requireIdentity()).thenReturn(
            new AuthenticatedFirebaseUser("maria-id", "maria@test.local", "Maria", true));
        when(users.findByFirebaseUid("maria-id")).thenReturn(Optional.of(user));
        when(users.saveAndFlush(same(user))).thenReturn(user);
        return user;
    }

    @Test
    void savesAndRemovesTheSameUsersMood() {
        var user = authenticated();
        var mood = service.save(new ReadingMoodRequest("☕", "Leyendo con cafecito", "Sin prisa"));
        assertThat(mood.label()).isEqualTo("Leyendo con cafecito");
        assertThat(user.getReadingMoodEmoji()).isEqualTo("☕");
        assertThat(user.getReadingMoodDetail()).isEqualTo("Sin prisa");
        assertThat(service.save(new ReadingMoodRequest(null, null, null))).isNull();
        assertThat(user.getReadingMoodEmoji()).isNull();
        assertThat(user.getReadingMoodTitle()).isNull();
        assertThat(user.getReadingMoodDetail()).isNull();
        verify(users, times(2)).saveAndFlush(same(user));
    }

    @Test
    void rejectsIncompleteMoodWithoutSaving() {
        authenticated();
        assertThatThrownBy(() -> service.save(new ReadingMoodRequest("☕", " ", "Detalle")))
            .isInstanceOf(ApiException.class);
        verify(users, never()).saveAndFlush(any(User.class));
    }
}
