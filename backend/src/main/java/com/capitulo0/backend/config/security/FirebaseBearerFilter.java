package com.capitulo0.backend.config.security;

import java.io.IOException;
import java.util.Collections;
import java.util.List;
import java.util.regex.Pattern;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import com.capitulo0.backend.auth.service.FirebaseTokenVerifier;
import org.springframework.security.authentication.AuthenticationServiceException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

// Instantiated only inside SecurityFilterChain: never registered as a servlet filter bean.
public class FirebaseBearerFilter extends OncePerRequestFilter {
    private static final Pattern BEARER = Pattern.compile("(?i:Bearer) ([A-Za-z0-9._~+/-]+=*)");
    private final FirebaseTokenVerifier verifier;
    private final RestSecurityErrors errors;
    public FirebaseBearerFilter(FirebaseTokenVerifier verifier, RestSecurityErrors errors) {
        this.verifier = verifier; this.errors = errors;
    }
    @Override protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getServletPath();
        return "GET".equals(request.getMethod()) && (path.equals("/api/health")
            || path.equals("/api/books") || path.matches("/api/books/[^/]+"));
    }
    @Override protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
            FilterChain chain) throws ServletException, IOException {
        var headers = Collections.list(request.getHeaders("Authorization"));
        if (headers.isEmpty()) { chain.doFilter(request, response); return; }
        try {
            if (headers.size() != 1) throw new BadCredentialsException("Invalid authorization header");
            var bearer = BEARER.matcher(headers.get(0));
            if (!bearer.matches()) throw new BadCredentialsException("Invalid authorization header");
            var principal = verifier.verify(bearer.group(1));
            if (principal == null) throw new BadCredentialsException("Invalid identity");
            var context = SecurityContextHolder.createEmptyContext();
            context.setAuthentication(UsernamePasswordAuthenticationToken.authenticated(principal, null, List.of()));
            SecurityContextHolder.setContext(context);
        } catch (AuthenticationServiceException ex) {
            SecurityContextHolder.clearContext(); errors.unavailable(response); return;
        } catch (AuthenticationException ex) {
            SecurityContextHolder.clearContext(); errors.commence(request, response, ex); return;
        }
        chain.doFilter(request, response);
    }
}
