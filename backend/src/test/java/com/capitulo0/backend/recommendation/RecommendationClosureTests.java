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
