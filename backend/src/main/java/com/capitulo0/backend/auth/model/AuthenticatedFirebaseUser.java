package com.capitulo0.backend.auth.model;

import java.security.Principal;

public record AuthenticatedFirebaseUser(String uid, String email, String displayName,
        boolean emailVerified) implements Principal {
    public AuthenticatedFirebaseUser {
        if (uid == null || uid.isBlank() || uid.length() > 128) {
            throw new IllegalArgumentException("Invalid verified identity");
        }
    }
    // Existing callers without the claim never implicitly assert a verified email.
    public AuthenticatedFirebaseUser(String uid, String email, String displayName) {
        this(uid, email, displayName, false);
    }
    @Override public String getName() { return uid; }
}
