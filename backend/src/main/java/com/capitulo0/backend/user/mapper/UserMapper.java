package com.capitulo0.backend.user.mapper;
import com.capitulo0.backend.user.dto.UserResponse;
import com.capitulo0.backend.user.entity.User;
public final class UserMapper {
    private UserMapper() {}
    public static UserResponse toResponse(User user) {
        return new UserResponse(
            user.getId(),
            user.getEmail(),
            user.getDisplayName(),
            user.getUsername(),
            user.getBiography(),
            user.getAvatarUrl(),
            user.getAnnualReadingGoal(),
            user.getCreatedAt(),
            user.getUpdatedAt()
        );
    }
}