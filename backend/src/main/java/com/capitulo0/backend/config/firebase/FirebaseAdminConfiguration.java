package com.capitulo0.backend.config.firebase;

import java.io.IOException;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.auth.FirebaseAuth;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Lazy;

@Configuration(proxyBeanMethods = false)
public class FirebaseAdminConfiguration {
    @Bean(destroyMethod = "")
    @Lazy
    public FirebaseApp firebaseApp(@Value("${firebase.project-id:}") String projectId) throws IOException {
        if (projectId.isBlank()) throw new IllegalStateException("Firebase project is not configured");
        String emulator = System.getenv("FIREBASE_AUTH_EMULATOR_HOST");
        if (emulator != null && !emulator.isBlank()) {
            throw new IllegalStateException("Firebase Auth emulator is not allowed in this backend");
        }
        String appName = "capitulo-0-backend-" + projectId;
        // A named, process-wide app survives DevTools restarts without duplicate initialization.
        synchronized (FirebaseApp.class) {
            for (FirebaseApp app : FirebaseApp.getApps()) {
                if (appName.equals(app.getName())) return app;
            }
            return FirebaseApp.initializeApp(FirebaseOptions.builder()
                .setProjectId(projectId)
                .setCredentials(GoogleCredentials.getApplicationDefault())
                .build(), appName);
        }
    }

    @Bean
    @Lazy
    public FirebaseAuth firebaseAuth(ObjectProvider<FirebaseApp> apps) {
        return FirebaseAuth.getInstance(apps.getObject());
    }
}
