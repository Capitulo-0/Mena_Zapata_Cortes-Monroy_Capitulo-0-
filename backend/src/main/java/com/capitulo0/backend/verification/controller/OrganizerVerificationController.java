
package com.capitulo0.backend.verification.controller;

import com.capitulo0.backend.verification.dto.CreateVerificationRequest;
import com.capitulo0.backend.verification.dto.VerificationResponse;
import com.capitulo0.backend.verification.service.OrganizerVerificationService;
import jakarta.validation.Valid;
import java.util.Optional;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/organizer-verification")
public class OrganizerVerificationController {

    private final OrganizerVerificationService verification;

    public OrganizerVerificationController(
            OrganizerVerificationService verification
    ) {
        this.verification = verification;
    }

    @GetMapping("/me")
    public ResponseEntity<VerificationResponse> myStatus() {
        Optional<VerificationResponse> request =
                verification.myLatestRequest();

        return request
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    @PostMapping
    public ResponseEntity<VerificationResponse> submit(
            @Valid @RequestBody CreateVerificationRequest form
    ) {
        VerificationResponse created = verification.submit(form);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(created);
    }
}
