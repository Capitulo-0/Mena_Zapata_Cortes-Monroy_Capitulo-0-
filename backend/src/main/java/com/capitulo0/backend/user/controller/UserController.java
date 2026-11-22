package com.capitulo0.backend.user.controller;
import java.util.List;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import com.capitulo0.backend.user.dto.*;
import com.capitulo0.backend.user.service.UserService;
@RestController
@RequestMapping("/api/users")
public class UserController {
    private final UserService service;
    public UserController(UserService service) { this.service = service; }
    @PostMapping @ResponseStatus(HttpStatus.CREATED)
    public UserResponse create(@Valid @RequestBody CreateUserRequest request) { return service.create(request); }
    @GetMapping public List<UserResponse> list() { return service.list(); }
}
