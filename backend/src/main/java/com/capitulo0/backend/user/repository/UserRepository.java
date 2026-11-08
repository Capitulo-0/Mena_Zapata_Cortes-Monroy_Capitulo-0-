package com.capitulo0.backend.user.repository;
import com.capitulo0.backend.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
public interface UserRepository extends JpaRepository<User, Long> {
    boolean existsByEmailIgnoreCase(String email);
    Optional<User> findByFirebaseUid(String firebaseUid);
    boolean existsByFirebaseUid(String firebaseUid);
}
