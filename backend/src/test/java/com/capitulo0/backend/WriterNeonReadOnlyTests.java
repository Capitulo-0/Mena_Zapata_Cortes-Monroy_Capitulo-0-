package com.capitulo0.backend;

import java.sql.DriverManager;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;

/**
 * Explicit opt-in, independent of Spring, Hibernate and Flyway.
 * Credentials come only from this Maven/JVM process's environment.
 */
@EnabledIfSystemProperty(named = "writer.jdbc.check", matches = "true")
class WriterNeonReadOnlyTests {
    @Test
    void connectionAndWriterSchemaAreInspectedWithoutWrites() {
        Logger driverLogger = Logger.getLogger("org.postgresql");
        Level previousLevel = driverLogger.getLevel();
        driverLogger.setLevel(Level.OFF);
        // Never attach the original exception: PostgreSQL errors may contain secrets.
        try {
            var config = WriterJdbcReadOnlyProbe.configuration(System.getenv());
            DriverManager.setLogWriter(null);
            var report = WriterJdbcReadOnlyProbe.inspect(
                DriverManager.getConnection(config.url(), config.properties()));
            System.out.println("WRITER_JDBC: CONEXION_Y_AUTENTICACION=OK");
            System.out.println("WRITER_JDBC: TRANSACCION_SOLO_LECTURA=OK");
            System.out.println("WRITER_JDBC: SELECT_1=OK");
            System.out.println("WRITER_JDBC: FLYWAY_HISTORY=" + (report.historyExists() ? "EXISTE" : "NO_EXISTE"));
            System.out.println("WRITER_JDBC: V10=" + report.v10());
            System.out.println("WRITER_JDBC: PUBLIC_WRITER_STORIES=" + (report.storiesExist() ? "EXISTE" : "NO_EXISTE"));
            System.out.println("WRITER_JDBC: ROLLBACK_Y_CIERRE=OK");
            System.out.println("WRITER_JDBC: RAMA=CONFIRMAR_EN_CONSOLA_NEON_NO_INFERIBLE_POR_JDBC");
            System.out.println("WRITER_JDBC: MIGRACIONES_EJECUTADAS=NINGUNA");
        } catch (Exception error) {
            String safe = WriterJdbcReadOnlyProbe.safeFailure(error);
            System.out.println("WRITER_JDBC: " + safe);
            throw new AssertionError(safe);
        } finally {
            driverLogger.setLevel(previousLevel);
        }
    }
}
