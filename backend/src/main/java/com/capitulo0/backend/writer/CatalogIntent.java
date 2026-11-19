package com.capitulo0.backend.writer;

import com.capitulo0.backend.recommendation.RecommendationService.Lookup;
import com.capitulo0.backend.recommendation.RecommendationService.LookupKind;
import java.text.Normalizer;
import java.util.List;
import java.util.Locale;
import java.util.regex.Pattern;

final class CatalogIntent {
    private static final int FLAGS = Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE;
    private static final Pattern SIMILAR = Pattern.compile(
        "\\b(?:similar(?:es)?|parecid[oa]s?|semejantes?|del estilo|otros autores|alternativas)\\b", FLAGS);
    private static final Pattern AUTHOR = Pattern.compile(
        "^(?:(?:mu[eé]strame|busca|dame|recomi[eé]ndame|quiero ver|quiero leer) )?(?:los )?(?:qu[eé] )?(?:libros|obras|novelas)(?: (?:del autor|de la autora|de|escrit[oa]s? por|publicados por|tiene|escribi[oó]|public[oó])) (.+)$", FLAGS);
    private static final Pattern SERIES = Pattern.compile(
        "^(?:(?:cu[aá]les son|mu[eé]strame|busca|dame|quiero ver) )?(?:los )?(?:(?:libros|obras|novelas) de )?(?:la )?(?:saga|serie|trilog[ií]a) (.+)$", FLAGS);
    private static final Pattern TITLE = Pattern.compile(
        "^(?:busca|buscar|encuentra|mu[eé]strame|busco) (?:el (?:libro|t[ií]tulo) )?(.+)$", FLAGS);
    private static final Pattern TOPIC = Pattern.compile(
        "^(?:libros?|obras|novelas?|historias|algo|ideas|romances?|ficci[oó]n|fantas[ií]a|misterio|suspenso|terror|cuentos|poes[ií]a|espa[nñ]ol|amor|aventuras?|historia|realismo|drama|thrillers?|ciencia|autores?|autoras?|autoayuda|cr[ií]tica)(?: |$)", FLAGS);
    private static final Pattern EXPLICIT_AUTHOR = Pattern.compile(
        " (?:del autor|de la autora|escrit[oa]s? por|publicados por|tiene|escribi[oó]|public[oó]) ", FLAGS);

    private CatalogIntent() {}

    static Lookup detect(String message, List<LiteraryChatService.Turn> history) {
        var direct = explicit(message);
        if (direct != null) return direct;
        var query = clean(message);
        if (!valid(query)) return null;
        for (int i = history.size() - 1; i >= 0; i--) {
            var turn = history.get(i);
            if (!"user".equals(turn.role())) continue;
            var previous = explicit(turn.text());
            if (previous != null && fold(previous.text()).equals(fold(query))) return previous;
            break;
        }
        return null;
    }

    static Lookup explicit(String message) {
        var text = clean(message);
        if (SIMILAR.matcher(text).find()) return null;
        var series = SERIES.matcher(text);
        if (series.matches()) return lookup(LookupKind.SERIES, series.group(1));
        var author = AUTHOR.matcher(text);
        if (author.matches()) {
            var name = clean(author.group(1));
            var words = name.split(" ");
            if ((EXPLICIT_AUTHOR.matcher(text).find()
                    || (words.length >= 2 && words.length <= 6 && !TOPIC.matcher(name).find()
                        && !name.matches("(?i).*(?: para | sobre | con | en español| sin | que ).*")))
                    && name.matches("[\\p{L}\\p{M} .'-]+"))
                return lookup(LookupKind.AUTHOR, name);
            return null;
        }
        var title = TITLE.matcher(text);
        if (title.matches()) {
            var name = clean(title.group(1));
            if (text.matches("(?i).+ el (?:libro|t[ií]tulo) .+") || !TOPIC.matcher(name).find())
                return lookup(LookupKind.TITLE, name);
        }
        return null;
    }

    static Lookup lookup(LookupKind kind, String text) {
        var name = clean(text);
        return valid(name) ? new Lookup(kind, name) : null;
    }

    private static boolean valid(String name) {
        return name.matches("[\\p{L}\\p{M}\\p{N} .,'-]{2,120}") && name.codePoints().anyMatch(Character::isLetter);
    }

    static String fold(String text) {
        return Normalizer.normalize(text, Normalizer.Form.NFD).replaceAll("\\p{M}", "").toLowerCase(Locale.ROOT);
    }

    private static String clean(String text) {
        if (text == null) return "";
        return Normalizer.normalize(text, Normalizer.Form.NFC).replace((char) 0x2019, (char) 39)
            .replaceAll("^\\s*[¿¡«\\\"]+|[?!.»\\\"]+\\s*$", "")
            .replaceAll("\\s+", " ").strip();
    }
}
