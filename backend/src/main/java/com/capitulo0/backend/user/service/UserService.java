package com.capitulo0.backend.user.service;
import java.util.List;
import java.util.Locale;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.capitulo0.backend.user.repository.UserRepository;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.dto.*;
import com.capitulo0.backend.user.mapper.UserMapper;
import com.capitulo0.backend.common.exception.ApiException;
@Service
@Transactional(readOnly = true)
public class UserService {
    private final UserRepository users;
    public UserService(UserRepository users) { this.users = users; }
    public User require(Long id) { return users.findById(id).orElseThrow(() -> ApiException.notFound("Usuario")); }
    // Internal lookup only: callers must supply a UID from a verified token in the future.
    public User requireByFirebaseUid(String firebaseUid) {
        if (firebaseUid == null || firebaseUid.isBlank()) throw ApiException.invalid("Firebase UID requerido");
        return users.findByFirebaseUid(firebaseUid).orElseThrow(() -> ApiException.notFound("Usuario"));
    }
    public List<UserResponse> list() { return users.findAll(Sort.by("id")).stream().map(UserMapper::toResponse).toList(); }
    @Transactional
    public UserResponse create(CreateUserRequest request) {
        String email = request.email().strip().toLowerCase(Locale.ROOT);
        if (users.existsByEmailIgnoreCase(email)) throw ApiException.conflict("El email ya está registrado");
        User user = User.create();
        user.setEmail(email); user.setDisplayName(request.displayName());
        return UserMapper.toResponse(users.saveAndFlush(user));
    }
}
