package com.capitulo0.backend.config.security;

import java.io.IOException;
import java.time.Instant;
import java.util.List;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import com.capitulo0.backend.common.exception.ApiExceptionHandler.ApiError;
import org.springframework.http.MediaType;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;
import tools.jackson.databind.ObjectMapper;

@Component
public class RestSecurityErrors implements AuthenticationEntryPoint, AccessDeniedHandler {
    private final ObjectMapper json;
    public RestSecurityErrors(ObjectMapper json) { this.json = json; }
    @Override public void commence(HttpServletRequest request, HttpServletResponse response,
            AuthenticationException exception) throws IOException {
        response.setHeader("WWW-Authenticate", "Bearer");
        write(response, 401, "Autenticacion requerida o token no valido");
    }
    @Override public void handle(HttpServletRequest request, HttpServletResponse response,
            AccessDeniedException exception) throws IOException {
        write(response, 403, "Acceso denegado");
    }
    public void unavailable(HttpServletResponse response) throws IOException {
        write(response, 503, "Servicio de identidad no disponible");
    }
    private void write(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-store");
        json.writeValue(response.getOutputStream(), new ApiError(status, message, List.of(), Instant.now()));
    }
}
