package com.capitulo0.backend;

import java.sql.DriverManager;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;

/** Two explicit modes; the default suite cannot run either one. */
@EnabledIfSystemProperty(named = "writer.v10.mode", matches = "preflight|apply")
class WriterV10ControlledMigrationTests {
    @Test void runOnlyTheExplicitlySelectedMode() {
        silenceSensitiveLibraryLogs();
        String mode = System.getProperty("writer.v10.mode");
        try {
            var environment = System.getenv();
            if ("preflight".equals(mode)) {
                var target = WriterV10MigrationRunner.target(environment);
                var report = WriterV10MigrationRunner.preflight(target);
                System.out.println("WRITER_V10: PREFLIGHT_SOLO_LECTURA=OK");
                System.out.println("WRITER_V10: HOST_INDEPENDIENTE_COINCIDE=OK");
                System.out.println("WRITER_V10: RAMA_DECLARADA=perfil-v9-notifications");
                System.out.println("WRITER_V10: V1_A_V9_Y_CHECKSUMS=OK");
                System.out.println("WRITER_V10: UNICA_PENDIENTE=V10");
                System.out.println("WRITER_V10: ESQUEMA_REQUERIDO=OK");
                System.out.println("WRITER_V10: WRITER_STORIES=NO_EXISTE");
                System.out.println("WRITER_V10: HUELLA=" + report.token());
                System.out.println("WRITER_V10: APTO_PARA_SOLICITAR_AUTORIZACION=SI");
                System.out.println("WRITER_V10: MIGRACIONES_EJECUTADAS=NINGUNA");
            } else if ("apply".equals(mode)) {
                WriterV10MigrationRunner.apply(environment);
                System.out.println("WRITER_V10: APLICACION_Y_POST_VALIDACION=OK");
                System.out.println("WRITER_V10: MIGRACIONES_EJECUTADAS=1_VERSION_10");
            } else {
                throw new WriterV10MigrationRunner.GuardFailure("MODO_NO_PERMITIDO");
            }
        } catch (Exception | LinkageError error) {
            String safe = error instanceof WriterV10MigrationRunner.GuardFailure
                ? error.getMessage() : error instanceof Exception exception ? WriterJdbcReadOnlyProbe.safeFailure(exception)
                    : "ERROR_CARGA_DEPENDENCIAS_SIN_DETALLES";
            System.out.println("WRITER_V10: RESULTADO=BLOQUEADO");
            System.out.println("WRITER_V10: CODIGO=" + safe);
            if ("apply".equals(mode)) {
                System.out.println("WRITER_V10: REVISAR_HISTORIAL_ANTES_DE_REINTENTAR=SI");
            }
            throw new AssertionError("Writer V10: " + safe);
        }
    }

    static void silenceSensitiveLibraryLogs() {
        DriverManager.setLogWriter(null);
        for (String name : new String[]{"org.postgresql", "org.flywaydb", "org.hibernate"}) {
            Logger.getLogger(name).setLevel(Level.OFF);
            var logger = org.slf4j.LoggerFactory.getLogger(name);
            if (logger instanceof ch.qos.logback.classic.Logger logback) {
                logback.setLevel(ch.qos.logback.classic.Level.OFF);
            }
        }
    }
}
