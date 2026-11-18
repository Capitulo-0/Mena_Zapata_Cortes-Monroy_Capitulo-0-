package com.capitulo0.backend;

import org.flywaydb.core.api.logging.Log;
import org.flywaydb.core.api.logging.LogCreator;

/** Prevents Flyway messages, SQL and connection details reaching console/reports. */
public final class WriterV10SilentLogCreator implements LogCreator {
    @Override public Log createLogger(Class<?> type) {
        return new Log() {
            @Override public void debug(String message) {}
            @Override public void info(String message) {}
            @Override public void warn(String message) {}
            @Override public void error(String message) {}
            @Override public void error(String message, Exception error) {}
            @Override public void notice(String message) {}
        };
    }
}
