package com.capitulo0.backend;
import com.capitulo0.backend.user.dto.UserResponse;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.mapper.UserMapper;
import org.junit.jupiter.api.Test;
import java.lang.reflect.RecordComponent;
import java.util.Arrays;
import static org.assertj.core.api.Assertions.assertThat;
class UserMapperTests {
    @Test
    void mapsProfileFieldsCorrectly() {
        User user = User.create();
        user.setEmail("edu@example.test");
        user.setDisplayName("Eduardo");
        user.setFirebaseUid("firebase-secret-123");
        user.setUsername("edu");
        user.setBiography("Me encanta leer.");
        user.setAvatarUrl("https://example.test/avatar.png");
        UserResponse response = UserMapper.toResponse(user);
        assertThat(response.email()).isEqualTo("edu@example.test");
        assertThat(response.displayName()).isEqualTo("Eduardo");
        assertThat(response.username()).isEqualTo("edu");
        assertThat(response.biography()).isEqualTo("Me encanta leer.");
        assertThat(response.avatarUrl())
            .isEqualTo("https://example.test/avatar.png");
    }
    @Test
    void allowsProfileFieldsToBeNull() {
        User user = User.create();
        user.setEmail("new@example.test");
        UserResponse response = UserMapper.toResponse(user);
        assertThat(response.username()).isNull();
        assertThat(response.biography()).isNull();
        assertThat(response.avatarUrl()).isNull();
    }
    @Test
    void doesNotExposeFirebaseUidInResponse() {
        String[] responseFields = Arrays.stream(
            UserResponse.class.getRecordComponents()
        )
        .map(RecordComponent::getName)
        .toArray(String[]::new);
        assertThat(responseFields)
            .doesNotContain("firebaseUid");
    }
}
