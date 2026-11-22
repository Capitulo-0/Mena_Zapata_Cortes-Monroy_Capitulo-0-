package com.capitulo0.backend.admin.controller;

import com.capitulo0.backend.admin.service.AdminAuthorizationService;
import com.capitulo0.backend.user.entity.User;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    private final AdminAuthorizationService authorization;

    public AdminController(AdminAuthorizationService authorization) {
        this.authorization = authorization;
    }

    @GetMapping("/me")
    public Map<String, Object> me() {
        User admin = authorization.requireAdmin();

        return Map.of(
                "id", admin.getId(),
                "role", "ADMIN"
        );
    }
}
