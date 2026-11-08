package com.capitulo0.backend.auth.model;

import java.security.Principal;

public record AuthenticatedFirebaseUser(String uid, String email, String displayName) implements Principal {
    public AuthenticatedFirebaseUser {
        if (uid == null || uid.isBlank() || uid.length() > 128) {
            throw new IllegalArgumentException("Invalid verified identity");
        }
    }
    @Override public String getName() { return uid; }
}
