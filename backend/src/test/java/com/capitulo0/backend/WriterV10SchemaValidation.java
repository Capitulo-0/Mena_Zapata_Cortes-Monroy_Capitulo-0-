package com.capitulo0.backend;

import java.util.HashMap;
import javax.sql.DataSource;
import org.hibernate.boot.MetadataSources;
import org.hibernate.boot.registry.StandardServiceRegistryBuilder;
import org.hibernate.tool.schema.internal.ExceptionHandlerHaltImpl;
import org.hibernate.tool.schema.spi.*;

/** Calls only Hibernate's schema VALIDATOR. No SessionFactory, DDL generator or Spring. */
final class WriterV10SchemaValidation {
    private WriterV10SchemaValidation() {}

    static void validate(DataSource source, boolean includeWriter, String dialect) {
        var settings = new HashMap<String, Object>();
        settings.put("hibernate.connection.datasource", source);
        settings.put("hibernate.dialect", dialect);
        settings.put("hibernate.default_schema", "public");
        settings.put("hibernate.hbm2ddl.auto", "none");
        settings.put("hibernate.boot.allow_jdbc_metadata_access", true);
        var registry = new StandardServiceRegistryBuilder().applySettings(settings).build();
        try {
            var sources = new MetadataSources(registry)
                .addAnnotatedClass(com.capitulo0.backend.user.entity.User.class)
                .addAnnotatedClass(com.capitulo0.backend.catalog.book.entity.Book.class)
                .addAnnotatedClass(com.capitulo0.backend.library.entity.LibraryEntry.class)
                .addAnnotatedClass(com.capitulo0.backend.follow.entity.UserFollow.class)
                .addAnnotatedClass(com.capitulo0.backend.notification.entity.UserNotification.class);
            if (includeWriter) sources.addAnnotatedClass(com.capitulo0.backend.writer.WriterStoryEntity.class);
            var metadata = sources.buildMetadata();
            var tool = registry.getService(SchemaManagementTool.class);
            tool.getSchemaValidator(settings).doValidation(metadata,
                SchemaManagementToolCoordinator.buildExecutionOptions(settings, ExceptionHandlerHaltImpl.INSTANCE),
                ContributableMatcher.ALL);
        } finally {
            StandardServiceRegistryBuilder.destroy(registry);
        }
    }
}
