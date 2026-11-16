package com.capitulo0.backend.recommendation;

import com.capitulo0.backend.auth.service.CurrentUserService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/me/recommendations")
public class RecommendationController {
    private final CurrentUserService current;
    private final RecommendationService recommendations;
    public RecommendationController(CurrentUserService current, RecommendationService recommendations) {
        this.current = current; this.recommendations = recommendations;
    }
    public record EnrichRequest(@NotBlank @Pattern(regexp="[a-fA-F0-9-]{36}") String candidateSetId) {}
    @GetMapping public Recommendations.Result list() { return recommendations.recommendations(current.require().getId()); }
    @PostMapping("/gemini") public Recommendations.Result enrich(@Valid @RequestBody EnrichRequest request) {
        return recommendations.enrich(current.require().getId(), request.candidateSetId());
    }
}
