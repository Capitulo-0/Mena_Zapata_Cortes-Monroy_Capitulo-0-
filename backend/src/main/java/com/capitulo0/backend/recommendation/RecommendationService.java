package com.capitulo0.backend.recommendation;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.text.Normalizer;
import java.time.Clock;
import java.util.*;
import java.util.concurrent.Semaphore;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import com.capitulo0.backend.common.exception.ApiException;
import com.capitulo0.backend.integration.googlebooks.*;
import com.capitulo0.backend.library.dto.LibraryEntryResponse;
import com.capitulo0.backend.library.service.LibraryService;
import static com.capitulo0.backend.recommendation.Recommendations.*;

@Service
public class RecommendationService {
    private final LibraryService library;
    private final GoogleBooksService books;
    private final Provider gemini;
    private final Clock clock;
    private final LinkedHashMap<Long, State> sessions = new LinkedHashMap<>(16, .75f, true);
    private final Semaphore aiSlots = new Semaphore(4);
    private final ArrayDeque<Long> globalCalls = new ArrayDeque<>();
    private static final class State {
        String fingerprint;
        Result normal;
        Result ai;
        Input input;
        volatile long expires;
        long nextAiAttempt;
        final ArrayDeque<Long> calls = new ArrayDeque<>();
    }
    @Autowired public RecommendationService(LibraryService library, GoogleBooksService books,
            GeminiRecommendationClient gemini) { this(library, books, gemini, Clock.systemUTC()); }
    RecommendationService(LibraryService library, GoogleBooksService books, Provider gemini, Clock clock) {
        this.library = library; this.books = books; this.gemini = gemini; this.clock = clock;
    }
    private synchronized State state(Long uid) {
        State existing = sessions.get(uid);
        if (existing != null) return existing;
        // Keep rate counters for at least one minute even when candidate sets expire.
        if (sessions.size() >= 128) {
            var iterator = sessions.entrySet().iterator();
            while (iterator.hasNext()) {
                var entry = iterator.next();
                if (entry.getValue().expires + 60000 < clock.millis()) { iterator.remove(); break; }
            }
            if (sessions.size() >= 128) throw new ApiException(
                org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE, "Recomendaciones ocupadas. Reintenta más tarde.");
        }
        State created = new State(); created.expires = clock.millis() + 60000;
        sessions.put(uid, created); return created;
    }
    public Result recommendations(Long uid) {
        var entries = List.copyOf(library.list(uid));
        String fingerprint = fingerprint(entries);
        State state = state(uid);
        synchronized (state) {
            if (state.normal != null && fingerprint.equals(state.fingerprint) && clock.millis() < state.expires)
                return state.normal;
            var profile = profile(entries);
            var pool = new ArrayList<GoogleBook>();
            int failures = 0;
            List<String[]> queries = queries(profile);
            long started = System.nanoTime();
            int attempted = 0;
            RuntimeException failure = null;
            for (var query : queries) {
                if (attempted >= 2 && System.nanoTime() - started > 3_000_000_000L) break;
                attempted++;
                try { pool.addAll(books.search(query[0], query[1], 0, 20, "").items()); }
                catch (RuntimeException e) { failures++; failure = e; }
            }
            if (failures == attempted) throw failure;
            boolean personalized = !profile.authors.isEmpty() || !profile.genres.isEmpty();
            var scored = new ArrayList<Scored>();

            for (var book : pool) {
                if (book == null || book.volumeId() == null || !book.volumeId().matches("[A-Za-z0-9_-]{1,128}")
                        || clean(book.title()).isEmpty()) continue;
                var ids = identities(book);
                if (!Collections.disjoint(ids, profile.owned)) continue;
                var reasons = new ArrayList<String>();
                int score = match(safe(book.authors()), profile.authors, "AUTHOR:", reasons)
                    + match(safe(book.categories()), profile.genres, "GENRE:", reasons);
                if (personalized && reasons.isEmpty()) continue;
                if (reasons.isEmpty()) reasons.add("EXPLORE");

                scored.add(new Scored(new Item(book, reason(reasons.getFirst()), List.copyOf(reasons)), score));
            }
            scored.sort(Comparator.comparingInt(Scored::score).reversed()
                .thenComparing(Comparator.comparingInt((Scored s) -> metadataQuality(s.item().book())).reversed()));
            var titles = new HashSet<String>();
            var identities = new HashSet<String>();
            scored.removeIf(candidate -> {
                var book = candidate.item().book();
                var keys = identities(book);
                if (titles.contains(workTitle(book.title())) || !Collections.disjoint(keys, identities)) return true;
                titles.add(workTitle(book.title())); identities.addAll(keys); return false;
            });
            var items = diversify(scored);
            state.input = new Input(profile.preferences, items.stream().map(item -> new Candidate(
                item.book().volumeId(), clean(item.book().title()), bounded(item.book().authors()),
                bounded(item.book().categories()), item.reasonCodes())).toList());
            String notice = personalized ? "Basadas en autores y categorías reales de tu Biblioteca."
                : entries.isEmpty() ? "Exploración general: añade lecturas para personalizar."
                : "Exploración general: faltan autores o categorías utilizables en tu Biblioteca.";
            if (personalized && !items.isEmpty() && items.stream().map(i -> authorKey(i.book())).distinct().count() == 1)
                notice = "Sugerencias limitadas a un autor con los metadatos disponibles.";
            if (failures > 0) notice += " Parte de Google Books no respondió; puedes actualizar.";
            state.normal = new Result(UUID.randomUUID().toString(), personalized, items, "NORMAL", notice, personalized && !items.isEmpty() && gemini.available());
            state.ai = null; state.fingerprint = fingerprint; state.expires = clock.millis() + 60000;
            return state.normal;
        }
    }
    public Result enrich(Long uid, String candidateSetId) {
        State state = state(uid);
        String fingerprint = fingerprint(List.copyOf(library.list(uid)));
        synchronized (state) {
            if (state.normal == null || !Objects.equals(state.normal.candidateSetId(), candidateSetId)
                    || !Objects.equals(state.fingerprint, fingerprint) || clock.millis() >= state.expires) {
                // No provider call for stale, foreign, expired or fabricated candidate sets.
                throw ApiException.conflict("Actualiza las recomendaciones antes de solicitar Gemini.");
            }
            if (state.ai != null) return state.ai;
            if (!state.normal.personalized() || state.normal.items().isEmpty()) return fallback(state, "NO_PREFERENCES");
            if (!gemini.configured()) return fallback(state, "NOT_CONFIGURED");
            if (!gemini.available()) return fallback(state, "NOT_AVAILABLE");
            long now = clock.millis();
            if (now < state.nextAiAttempt) return fallback(state, "BUSY");
            state.calls.removeIf(t -> now - t >= 60000);
            if (state.calls.size() >= 3 || !reserveGlobal(now)) return fallback(state, "QUOTA");
            if (!aiSlots.tryAcquire()) return fallback(state, "BUSY");
            state.calls.add(now);
            state.nextAiAttempt = now + 10000;
            try {
                var selections = gemini.select(state.input);
                if (selections == null || selections.isEmpty() || selections.size() > 6) return fallback(state, "INVALID");
                var candidates = new HashMap<String, Item>();
                state.normal.items().forEach(item -> candidates.put(item.book().volumeId(), item));
                var selected = new ArrayList<Item>();
                var used = new HashSet<String>();
                var selectedTitles = new HashSet<String>();
                for (var selection : selections) {
                    if (selection == null) return fallback(state, "INVALID");
                    var item = candidates.get(selection.id());
                    if (item == null || !used.add(selection.id()) || !selectedTitles.add(workTitle(item.book().title()))
                            || !item.reasonCodes().contains(selection.reasonCode()))
                        return fallback(state, "INVALID");
                    selected.add(new Item(item.book(), reason(selection.reasonCode()), item.reasonCodes()));
                }
                if (!state.fingerprint.equals(fingerprint(List.copyOf(library.list(uid)))))
                    throw ApiException.conflict("Tu Biblioteca cambió. Actualiza las recomendaciones.");
                state.ai = new Result(state.normal.candidateSetId(), true, List.copyOf(selected), "ENRICHED",
                    "Selección verificada entre tus recomendaciones.", true);
                return state.ai;
            } catch (Unavailable e) { return fallback(state, e.status);
            } finally { aiSlots.release(); }
        }
    }
    private synchronized boolean reserveGlobal(long now) {
        globalCalls.removeIf(t -> now - t >= 60000);
        if (globalCalls.size() >= 20) return false;
        globalCalls.add(now); return true;
    }
    private Result fallback(State state, String status) {
        return new Result(state.normal.candidateSetId(), state.normal.personalized(), state.normal.items(),
            status, state.normal.notice(), !Set.of("NOT_CONFIGURED", "NOT_AVAILABLE", "HTTP_ERROR").contains(status) && state.normal.geminiAvailable());
    }
    private static int metadataQuality(GoogleBook book) {
        int quality = book.coverUrl() != null && !book.coverUrl().isBlank() ? 8 : 0;
        if (!safe(book.authors()).isEmpty()) quality += 4;
        if (!safe(book.categories()).isEmpty()) quality += 2;
        if (book.description() != null && !book.description().isBlank()) quality++;
        if (book.publisher() != null && !book.publisher().isBlank()) quality++;
        if (book.publishedDate() != null && !book.publishedDate().isBlank()) quality++;
        if (book.pageCount() != null && book.pageCount() > 0) quality++;
        if (book.identifiers() != null && book.identifiers().values().stream().anyMatch(v -> isbn(v) != null)) quality += 2;
        return quality;
    }
    private record Scored(Item item, int score) {}
    private record Profile(Map<String, Integer> authors, Map<String, Integer> genres,
                           List<Preference> preferences, Set<String> owned) {}
    private static Profile profile(List<LibraryEntryResponse> entries) {
        var authors = new LinkedHashMap<String, Integer>();
        var genres = new LinkedHashMap<String, Integer>();
        var preferences = new ArrayList<Preference>();
        var owned = new HashSet<String>();
        for (var entry : entries) {
            if (entry.book() == null) continue;
            var b = entry.book();
            owned.addAll(identities(b.googleBooks() != null ? b.googleBooks()
                : new GoogleBook(b.googleVolumeId(), b.title(), null, author(b.author()), null, null,
                    null, null, List.of(), null, b.isbn() == null ? Map.of() : Map.of("isbn", b.isbn()), null, null)));
            if (b.googleVolumeId() != null) owned.add("id:" + b.googleVolumeId());
            String isbn = isbn(b.isbn()); if (isbn != null) owned.add("isbn:" + isbn);
            for (String a : author(b.author())) owned.add("work:" + workTitle(b.title()) + "|" + norm(a));
        }
        entries.stream().filter(e -> e.book() != null)
            .sorted(Comparator.comparingInt((LibraryEntryResponse e) -> weight(e)).reversed()
                .thenComparing(e -> e.updatedAt() == null ? java.time.Instant.EPOCH : e.updatedAt(), Comparator.reverseOrder()))
            .limit(24).forEach(entry -> {
                var b = entry.book();
                var a = b.googleBooks() == null ? author(b.author()) : bounded(b.googleBooks().authors());
                if (a.isEmpty()) a = author(b.author());
                var g = b.googleBooks() == null ? List.<String>of() : bounded(b.googleBooks().categories());
                for (var value : a) authors.merge(value, weight(entry), Integer::sum);
                for (var value : g) genres.merge(value, weight(entry), Integer::sum);
                preferences.add(new Preference(clean(b.title()), a, g, entry.status() == null ? "POR_LEER" : entry.status().name()));
            });
        return new Profile(authors, genres, List.copyOf(preferences), owned);
    }
    private static int weight(LibraryEntryResponse e) {
        return e.status() == null ? 1 : switch(e.status()) { case LEIDO -> 4; case LEYENDO -> 2; case POR_LEER -> 1; };
    }
    private static int match(List<String> values, Map<String, Integer> preferences, String prefix, List<String> reasons) {
        int score = 0;
        for (var preference : preferences.entrySet())
            if (values.stream().anyMatch(value -> norm(value).equals(norm(preference.getKey())))) {
                if (reasons.size() < 6) reasons.add(prefix + preference.getKey());
                score += preference.getValue();
            }
        return score;
    }

