package com.capitulo0.backend.recommendation;
import com.capitulo0.backend.integration.googlebooks.*;
import com.capitulo0.backend.library.service.LibraryService;
import org.junit.jupiter.api.Test;
import java.time.Clock;
import java.util.*;
import tools.jackson.databind.json.JsonMapper;
import static org.mockito.Mockito.*;
import static org.assertj.core.api.Assertions.*;

class RecommendationSpanishCoverTests {
 private GoogleBook book(String id,String title,String language,String description) {
  return new GoogleBook(id,title,null,List.of("Autor"),description,null,null,null,List.of(),language,Map.of(),null,null);
 }
 @Test void SpanishQueryAndFinalFilterRejectOtherLanguagesAndMislabeledEnglish() {
  var library=mock(LibraryService.class); var google=mock(GoogleBooksService.class);
  var provider=mock(Recommendations.Provider.class);
  when(library.list(1L)).thenReturn(List.of());
  when(google.search(anyString(),anyString(),eq(0),eq(20),eq("es"))).thenReturn(
   new GoogleBooksService.Page(List.of(book("es","Don Quijote de la Mancha","es","Una novela del caballero."),
    book("en","The Secret Library","en",null), book("wrong","The Lost Book","es",null),
    book("missing","Sin idioma",null,null)),4,0,20,null));
  var result=new RecommendationService(library,google,provider,Clock.systemUTC()).recommendations(1L);
  assertThat(result.items()).extracting(i->i.book().volumeId()).containsExactly("es");
  assertThat(result.notice()).contains("español");
  verify(google).search("subject:fiction","all",0,20,"es");
  verify(provider,never()).select(any());
 }
 @Test void RejectsEnglishDescriptionEvenWithSpanishLanguageFlag() {
  assertThat(SpanishBooks.accepts(book("es","Una lectura","es",
   "The story and the characters with the world that was and the author"))).isFalse();
  assertThat(SpanishBooks.accepts(book("es","Un viaje","es","Una novela de los caminos y la memoria."))).isTrue();
 }
 @Test void CoverMappingNeverUsesAnotherVolumeAndAcceptsSmallThumbnail() {
  var json=JsonMapper.builder().build();
  var node=json.readTree("{\"id\":\"zyTCAlFPjgYC\",\"volumeInfo\":{\"title\":\"The Google Story\",\"imageLinks\":{"
   + "\"thumbnail\":\"https://books.google.com/books/content?id=another&img=1\","
   + "\"smallThumbnail\":\"http://books.google.com/books/content?id=zyTCAlFPjgYC&img=1\"}}}");
  assertThat(GoogleBooksClient.map(node).coverUrl()).isEqualTo("https://books.google.com/books/content?id=zyTCAlFPjgYC&img=1");
  assertThat(GoogleBooksClient.verifiedCoverUrl("https://books.google.com/books/content?id=other","zyTCAlFPjgYC")).isNull();
  assertThat(GoogleBooksClient.verifiedCoverUrl("https://books.google.com/books/content?id=one&id=other","one")).isNull();
  assertThat(GoogleBooksClient.verifiedCoverUrl("https://images.unsplash.com/photo-example","one")).isNull();
 }
}
