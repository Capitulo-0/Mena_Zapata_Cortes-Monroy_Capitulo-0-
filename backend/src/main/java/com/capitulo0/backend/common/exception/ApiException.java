
package com.capitulo0.backend.common.exception;

import org.springframework.http.HttpStatus;

public class ApiException extends RuntimeException {

    private final HttpStatus status;
    private final String code;

    public ApiException(HttpStatus status, String message) {
        this(status, "GENERAL_ERROR", message);
    }

    public ApiException(HttpStatus status, String code, String message) {
        super(message);
        this.status = status;
        this.code = code;
    }

    public HttpStatus getStatus() {
        return status;
    }

    public String getCode() {
        return code;
    }

    public static ApiException notFound(String resource) {
        return new ApiException(
            HttpStatus.NOT_FOUND,
            resource + " no encontrado"
        );
    }

    public static ApiException conflict(String message) {
        return new ApiException(
            HttpStatus.CONFLICT,
            message
        );
    }

    public static ApiException invalid(String message) {
        return new ApiException(
            HttpStatus.BAD_REQUEST,
            message
        );
    }

    public static ApiException usernameConflict() {
        return new ApiException(
            HttpStatus.CONFLICT,
            "USERNAME_TAKEN",
            "El nombre de usuario ya está en uso. Elige otro."
        );
    }
    public static ApiException usernameRequired() {
        return new ApiException(
            HttpStatus.BAD_REQUEST,
            "USERNAME_REQUIRED",
            "Debes elegir un nombre de usuario para completar tu cuenta."
        );
    }
}
