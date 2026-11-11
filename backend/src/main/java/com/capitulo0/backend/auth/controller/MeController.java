package com.capitulo0.backend.auth.controller;

import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.auth.service.UserProvisioningService;
import com.capitulo0.backend.user.dto.UserResponse;
import com.capitulo0.backend.user.mapper.UserMapper;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class MeController {
    private final CurrentUserService current;
    private final UserProvisioningService provisioning;
    public MeController(CurrentUserService current, UserProvisioningService provisioning) {
        this.current = current;
        this.provisioning = provisioning;
    }
    @GetMapping("/api/me")
    public UserResponse me() { return UserMapper.toResponse(current.require()); }
    @PostMapping("/api/me/provision")
    public UserResponse provision() { return provisioning.provision(current.requireIdentity()); }
}
