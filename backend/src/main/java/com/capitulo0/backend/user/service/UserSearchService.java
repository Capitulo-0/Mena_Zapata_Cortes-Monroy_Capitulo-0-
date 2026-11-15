package com.capitulo0.backend.user.service;

import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.user.dto.UserSearchResponse;
import com.capitulo0.backend.user.repository.UserRepository;
import java.util.List;
import java.util.Locale;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserSearchService {

    private static final int MAX_RESULTS = 10;
    private static final int MAX_QUERY_LENGTH = 100;

    private final UserRepository users;
    private final CurrentUserService current;

    public UserSearchService(
        UserRepository users,
        CurrentUserService current
    ) {
        this.users = users;
        this.current = current;
    }

    @Transactional(readOnly = true)
    public List<UserSearchResponse> search(String query) {

        // Solo usuarios autenticados pueden buscar perfiles.
        current.requireIdentity();

        if (query == null || query.isBlank()) {
            return List.of();
        }

        String normalized = query.trim();

        // Permitir búsquedas con @username.
        if (normalized.startsWith("@")) {
            normalized = normalized.substring(1).trim();
        }

        if (normalized.isEmpty()
                || normalized.length() > MAX_QUERY_LENGTH) {
            return List.of();
        }

        normalized = normalized.toLowerCase(Locale.ROOT);

        // Escapar caracteres especiales de SQL LIKE.
        String escaped = normalized
            .replace("!", "!!")
            .replace("%", "!%")
            .replace("_", "!_");

        String pattern = "%" + escaped + "%";
        String prefix = escaped + "%";

        return users.searchProfiles(
            normalized,
            pattern,
            prefix,
            PageRequest.of(0, MAX_RESULTS)
        ).stream()
            .map(user -> new UserSearchResponse(
                user.getDisplayName(),
                user.getUsername(),
                user.getAvatarUrl()
            ))
            .toList();
    }
}
