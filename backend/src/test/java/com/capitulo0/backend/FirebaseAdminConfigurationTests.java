package com.capitulo0.backend;

import java.util.Date;
import java.util.UUID;
import com.capitulo0.backend.config.firebase.FirebaseAdminConfiguration;
import com.google.auth.oauth2.AccessToken;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class FirebaseAdminConfigurationTests {
    @Test void missingProjectFailsBeforeAttemptingAdc() {
        assertThatThrownBy(() -> new FirebaseAdminConfiguration().firebaseApp(""))
            .isInstanceOf(IllegalStateException.class).hasMessage("Firebase project is not configured");
    }
    @Test void reusesNamedAppWithoutCredentialsLookupOrNetwork() throws Exception {
        String project = "offline-" + UUID.randomUUID();
        String name = "capitulo-0-backend-" + project;
        // Synthetic credential, never used to call any Google service.
        var app = FirebaseApp.initializeApp(FirebaseOptions.builder().setProjectId(project)
            .setCredentials(GoogleCredentials.create(new AccessToken("offline-fixture", new Date(Long.MAX_VALUE))))
            .build(), name);
        try {
            var config = new FirebaseAdminConfiguration();
            assertThat(config.firebaseApp(project)).isSameAs(app);
            assertThat(config.firebaseApp(project)).isSameAs(app);
            assertThat(FirebaseApp.getApps().stream().filter(candidate -> name.equals(candidate.getName())).count()).isEqualTo(1);
        } finally { app.delete(); }
    }
}
