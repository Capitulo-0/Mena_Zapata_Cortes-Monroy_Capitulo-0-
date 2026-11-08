package com.capitulo0.backend;

import java.util.Arrays;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;
import com.capitulo0.backend.common.exception.ApiException;
import com.capitulo0.backend.user.dto.UserResponse;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.mapper.UserMapper;
import com.capitulo0.backend.user.repository.UserRepository;
import com.capitulo0.backend.user.service.UserService;
import tools.jackson.databind.json.JsonMapper;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class UserFirebaseIdentityTests {
    @Autowired private UserRepository users;
    @Autowired private UserService service;

    private User save(String uid) {
        User user = User.create();
        user.setEmail(UUID.randomUUID() + "@example.test");
        user.setDisplayName("Test user");
        user.setFirebaseUid(uid);
        return users.saveAndFlush(user);
    }

    @Test
    void findsByUidAndInternalIdWithoutReplacingEitherIdentity() {
        String uid = "CaseSensitive-" + UUID.randomUUID();
        User saved = save(uid);
        assertThat(saved.getId()).isPositive();
        assertThat(users.findById(saved.getId())).get().extracting(User::getFirebaseUid).isEqualTo(uid);
        assertThat(users.findByFirebaseUid(uid)).get().extracting(User::getId).isEqualTo(saved.getId());
        assertThat(users.existsByFirebaseUid(uid)).isTrue();
        assertThat(service.requireByFirebaseUid(uid).getId()).isEqualTo(saved.getId());
        assertThat(users.findByFirebaseUid(uid.toLowerCase(java.util.Locale.ROOT))).isEmpty();
        assertThat(users.existsByEmailIgnoreCase(saved.getEmail().toUpperCase(java.util.Locale.ROOT))).isTrue();
    }

    @Test
    void rejectsDuplicateNonNullUidEvenWithDifferentEmails() {
        String uid = UUID.randomUUID().toString();
        save(uid);
        assertThatThrownBy(() -> save(uid)).isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void allowsMultipleUnlinkedMvpUsersAndPreservesTheirIds() {
        User first = save(null);
        User second = save(null);
        assertThat(first.getId()).isNotEqualTo(second.getId());
        assertThat(users.findById(first.getId())).get().extracting(User::getFirebaseUid).isNull();
        assertThat(users.findById(second.getId())).get().extracting(User::getFirebaseUid).isNull();
        assertThat(service.require(first.getId()).getEmail()).isEqualTo(first.getEmail());
    }

    @Test
    void missingUidDoesNotMatchAnUnlinkedUser() {
        save(null);
        String missing = UUID.randomUUID().toString();
        assertThat(users.findByFirebaseUid(missing)).isEmpty();
        assertThat(users.existsByFirebaseUid(missing)).isFalse();
        assertThatThrownBy(() -> service.requireByFirebaseUid(missing))
            .isInstanceOfSatisfying(ApiException.class,
                error -> assertThat(error.getStatus()).isEqualTo(HttpStatus.NOT_FOUND));
    }

    @Test
    void rejectsAbsentOrBlankUidBeforeLookingUpLegacyAccounts() {
        save(null);
        for (String invalid : new String[] {null, "", "   "}) {
            assertThatThrownBy(() -> service.requireByFirebaseUid(invalid))
                .isInstanceOfSatisfying(ApiException.class,
                    error -> assertThat(error.getStatus()).isEqualTo(HttpStatus.BAD_REQUEST));
        }
    }

    @Test
    void publicResponseDoesNotExposeFirebaseUid() {
        User saved = save(UUID.randomUUID().toString());
        UserResponse response = UserMapper.toResponse(saved);
        assertThat(response.id()).isEqualTo(saved.getId());
        assertThat(response.email()).isEqualTo(saved.getEmail());
        assertThat(Arrays.stream(UserResponse.class.getRecordComponents()).map(component -> component.getName()))
            .doesNotContain("firebaseUid", "firebase_uid");
        var json = JsonMapper.builder().build().valueToTree(response);
        assertThat(json.has("firebaseUid")).isFalse();
        assertThat(json.has("firebase_uid")).isFalse();
    }
}
