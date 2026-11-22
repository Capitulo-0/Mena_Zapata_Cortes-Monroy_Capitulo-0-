package com.capitulo0.backend.admin.repository;

import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Repository;

@Repository
public class AdminRoleRepository {

    private final EntityManager entityManager;

    public AdminRoleRepository(EntityManager entityManager) {
        this.entityManager = entityManager;
    }

    public boolean isAdmin(Long userId) {
        Number count = (Number) entityManager.createNativeQuery(
                """
                SELECT COUNT(*)
                FROM user_roles
                WHERE user_id = :userId
                  AND role = 'ADMIN'
                """
        )
                .setParameter("userId", userId)
                .getSingleResult();

        return count.longValue() > 0;
    }
}