    private static List<String> strongest(Map<String,Integer> values) {
        return values.entrySet().stream().sorted(Map.Entry.<String,Integer>comparingByValue().reversed())
            .map(Map.Entry::getKey).toList();
    }
    private static List<String[]> queries(Profile profile) {
        var queries = new ArrayList<String[]>();
        var authors = strongest(profile.authors);
        var genres = strongest(profile.genres);
        if (!authors.isEmpty()) queries.add(new String[]{quoted(authors.getFirst()), "author"});
        if (!genres.isEmpty()) queries.add(new String[]{"subject:" + quoted(genres.getFirst()), "all"});
        if (authors.size() > 1) queries.add(new String[]{quoted(authors.get(1)), "author"});
        else if (genres.size() > 1) queries.add(new String[]{"subject:" + quoted(genres.get(1)), "all"});
        else if (genres.isEmpty() && authors.size() > 2) queries.add(new String[]{quoted(authors.get(2)), "author"});
        if (queries.isEmpty()) queries.add(new String[]{"subject:fiction", "all"});
        // With authors only, use up to three independent verified preferences.
        if (genres.isEmpty() && authors.size() > 2 && queries.size() < 3)
            queries.add(new String[]{quoted(authors.get(2)), "author"});
        return queries;
    }
    private static String authorKey(GoogleBook book) {
        return safe(book.authors()).stream().map(RecommendationService::norm).filter(v -> !v.isEmpty())
            .sorted().findFirst().orElse("unknown:" + book.volumeId());
    }
    // Only explicit series/part metadata; never guess a saga from a shared title word.
    private static String seriesKey(GoogleBook book) {
        String text = norm(book.title() + " " + Objects.toString(book.subtitle(), ""));
        var series = java.util.regex.Pattern.compile("(?:saga|serie|series) (.+?)(?: (?:libro|book|tomo|volumen|volume|parte) [0-9]+|$)")
            .matcher(text);
        if (series.find() && series.group(1).length() >= 5)
            return authorKey(book) + "|" + series.group(1);
        var numbered = java.util.regex.Pattern.compile("^(.{8,}?) (?:libro|book|tomo|volumen|volume|parte) [0-9]+(?: |$)")
            .matcher(text);
        return numbered.find() ? authorKey(book) + "|" + numbered.group(1) : "";
    }
    private static List<Item> diversify(List<Scored> ranked) {
        var selected = new ArrayList<Item>();
        var authors = new HashMap<String,Integer>();
        var series = new HashSet<String>();
        var ids = new HashSet<String>();
        for (int perAuthor = 1; perAuthor <= 2; perAuthor++) {
            for (var scored : ranked) {
                var item = scored.item();
                String author = authorKey(item.book()), saga = seriesKey(item.book());
                if (selected.size() >= 16 || ids.contains(item.book().volumeId())
                        || authors.getOrDefault(author,0) >= perAuthor
                        || (!saga.isEmpty() && series.contains(saga))) continue;
                selected.add(item); ids.add(item.book().volumeId());
                authors.merge(author,1,Integer::sum); if (!saga.isEmpty()) series.add(saga);
            }
        }
        return List.copyOf(selected);
    }
    private static String workTitle(String title) {
        String value = Objects.toString(title, "");
        // Strip named editorial/format suffixes only; retain subtitles and numbered parts otherwise.
        for (int pass = 0; pass < 4; pass++) {
            String previous = value;
        value = value.replaceAll("(?iu)\\s*[\\(\\[]\\s*(?:edici[oó]n|edicion|edition|illustrated|ilustrad[oa]|spanish edition|english edition|tapa blanda|tapa dura|ebook|e-book)\\b[^\\)\\]]*[\\)\\]]\\s*$", "");
        value = value.replaceAll("(?iu)\\s*[:–—-]\\s*(?:edici[oó]n|edicion|edition|illustrated edition|edici[oó]n ilustrada|una novela|a novel)\\b.*$", "");
            if (value.equals(previous)) break;
        }
        return norm(value);
    }

