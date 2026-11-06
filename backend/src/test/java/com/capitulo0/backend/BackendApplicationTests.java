package com.capitulo0.backend;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@ActiveProfiles("test")
class BackendApplicationTests {

    @Autowired
    private JdbcTemplate jdbc;

    @Autowired
    private Flyway flyway;

    @Test
    void contextLoads() {
        assertThat(jdbc.queryForObject("SELECT 1", Integer.class)).isEqualTo(1);
    }

    @Test
    void migrationsPreserveTheTechnicalMarker() {
        assertThat(flyway.info().current().getVersion().getVersion()).isEqualTo("2");
        assertThat(jdbc.queryForObject(
                "SELECT service_name FROM backend_bootstrap WHERE id = 1", String.class))
                .isEqualTo("capitulo-0-backend");
        assertThat(jdbc.queryForObject(
                "SELECT COUNT(*) FROM flyway_schema_history WHERE success = TRUE AND version = '1'", Integer.class))
                .isEqualTo(1);
    }

    @Test
    void migrationCanRunAgainWithoutDuplicatingTheMarker() {
        flyway.migrate();
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM backend_bootstrap", Integer.class))
                .isEqualTo(1);
    }
}
