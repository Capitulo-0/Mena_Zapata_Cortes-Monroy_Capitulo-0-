package com.capitulo0.backend.auth.controller;

import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.user.dto.UserResponse;
import com.capitulo0.backend.user.mapper.UserMapper;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class MeController {
    private final CurrentUserService current;
    public MeController(CurrentUserService current) { this.current = current; }
    @GetMapping("/api/me")
    public UserResponse me() { return UserMapper.toResponse(current.require()); }
}
