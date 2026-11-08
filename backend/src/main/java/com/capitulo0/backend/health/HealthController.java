package com.capitulo0.backend.health;

import java.sql.Connection;
import java.sql.SQLException;

import javax.sql.DataSource;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {

    private final DataSource dataSource;

    public HealthController(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @GetMapping("/api/health")
    public ResponseEntity<HealthResponse> health() {
        try (Connection connection = dataSource.getConnection()) {
            if (connection.isValid(2)) {
                return ResponseEntity.ok(new HealthResponse("UP", "capitulo-0-backend", "UP"));
            }
        } catch (SQLException ignored) {
            // Never expose connection URLs, credentials or internal exception messages.
        }
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(new HealthResponse("DOWN", "capitulo-0-backend", "DOWN"));
    }

    public record HealthResponse(String status, String service, String database) {
    }
}
