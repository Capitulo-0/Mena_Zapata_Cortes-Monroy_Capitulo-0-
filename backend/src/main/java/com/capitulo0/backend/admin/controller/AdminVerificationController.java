package com.capitulo0.backend.admin.controller;

import com.capitulo0.backend.admin.dto.AdminVerificationResponse;
import com.capitulo0.backend.admin.dto.RejectVerificationRequest;
import com.capitulo0.backend.admin.service.AdminVerificationService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/verifications")
public class AdminVerificationController {

    private final AdminVerificationService service;

    public AdminVerificationController(
            AdminVerificationService service
    ) {
        this.service = service;
    }

    @GetMapping
    public ResponseEntity<List<AdminVerificationResponse>> pending() {
        return ResponseEntity.ok(service.pendingRequests());
    }

    @PostMapping("/{id}/approve")
    public ResponseEntity<AdminVerificationResponse> approve(
            @PathVariable Long id
    ) {
        return ResponseEntity.ok(service.approve(id));
    }

    @PostMapping("/{id}/reject")
    public ResponseEntity<AdminVerificationResponse> reject(
            @PathVariable Long id,
            @Valid @RequestBody RejectVerificationRequest request
    ) {
        return ResponseEntity.ok(
                service.reject(id, request.reason())
        );
    }
}
