package com.capitulo0.backend.auth.service;

import com.capitulo0.backend.auth.model.AuthenticatedFirebaseUser;

public interface FirebaseTokenVerifier {
    AuthenticatedFirebaseUser verify(String idToken);
}
