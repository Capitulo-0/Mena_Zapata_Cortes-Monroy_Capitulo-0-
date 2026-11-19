package com.capitulo0.backend.recommendation;

import java.util.List;
import java.util.Map;
import com.capitulo0.backend.integration.googlebooks.GoogleBook;

/** Public bibliographic data only. No account identifiers are sent to the provider. */
public final class Recommendations {
    private Recommendations() {}
    public record Item(GoogleBook book, String reason, List<String> reasonCodes) {}
    public record Result(String candidateSetId, boolean personalized, List<Item> items,
                         String aiStatus, String notice, boolean geminiAvailable) {
        public Result(String candidateSetId, boolean personalized, List<Item> items, String aiStatus, String notice) {
            this(candidateSetId, personalized, items, aiStatus, notice, false);
        }
    }
    public record Preference(String title, List<String> authors, List<String> genres, String status) {}
    public record Candidate(String id, String title, List<String> authors, List<String> genres,
                            List<String> allowedReasons) {}
    public record Input(List<Preference> preferences, List<Candidate> candidates) {}
    public record Selection(String id, String reasonCode) {}
    public interface Provider {
        boolean configured();
        default boolean available() { return configured(); }
        List<Selection> select(Input input);
    }
    public static final class Unavailable extends RuntimeException {
        public final String status;
        public final Integer retryAfterSeconds;
        public Unavailable(String status) { this(status, null); }
        public Unavailable(String status, Integer retryAfterSeconds) {
            super("Gemini unavailable");
            this.status = status;
            this.retryAfterSeconds = retryAfterSeconds;
        }
    }
    public static String reason(String code) {
        if (code.equals("DISCOVER")) return "Descubrimiento variado en español · Fuente: Google Books";
        if (code.startsWith("AUTHOR:")) return "Comparte autor con tu Biblioteca: " + code.substring(7);
        if (code.startsWith("GENRE:")) return "Relacionado con una categoría de tu Biblioteca: " + code.substring(6);
        return "Exploración general · Fuente: Google Books";
    }
    public static final Map<String, Object> OUTPUT_SCHEMA = Map.of(
        "type", "object", "properties", Map.of("selections", Map.of(
            "type", "array", "minItems", 1, "maxItems", 6, "items", Map.of(
                "type", "object", "properties", Map.of(
                    "id", Map.of("type", "string"), "reasonCode", Map.of("type", "string")),
                "required", List.of("id", "reasonCode"), "additionalProperties", false))),
        "required", List.of("selections"), "additionalProperties", false);
}
