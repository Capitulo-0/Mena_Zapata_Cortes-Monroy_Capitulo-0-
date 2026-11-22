
package com.capitulo0.backend.admin.service;

import com.capitulo0.backend.admin.repository.AdminRoleRepository;
import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.common.exception.ApiException;
import com.capitulo0.backend.user.entity.User;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminAuthorizationService {

    private final CurrentUserService current;
    private final AdminRoleRepository roles;

    public AdminAuthorizationService(
            CurrentUserService current,
            AdminRoleRepository roles
    ) {
        this.current = current;
        this.roles = roles;
    }

    @Transactional(readOnly = true)
    public boolean isCurrentUserAdmin() {
        User user = current.require();
        return roles.isAdmin(user.getId());
    }

    @Transactional(readOnly = true)
    public User requireAdmin() {
        User user = current.require();

        if (!roles.isAdmin(user.getId())) {
            throw new ApiException(
                    HttpStatus.FORBIDDEN,
                    "Se requieren permisos de administrador"
            );
        }

        return user;
    }
}
