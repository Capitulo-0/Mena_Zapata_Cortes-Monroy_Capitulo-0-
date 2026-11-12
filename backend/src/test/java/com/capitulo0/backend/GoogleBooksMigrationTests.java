package com.capitulo0.backend;
import org.h2.jdbcx.JdbcConnectionPool;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import java.util.UUID;
import static org.assertj.core.api.Assertions.*;
class GoogleBooksMigrationTests {
    @Test void upgradesV3PreservingManualBookAndProgressAndAllowsNullReferences() throws Exception {
        var ds=JdbcConnectionPool.create("jdbc:h2:mem:books-"+UUID.randomUUID()+";MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE","sa","");
        try(var c=ds.getConnection();var s=c.createStatement()) {
            Flyway.configure().dataSource(ds).target("3").load().migrate();
            s.executeUpdate("INSERT INTO users(id,email,firebase_uid,created_at,updated_at) VALUES(41,'fixture@example.test','fixture',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)");
            s.executeUpdate("INSERT INTO books(id,title,created_at,updated_at) VALUES(51,'Existing',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP),(52,'Another',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)");
            s.executeUpdate("INSERT INTO library_entries(id,user_id,book_id,status,reading_format,current_page,total_pages,created_at,updated_at) VALUES(61,41,51,'LEYENDO','FISICO',73,300,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)");
            var flyway=Flyway.configure().dataSource(ds).load();
            assertThat(flyway.migrate().migrationsExecuted).isEqualTo(1);
            try(var rows=s.executeQuery("SELECT b.title,b.google_volume_id,b.external_metadata,l.current_page FROM books b JOIN library_entries l ON b.id=l.book_id")) {
                assertThat(rows.next()).isTrue();
                assertThat(rows.getString(1)).isEqualTo("Existing");
                assertThat(rows.getString(2)).isNull();assertThat(rows.getString(3)).isNull();
                assertThat(rows.getInt(4)).isEqualTo(73);
            }
            s.executeUpdate("UPDATE books SET google_volume_id='unique-fixture' WHERE id=51");
            assertThatThrownBy(() -> s.executeUpdate("UPDATE books SET google_volume_id='unique-fixture' WHERE id=52")).isInstanceOf(java.sql.SQLException.class);
            assertThat(flyway.migrate().migrationsExecuted).isZero();flyway.validate();
        } finally { ds.dispose(); }
    }
}
