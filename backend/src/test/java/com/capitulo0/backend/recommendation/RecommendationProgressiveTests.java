package com.capitulo0.backend.recommendation;
import com.capitulo0.backend.integration.googlebooks.*;
import com.capitulo0.backend.library.service.LibraryService;
import com.capitulo0.backend.library.dto.LibraryEntryResponse;
import com.capitulo0.backend.library.entity.ReadingStatus;
import com.capitulo0.backend.catalog.book.dto.BookResponse;
import com.capitulo0.backend.common.exception.ApiException;
import java.time.*;
import java.util.*;
import java.util.concurrent.atomic.*;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;
import static com.capitulo0.backend.recommendation.Recommendations.*;
class RecommendationProgressiveTests {
 final LibraryService library=mock(LibraryService.class);
 final GoogleBooksService books=mock(GoogleBooksService.class);
 final Provider gemini=mock(Provider.class);
 static class TestClock extends Clock { long now; public java.time.ZoneId getZone(){return ZoneOffset.UTC;} public Clock withZone(java.time.ZoneId z){return this;} public Instant instant(){return Instant.ofEpochMilli(now);} }
 final TestClock clock=new TestClock();
 final RecommendationService service=new RecommendationService(library,books,gemini,clock);
 GoogleBook book(String id,String title,String author,String genre,String lang) {
  return new GoogleBook(id,title,null,List.of(author),null,null,null,null,List.of(genre),lang,Map.of(),null,null);
 }
 GoogleBook book(String id,String author,String genre) { return book(id,"Obra de prueba "+id,author,genre,"es"); }
 LibraryEntryResponse entry(GoogleBook b) { return new LibraryEntryResponse(1L,1L,new BookResponse(1L,b.title(),b.authors().getFirst(),null,null,null,null,null,null,null,null,b.volumeId(),b),ReadingStatus.LEIDO,null,0,null,null,null,null,null); }
 GoogleBooksService.Page page(GoogleBook... b) {return new GoogleBooksService.Page(List.of(b),b.length,0,20,null);}
 void seven() {
  var entries=new ArrayList<LibraryEntryResponse>();
  for(int i=0;i<7;i++) entries.add(entry(book("owned"+i,"Autora "+(char)('A'+i),i%2==0?"Fantasía":"Historia")));
  when(library.list(1L)).thenReturn(entries);
  when(books.search(anyString(),anyString(),anyInt(),eq(20),eq("es"))).thenReturn(page());
 }
 @Test void sevenBooksFirstQueryTwoExpandsOtherGenreToFive() {
  seven();
  when(books.search("\"Autora A\"","author",0,20,"es")).thenReturn(page(book("a1","Autora A","Fantasía"),book("a2","Autora A","Fantasía")));
  when(books.search("subject:\"Historia\"","all",0,20,"es")).thenReturn(page(book("h1","Nueva D","Historia"),book("h2","Nueva E","Historia"),book("h3","Nueva F","Historia")));
  var result=service.recommendations(1L);
  assertThat(result.items()).hasSize(5);
  assertThat(result.items()).extracting(i->i.book().categories().getFirst()).contains("Historia","Fantasía");
  assertThat(service.searchStats(1L).initialEligible).isEqualTo(2);
  assertThat(service.searchStats(1L).initialReceived).isEqualTo(2);
  assertThat(service.searchStats(1L).stop).isEqualTo("TARGET_REACHED");
 }
 @Test void firstThreeCanRecoverFourWithoutFalsePaddingWithinEightRequests() {
  seven();
  when(books.search("\"Autora A\"","author",0,20,"es")).thenReturn(page(book("a1","Autora A","Fantasía"),book("a2","Autora A","Fantasía"),book("a3","Autora A","Fantasía")));
  when(books.search("subject:\"Historia\"","all",0,20,"es")).thenReturn(page(book("h1","Otra autora","Historia")));
  var result=service.recommendations(1L);
  assertThat(result.items()).hasSize(4);assertThat(service.searchStats(1L).requests).isLessThanOrEqualTo(8);
  assertThat(result.notice()).contains("4 obras verificables");
 }
 @Test void rejectsOwnedEditionsEnglishDuplicatesAndUnrelatedButKeepsBooksWithoutCovers() {
  seven();
  when(books.search("\"Autora A\"","author",0,20,"es")).thenReturn(page(
   book("owned0","Autora A","Fantasía"),book("english","The secret","Autora A","Fantasía","en"),
   book("a1","La puerta","Autora A","Fantasía","es"),book("dup","LA PUERTA (Edición ilustrada)","Autora A","Fantasía","es"),
   book("unrelated","Otra","Deportes"),book("a2","Autora A","Fantasía"),book("a3","Autora A","Fantasía"),book("a4","Autora A","Fantasía"),book("a5","Autora A","Fantasía")));
  var result=service.recommendations(1L);
  assertThat(result.items()).hasSize(5).allMatch(i->i.book().coverUrl()==null);
  assertThat(result.items()).extracting(i->i.book().volumeId()).doesNotContain("owned0","english","dup","unrelated");
  var stats=service.searchStats(1L);assertThat(stats.language).isPositive();assertThat(stats.owned).isPositive();assertThat(stats.duplicates).isPositive();assertThat(stats.unrelated).isPositive();
 }
 @Test void followsSecondPageWhenFirstPageFilteringLeavesTwo() {
  when(library.list(1L)).thenReturn(List.of(entry(book("owned","Autora A","Fantasía"))));
  when(books.search(anyString(),anyString(),anyInt(),eq(20),eq("es"))).thenReturn(page());
  when(books.search("\"Autora A\"","author",0,20,"es")).thenReturn(new GoogleBooksService.Page(List.of(book("a1","Autora A","Fantasía"),book("a2","Autora A","Fantasía")),60,0,20,20));
  when(books.search("\"Autora A\"","author",20,20,"es")).thenReturn(page(book("a3","Autora A","Fantasía"),book("a4","Autora A","Fantasía"),book("a5","Autora A","Fantasía")));
  assertThat(service.recommendations(1L).items()).hasSize(5);
  verify(books).search("\"Autora A\"","author",20,20,"es");
 }
 @Test void taxonomyCanMatchVerifiedSpanishBookWithEnglishCategoryLabels() {
  seven();when(books.search(anyString(),anyString(),anyInt(),eq(20),eq("es"))).thenReturn(page(
    book("a1","Otra A","Fiction / Fantasy / General"),book("a2","Otra B","Fiction / Fantasy / General"),book("a3","Otra C","Fiction / Fantasy / General"),book("a4","Otra D","Fiction / Fantasy / General"),book("a5","Otra E","Fiction / Fantasy / General")));
  assertThat(service.recommendations(1L).items()).hasSize(5).allMatch(i->i.reasonCodes().contains("GENRE:Fantasía"));
 }
 @Test void partialFailureStillReturnsFiveAndShortCacheRetriesOnlyAfterTenSeconds() {
  seven();when(books.search("\"Autora A\"","author",0,20,"es")).thenThrow(new RuntimeException("isolated fixture"));
  when(books.search("subject:\"Fantasía\"","all",0,20,"es")).thenReturn(page(book("a1","X1","Fantasía"),book("a2","X2","Fantasía"),book("a3","X3","Fantasía"),book("a4","X4","Fantasía"),book("a5","X5","Fantasía")));
  assertThat(service.recommendations(1L).items()).hasSize(5);assertThat(service.searchStats(1L).failures).isEqualTo(1);
 }
 @Test void lowCountCacheDoesNotFreezeTwoWhenMoreCandidatesBecomeEligible() {
  seven();var expanded=new AtomicBoolean(false);
  when(books.search(anyString(),anyString(),anyInt(),eq(20),eq("es"))).thenAnswer(i->expanded.get()?page(book("a1","A","Fantasía"),book("a2","B","Fantasía"),book("a3","C","Fantasía"),book("a4","D","Fantasía"),book("a5","E","Fantasía")):page(book("a1","A","Fantasía"),book("a2","B","Fantasía")));
  var first=service.recommendations(1L);assertThat(first.items()).hasSize(2);expanded.set(true);
  assertThat(service.recommendations(1L)).isSameAs(first);
  clock.now=10001;assertThat(service.recommendations(1L).items()).hasSize(5);
 }
 @Test void threeConsecutiveProviderFailuresStopWithoutUnboundedRetries() {
  seven();when(books.search(anyString(),anyString(),anyInt(),anyInt(),anyString())).thenThrow(new RuntimeException("isolated fixture"));
  assertThatThrownBy(()->service.recommendations(1L)).isInstanceOf(RuntimeException.class);
  assertThat(service.searchStats(1L).requests).isEqualTo(3);assertThat(service.searchStats(1L).stop).isEqualTo("PROVIDER_FAILURES");
 }
 @Test void geminiReordersButDoesNotShrinkFiveVerifiedCandidatesToTwo() {
  seven();when(books.search(anyString(),anyString(),anyInt(),eq(20),eq("es"))).thenReturn(page(book("a1","Autora A","Fantasía"),book("a2","Autora B","Fantasía"),book("a3","Autora C","Fantasía"),book("a4","Autora D","Fantasía"),book("a5","Autora E","Fantasía")));
  when(gemini.configured()).thenReturn(true);when(gemini.available()).thenReturn(true);
  var normal=service.recommendations(1L);
  when(gemini.select(any())).thenReturn(List.of(new Selection("a2","AUTHOR:Autora B"),new Selection("a1","AUTHOR:Autora A")));
  var enriched=service.enrich(1L,normal.candidateSetId());assertThat(enriched.items()).hasSize(5);
  assertThat(enriched.items().subList(0,2)).extracting(i->i.book().volumeId()).containsExactly("a2","a1");
 }
}
