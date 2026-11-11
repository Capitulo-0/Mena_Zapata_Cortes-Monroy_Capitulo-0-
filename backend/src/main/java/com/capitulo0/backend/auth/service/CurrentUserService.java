package com.capitulo0.backend.auth.service;

import com.capitulo0.backend.auth.model.AuthenticatedFirebaseUser;
import com.capitulo0.backend.common.exception.ApiException;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.user.service.UserService;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationCredentialsNotFoundException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

@Service
public class CurrentUserService {
    private final UserService users;
    public CurrentUserService(UserService users) { this.users = users; }
    public AuthenticatedFirebaseUser requireIdentity() {
        var authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()
                || !(authentication.getPrincipal() instanceof AuthenticatedFirebaseUser principal)) {
            throw new AuthenticationCredentialsNotFoundException("Verified identity required");
        }
        return principal;
    }
    public User require() { return users.requireByFirebaseUid(requireIdentity().uid()); }
    public Long requireOwner(Long requestedUserId) {
        Long owner = require().getId();
        if (!owner.equals(requestedUserId)) throw new ApiException(HttpStatus.FORBIDDEN, "Acceso denegado");
        return owner;
    }
}
