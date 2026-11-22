package com.capitulo0.backend.integration.googlebooks;
import java.util.Locale;
import java.util.regex.Pattern;
/** Conservative recommendation eligibility; never translates or invents titles. */
public final class SpanishBooks {
 private SpanishBooks() {}
 public static boolean declaresSpanish(GoogleBook book) {
  if (book == null || book.language() == null) return false;
  String language = book.language().strip().toLowerCase(Locale.ROOT);
  return language.equals("es") || language.startsWith("es-");
 }
 public static boolean languageUnknown(GoogleBook book) {
  return book != null && (book.language() == null || book.language().isBlank()
      || "und".equalsIgnoreCase(book.language().strip()));
 }
 public static boolean accepts(GoogleBook book) {
  if (!declaresSpanish(book)) return false;
  String title=book.title()==null?"":book.title().strip().toLowerCase(Locale.ROOT);
  if(Pattern.compile("^(the |how to |a tale of |stories of )|english edition|in english").matcher(title).find()) return false;
  String text=title+" "+(book.description()==null?"":book.description().toLowerCase(Locale.ROOT));
  long en=Pattern.compile("\\b(the|and|with|from|that|this|her|his|was|were|your)\\b").matcher(text).results().count();
  long es=Pattern.compile("\\b(el|la|los|las|de|del|una|un|y|con|para|que|en|su|por)\\b").matcher(text).results().count();
  return en<5 || en<=es*2;
 }
}
