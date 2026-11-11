package com.capitulo0.backend.config.security;

import jakarta.servlet.DispatcherType;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import com.capitulo0.backend.auth.service.FirebaseTokenVerifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.ProviderNotFoundException;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.AnonymousAuthenticationFilter;

@Configuration(proxyBeanMethods = false)
public class SecurityConfiguration {
    // Prevent Boot's generated password/UserDetailsService; Bearer verification is the only mechanism.
    @Bean public AuthenticationManager authenticationManager() {
        return authentication -> { throw new ProviderNotFoundException("Only verified Firebase identity is supported"); };
    }
    @Bean public SecurityFilterChain securityFilterChain(HttpSecurity http, FirebaseTokenVerifier verifier,
            RestSecurityErrors errors, UrlBasedCorsConfigurationSource apiCorsConfigurationSource) throws Exception {
        return http
            .cors(cors -> cors.configurationSource(apiCorsConfigurationSource))
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .csrf(AbstractHttpConfigurer::disable)
            .formLogin(AbstractHttpConfigurer::disable)
            .httpBasic(AbstractHttpConfigurer::disable)
            .logout(AbstractHttpConfigurer::disable)
            .requestCache(AbstractHttpConfigurer::disable)
            .exceptionHandling(ex -> ex.authenticationEntryPoint(errors).accessDeniedHandler(errors))
            .authorizeHttpRequests(auth -> auth
                .dispatcherTypeMatchers(DispatcherType.ERROR).permitAll()
                .requestMatchers(HttpMethod.GET, "/api/health", "/api/books", "/api/books/*").permitAll()
                .requestMatchers("/api/users", "/api/users/").denyAll()
                .anyRequest().authenticated())
            .addFilterBefore(new FirebaseBearerFilter(verifier, errors), AnonymousAuthenticationFilter.class)
            .build();
    }
}