    private static List<String> author(String value) {
        String clean = clean(value);
        if (clean.isEmpty() || Set.of("autor desconocido", "desconocido", "sin autor", "unknown", "autor no disponible")
                .contains(norm(clean))) return List.of();
        return List.of(clean);
    }
    private static List<String> safe(List<String> values) { return values == null ? List.of() : values; }
    private static List<String> bounded(List<String> values) {
        return safe(values).stream().map(RecommendationService::clean).filter(v -> !v.isEmpty()).distinct().limit(3).toList();
    }
    private static String quoted(String text) { return "\"" + text.replace("\"", "").replace("\\", "") + "\""; }
    private static String clean(String value) {
        if (value == null) return "";
        String cleaned = value.replaceAll("[\\p{Cntrl}]", " ").strip();
        return cleaned.substring(0, Math.min(cleaned.length(), 120));
    }
    private static String norm(String value) {
        return Normalizer.normalize(value == null ? "" : value, Normalizer.Form.NFD)
            .replaceAll("\\p{M}", "").toLowerCase(Locale.ROOT).replaceAll("[^\\p{L}\\p{N}]+", " ").strip();
    }
    private static Set<String> identities(GoogleBook b) {
        var ids = new HashSet<String>();
        if (b.volumeId() != null && !b.volumeId().isBlank()) ids.add("id:" + b.volumeId());
        if (b.identifiers() != null) for (var value : b.identifiers().values()) {
            String isbn = isbn(value); if (isbn != null) ids.add("isbn:" + isbn);
        }
        if (!norm(b.title()).isEmpty()) for (var a : safe(b.authors()))
            if (!norm(a).isEmpty()) ids.add("work:" + workTitle(b.title()) + "|" + norm(a));
        return ids;
    }
    // Reject malformed ISBNs; canonicalize valid ISBN-10 to ISBN-13 for identity matching.
    static String isbn(String value) {
        if (value == null) return null;
        String s = value.replaceAll("[\\s-]", "").toUpperCase(Locale.ROOT);
        if (s.matches("[0-9]{9}[0-9X]")) {
            int sum = 0; for (int i=0;i<10;i++) sum += (10-i)*(s.charAt(i)=='X'?10:s.charAt(i)-'0');
            if (sum%11 != 0) return null;
            s = "978" + s.substring(0,9);
            int check = 0; for (int i=0;i<12;i++) check += (s.charAt(i)-'0')*(i%2==0?1:3);
            return s + ((10-check%10)%10);
        }
        if (!s.matches("[0-9]{13}")) return null;
        int sum=0; for(int i=0;i<13;i++) sum+=(s.charAt(i)-'0')*(i%2==0?1:3);
        return sum%10==0?s:null;
    }
    private static String fingerprint(List<LibraryEntryResponse> entries) {
        try {
            var json = tools.jackson.databind.json.JsonMapper.builder().build();
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                .digest(json.writeValueAsString(entries).getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) { throw new IllegalStateException("Cannot identify library revision"); }
    }
}
