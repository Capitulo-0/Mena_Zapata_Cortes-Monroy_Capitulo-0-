package com.capitulo0.backend.recommendation;
import com.capitulo0.backend.integration.googlebooks.*;
import org.junit.jupiter.api.Test;
import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;
class RecommendationClosureTests {
 @Test void zeroOneAndSevenSavedBooksCanReachFiveUniqueSpanishWorksWithDiscovery() {
  for(int count:new int[]{0,1,7}) {
   var f=new RecommendationProgressiveTests();f.seven();
   if(count==0)when(f.library.list(1L)).thenReturn(List.of());
   if(count==1)when(f.library.list(1L)).thenReturn(List.of(f.entry(f.book("owned0","Autora A","Fantasía"))));
   var calls=new AtomicInteger();
   when(f.books.search(anyString(),anyString(),anyInt(),eq(20),eq("es"))).thenAnswer(invocation->{
    String query=invocation.getArgument(0);calls.incrementAndGet();
    if(!query.startsWith("subject:") || query.contains("\""))return f.page(f.book("personal1","Autora A","Fantasía"),f.book("personal2","Autora A","Fantasía"));
    String genre=query.substring(8);
    return f.page(f.book("g"+Math.abs(query.hashCode())+"a","Nueva A",genre),f.book("g"+Math.abs(query.hashCode())+"b","Nueva B",genre),f.book("g"+Math.abs(query.hashCode())+"c","Nueva C",genre));
   });
   var result=f.service.recommendations(1L);
   assertThat(result.items()).as("library size %s",count).hasSize(5);
   assertThat(result.items().stream().map(i->i.book().volumeId()).distinct().count()).isEqualTo(5);
   assertThat(result.items().stream().map(i->i.book().title()).distinct().count()).isEqualTo(5);
   assertThat(result.items()).allMatch(i->SpanishBooks.accepts(i.book()));
   assertThat(f.service.searchStats(1L).requests).isLessThanOrEqualTo(8);
   assertThat(f.service.recommendations(1L)).isSameAs(result);
  }
 }
 @Test void chatDiscoveryExcludesSavedAndDuplicateEditionsAndHonorsLength() {
  var f=new RecommendationProgressiveTests();
  var owned=f.book("owned","Autora A","Fantasía");
  when(f.library.list(1L)).thenReturn(List.of(f.entry(owned)));
  var first=new GoogleBook("real","La noche del misterio",null,List.of("Autora B"),null,null,null,130,List.of("Misterio"),"es",Map.of(),null,null);
  var duplicate=new GoogleBook("duplicate","La noche del misterio (Edición ilustrada)",null,List.of("Autora B"),null,null,null,130,List.of("Misterio"),"es",Map.of(),null,null);
  var tooLong=new GoogleBook("long","Un misterio muy largo",null,List.of("Autora C"),null,null,null,350,List.of("Misterio"),"es",Map.of(),null,null);
  when(f.books.search("misterio","all",0,24,"es")).thenReturn(f.page(owned,first,duplicate,tooLong));
  assertThat(f.service.discover(1L,new RecommendationService.Discovery(
      List.of("misterio"), List.of("misterio"), List.of(), List.of(), true, 200), false).books()).hasSize(1)
    .allMatch(book->Set.of("real","duplicate").contains(book.volumeId()));
 }
 @Test void semanticDiscoveryExpandsSearchAndExcludesSagaAcademicAndOtherLanguages() {
  var f = new RecommendationProgressiveTests();
  when(f.library.list(1L)).thenReturn(List.of());
  var saga = candidate("saga", "Culpa mía", "Juvenile Fiction / Romance", "Romance juvenil", "es");
  var criticism = candidate("academic", "Historia de la literatura", "Literary Criticism", "Estudio sobre romance", "es");
  var english = candidate("english", "Our Secret", "Juvenile Fiction / Romance", "Romance", "en");
  var fantasy = candidate("fantasy", "Corazón de dragón", "Fantasy / Romance", "Romance", "es");
  var admired = candidate("good", "Entre dos veranos", "Juvenile Fiction / Romance", "Romance juvenil y tensión romántica", "es");
  var second = candidate("also-good", "El último verano", "Fiction", "Una historia de romance juvenil", "es");
  when(f.books.search("romance juvenil", "all", 0, 24, "es"))
      .thenReturn(f.page(saga, criticism, english, fantasy));
  when(f.books.search("drama juvenil", "all", 0, 24, "es")).thenReturn(f.page(admired, second));
  var intent = new RecommendationService.Discovery(List.of("romance juvenil", "drama juvenil"),
      List.of("romance", "romance juvenil"), List.of("Culpables", "Culpa mía", "Culpa tuya", "Culpa nuestra"),
      List.of("fantasy", "fantasía"), true, 0);
  assertThat(f.service.discover(1L, intent, false).books()).extracting(GoogleBook::volumeId)
      .containsExactly("good", "also-good");
  verify(f.books, times(2)).search(anyString(), eq("all"), eq(0), eq(24), eq("es"));
 }

