package com.capitulo0.backend;

import org.h2.jdbcx.JdbcConnectionPool;
import java.util.UUID;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.assertThat;

class FirebaseIdentityMigrationTests {
    @Test
    void upgradesV2WithoutChangingExistingUsersOrLibraryAndCanRunAgain() throws Exception {
        String url = "jdbc:h2:mem:identity-migration-" + UUID.randomUUID()
            + ";MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE";
        // Pool keeps H2 constraint-compilation sessions alive across Flyway operations.
        // Dispose all connections after this isolated in-memory test.
        var dataSource = JdbcConnectionPool.create(url, "sa", "");
        try (var connection = dataSource.getConnection();
             var statement = connection.createStatement()) {
            Flyway.configure().dataSource(dataSource).target("2").load().migrate();
            statement.executeUpdate("INSERT INTO users (id,email,display_name,created_at,updated_at) "
                + "VALUES (41,'legacy@example.test','Legacy',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)");
            statement.executeUpdate("INSERT INTO books (id,title,created_at,updated_at) "
                + "VALUES (51,'Existing book',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)");
            statement.executeUpdate("INSERT INTO library_entries "
                + "(id,user_id,book_id,status,reading_format,current_page,total_pages,created_at,updated_at) "
                + "VALUES (61,41,51,'LEYENDO','FISICO',25,100,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)");
            java.time.OffsetDateTime originalCreatedAt;
            java.time.OffsetDateTime originalUpdatedAt;
            try (var row = statement.executeQuery("SELECT created_at,updated_at FROM users WHERE id=41")) {
                assertThat(row.next()).isTrue();
                originalCreatedAt = row.getObject(1, java.time.OffsetDateTime.class);
                originalUpdatedAt = row.getObject(2, java.time.OffsetDateTime.class);
            }

            Flyway flyway = Flyway.configure().dataSource(dataSource).target("3").load();
            assertThat(flyway.migrate().migrationsExecuted).isEqualTo(1);
            assertThat(flyway.info().current().getVersion().getVersion()).isEqualTo("3");
            try (var row = statement.executeQuery("SELECT u.id,u.email,u.display_name,u.firebase_uid,"
                    + "u.created_at,u.updated_at,l.id,l.book_id,l.current_page,l.total_pages,l.status "
                    + "FROM users u JOIN library_entries l ON l.user_id=u.id WHERE u.id=41")) {
                assertThat(row.next()).isTrue();
                assertThat(row.getLong(1)).isEqualTo(41);
                assertThat(row.getString(2)).isEqualTo("legacy@example.test");
                assertThat(row.getString(3)).isEqualTo("Legacy");
                assertThat(row.getString(4)).isNull();
                assertThat(row.getObject(5, java.time.OffsetDateTime.class)).isEqualTo(originalCreatedAt);
                assertThat(row.getObject(6, java.time.OffsetDateTime.class)).isEqualTo(originalUpdatedAt);
                assertThat(row.getLong(7)).isEqualTo(61);
                assertThat(row.getLong(8)).isEqualTo(51);
                assertThat(row.getInt(9)).isEqualTo(25);
                assertThat(row.getInt(10)).isEqualTo(100);
                assertThat(row.getString(11)).isEqualTo("LEYENDO");
                assertThat(row.next()).isFalse();
            }
            assertThat(flyway.migrate().migrationsExecuted).isZero();
            flyway.validate();
        } finally {
            dataSource.dispose();
        }
    }
}
