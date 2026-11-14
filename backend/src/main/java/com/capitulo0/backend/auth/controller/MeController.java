package com.capitulo0.backend.auth.controller;
import com.capitulo0.backend.auth.dto.ProvisionUserRequest;
import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.auth.service.UserProvisioningService;
import com.capitulo0.backend.user.dto.UpdateProfileRequest;
import com.capitulo0.backend.user.dto.UserResponse;
import com.capitulo0.backend.user.mapper.UserMapper;
import com.capitulo0.backend.user.service.ProfileUpdateService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
@RestController
public class MeController {
    private final CurrentUserService current;
    private final UserProvisioningService provisioning;
    private final ProfileUpdateService profileUpdate;
    public MeController(
        CurrentUserService current,
        UserProvisioningService provisioning,
        ProfileUpdateService profileUpdate
    ) {
        this.current = current;
        this.provisioning = provisioning;
        this.profileUpdate = profileUpdate;
    }
    @GetMapping("/api/me")
    public UserResponse me() {
        return UserMapper.toResponse(current.require());
    }
    @PostMapping("/api/me/provision")
    public UserResponse provision(
        @Valid @RequestBody(required = false) ProvisionUserRequest request
    ) {
        String username = request == null ? null : request.username();

        return provisioning.provision(
            current.requireIdentity(),
            username
        );
    }
    @PatchMapping("/api/me")
    public UserResponse updateProfile(
        @Valid @RequestBody UpdateProfileRequest request
    ) {
        return profileUpdate.update(request);
    }
}
