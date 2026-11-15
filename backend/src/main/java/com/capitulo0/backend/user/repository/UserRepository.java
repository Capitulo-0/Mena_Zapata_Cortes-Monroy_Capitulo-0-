
package com.capitulo0.backend.user.repository;

import com.capitulo0.backend.user.entity.User;

import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserRepository extends JpaRepository<User, Long> {

    boolean existsByEmailIgnoreCase(String email);

    Optional<User> findByFirebaseUid(String firebaseUid);

    boolean existsByFirebaseUid(String firebaseUid);

    boolean existsByUsername(String username);

    Optional<User> findByUsername(String username);

    @Query("""
        SELECT u
        FROM User u
        WHERE LOWER(u.username) LIKE
            :pattern ESCAPE '!'
        OR LOWER(u.displayName) LIKE
            :pattern ESCAPE '!'
        ORDER BY
            CASE
                WHEN LOWER(u.username) = :exact THEN 0
                WHEN LOWER(u.username) LIKE
                    :prefix ESCAPE '!' THEN 1
                WHEN LOWER(u.displayName) = :exact THEN 2
                ELSE 3
            END,
            u.username ASC,
            u.id ASC
        """)
    List<User> searchProfiles(
        @Param("exact") String exact,
        @Param("pattern") String pattern,
        @Param("prefix") String prefix,
        Pageable pageable
    );
}
