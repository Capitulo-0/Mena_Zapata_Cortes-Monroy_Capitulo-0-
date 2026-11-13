
package com.capitulo0.backend.common.exception;

import java.time.Instant;
import java.util.List;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.*;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
@RestControllerAdvice
public class ApiExceptionHandler {
    public record ApiError(
        int status,
        String code,
        String message,
        List<String> details,
        Instant timestamp
    ) {}
    private ResponseEntity<ApiError> response(
        HttpStatus status,
        String message,
        List<String> details
    ) {
        return response(
            status,
            "GENERAL_ERROR",
            message,
            details
        );
    }
    private ResponseEntity<ApiError> response(
        HttpStatus status,
        String code,
        String message,
        List<String> details
    ) {
        return ResponseEntity.status(status).body(
            new ApiError(
                status.value(),
                code,
                message,
                details,
                Instant.now()
            )
        );
    }
    @ExceptionHandler(
        org.springframework.security.access.AccessDeniedException.class
    )
    public ResponseEntity<ApiError> forbidden(
        org.springframework.security.access.AccessDeniedException ex
    ) {
        return response(
            HttpStatus.FORBIDDEN,
            "Acceso denegado",
            List.of()
        );
    }
    @ExceptionHandler(
        org.springframework.security.core.AuthenticationException.class
    )
    public ResponseEntity<ApiError> unauthenticated(
        org.springframework.security.core.AuthenticationException ex
    ) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
            .header("WWW-Authenticate", "Bearer")
            .body(
                new ApiError(
                    401,
                    "GENERAL_ERROR",
                    "Autenticacion requerida",
                    List.of(),
                    Instant.now()
                )
            );
    }
    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ApiError> domain(ApiException ex) {
        return response(
            ex.getStatus(),
            ex.getCode(),
            ex.getMessage(),
            List.of()
        );
    }
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> validation(
        MethodArgumentNotValidException ex
    ) {
        return response(
            HttpStatus.BAD_REQUEST,
            "Datos no válidos",
            ex.getBindingResult()
                .getFieldErrors()
                .stream()
                .map(error ->
                    error.getField() + ": " + error.getDefaultMessage()
                )
                .sorted()
                .toList()
        );
    }
    @ExceptionHandler({
        HttpMessageNotReadableException.class,
        MethodArgumentTypeMismatchException.class
    })
    public ResponseEntity<ApiError> malformed(Exception ex) {
        return response(
            HttpStatus.BAD_REQUEST,
            "JSON, identificador o valor de enumeración no válido",
            List.of()
        );
    }
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiError> integrity(
        DataIntegrityViolationException ex
    ) {
        return response(
            HttpStatus.CONFLICT,
            "La operación viola una restricción de integridad o duplicado",
            List.of()
        );
    }
}