 @Test void genericDiscoveryFallsBackToNarrativeAndSkipsAcademicStudies() {
  var f = new RecommendationProgressiveTests();
  when(f.library.list(1L)).thenReturn(List.of());
  var narrative = candidate("read", "El último verano", "Fiction", "Una novela", "es");
  var academic = candidate("study", "Estudios literarios", "Literary Criticism", "Una introducción", "es");
  when(f.books.search(anyString(), eq("all"), eq(0), eq(24), eq("es"))).thenReturn(f.page(academic, narrative));
  var intent = new RecommendationService.Discovery(List.of(), List.of(), List.of(), List.of(), true, 0);
  assertThat(f.service.discover(1L, intent, false).books()).extracting(GoogleBook::volumeId).containsExactly("read");
  verify(f.books, times(3)).search(startsWith("subject:"), eq("all"), eq(0), eq(24), eq("es"));
 }

 private static GoogleBook candidate(String id, String title, String category, String description, String language) {
  return new GoogleBook(id,title,null,List.of("Autora " + id),description,null,null,140,List.of(category),language,Map.of(),null,null);
 }

 @Test void explicitAuthorPaginatesAndAllowsMissingMetadataWithoutLabelingItSpanish() {
  var f = new RecommendationProgressiveTests();
  var es = new GoogleBook("es","Culpa mía",null,List.of("Mercedes Ron"),null,null,null,null,List.of(),"es",Map.of(),null,null);
  var duplicate = new GoogleBook("dup","Culpa mía (Edición ilustrada)",null,List.of("Mercedes Ron"),null,null,null,null,List.of(),"es",Map.of(),null,null);
  var next = new GoogleBook("next","Culpa tuya",null,List.of("Ron, Mercedes"),null,null,null,null,List.of(),"es",Map.of(),null,null);
  var missing = new GoogleBook("missing","Culpa nuestra",null,List.of("Mércedes Ron"),null,null,null,null,List.of(),null,Map.of(),null,null);
  var english = new GoogleBook("english","My Fault",null,List.of("Mercedes Ron"),null,null,null,null,List.of(),"en",Map.of(),null,null);
  when(f.books.search("\"Mércedes Ron\"","author",0,24,"es"))
      .thenReturn(new GoogleBooksService.Page(List.of(es),4,0,24,24));
  when(f.books.search("\"Mércedes Ron\"","author",24,24,"es"))
      .thenReturn(f.page(duplicate,next));
  when(f.books.search("Mércedes Ron","author",0,24,null)).thenReturn(f.page(missing,english));
  var result = f.service.lookup(new RecommendationService.Lookup(RecommendationService.LookupKind.AUTHOR,"Mércedes Ron"));
  assertThat(result.books()).extracting(GoogleBook::volumeId).contains("next","missing").doesNotContain("english");
  assertThat(result.books()).hasSize(3);
  assertThat(result.books().getLast().language()).isNull();
  assertThat(result.books().getLast().coverUrl()).isNull();
  verifyNoInteractions(f.library);
 }

 @Test void noCatalogCandidatesRemainDifferentFromTechnicalError() {
  var f = new RecommendationProgressiveTests();
  var lookup = new RecommendationService.Lookup(RecommendationService.LookupKind.AUTHOR,"Autora real");
  when(f.books.search(anyString(),eq("author"),eq(0),eq(24),nullable(String.class)))
      .thenReturn(f.page());
  assertThat(f.service.lookup(lookup).received()).isZero();
  when(f.books.search(anyString(),eq("author"),eq(0),eq(24),nullable(String.class)))
      .thenThrow(new com.capitulo0.backend.common.exception.ApiException(
          org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE,"Catálogo temporalmente no disponible"));
  assertThatThrownBy(() -> f.service.lookup(lookup))
      .isInstanceOf(com.capitulo0.backend.common.exception.ApiException.class);
 }

 @Test void identityAliasesMergeTransitivelyAcrossIdsTitlesAndValidIsbns() {
  var f=new RecommendationProgressiveTests();f.seven();
  var a=new GoogleBook("a","La misma obra",null,List.of("Autora A"),null,null,null,null,List.of("Fantasía"),"es",Map.of("ISBN_10","0306406152"),null,null);
  var b=new GoogleBook("b","La misma obra (Edición ilustrada)",null,List.of("Autora A"),null,null,null,null,List.of("Fantasía"),"es",Map.of("ISBN_13","9780140328721"),null,null);
  var c=new GoogleBook("c","Título alternativo",null,List.of("Autora A"),null,null,null,null,List.of("Fantasía"),"es",Map.of("ISBN_13","9780140328721"),null,null);
  when(f.books.search(anyString(),anyString(),anyInt(),anyInt(),eq("es"))).thenReturn(f.page(a,b,c));
  assertThat(f.service.recommendations(1L).items()).hasSize(1);
 }
 @Test void discoveryCanRotateAfterCacheExpiryButNeverOnCachedRebuilds() {
  var f=new RecommendationProgressiveTests();when(f.library.list(1L)).thenReturn(List.of());
  var queries=new ArrayList<String>();
  when(f.books.search(anyString(),anyString(),anyInt(),anyInt(),eq("es"))).thenAnswer(i->{
   String q=i.getArgument(0);queries.add(q);
   return f.page(f.book("g"+Math.abs(q.hashCode())+"a","A",q),f.book("g"+Math.abs(q.hashCode())+"b","B",q));
  });
  var first=f.service.recommendations(1L);int calls=queries.size();
  assertThat(f.service.recommendations(1L)).isSameAs(first);assertThat(queries).hasSize(calls);
  f.clock.now=60001;var next=f.service.recommendations(1L);
  assertThat(next.candidateSetId()).isNotEqualTo(first.candidateSetId());assertThat(next.items()).hasSize(5);
  assertThat(queries.subList(calls,queries.size())).isNotEqualTo(queries.subList(0,calls));
 }
}
