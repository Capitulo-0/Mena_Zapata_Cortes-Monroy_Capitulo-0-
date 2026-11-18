package com.capitulo0.backend.recommendation;
import com.capitulo0.backend.integration.googlebooks.*;
import com.capitulo0.backend.common.exception.ApiException;
import org.junit.jupiter.api.Test;
import com.sun.net.httpserver.HttpServer;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.*;
import tools.jackson.databind.json.JsonMapper;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;
class RecommendationTransportBudgetTests {
 @Test void shortRecommendationDeadlineDoesNotBlockLaterCatalogRequestsAndIsCleared() throws Exception {
  var server=HttpServer.create(new InetSocketAddress("127.0.0.1",0),0);
  var threads=Executors.newCachedThreadPool();server.setExecutor(threads);
  server.createContext("/volumes",exchange->{
   try {
    if(exchange.getRequestURI().getRawQuery().contains("slow")) Thread.sleep(3000);
    byte[] bytes="{\"totalItems\":0}".getBytes(StandardCharsets.UTF_8);
    exchange.sendResponseHeaders(200,bytes.length);exchange.getResponseBody().write(bytes);
   } catch(InterruptedException e) {Thread.currentThread().interrupt();} catch(java.io.IOException ignored) {}
   finally {exchange.close();}
  });server.start();
  try {
   var client=new GoogleBooksClient("http://127.0.0.1:"+server.getAddress().getPort(),"fixture-key",6000);
   long started=System.nanoTime();
   assertThatThrownBy(()->GoogleBooksClient.withinRecommendationDeadline(System.nanoTime()+500_000_000L,()->client.search("slow",0,20,"es"))).isInstanceOf(ApiException.class);
   assertThat((System.nanoTime()-started)/1_000_000).isLessThan(2500);
   assertThat(client.search("fast",0,20,"es").path("totalItems").asInt(-1)).isZero();
  } finally {server.stop(0);threads.shutdownNow();}
 }
 @Test void countsProviderLanguageAndMalformedDropsWithoutDiscardingMissingCovers() {
  var client=mock(GoogleBooksClient.class);var json=JsonMapper.builder().build();
  when(client.search("q",0,20,"es")).thenReturn(json.readTree("""
   {"totalItems":3,"items":[{"id":"valid","volumeInfo":{"title":"Una obra real","language":"es"}},
   {"id":"english","volumeInfo":{"title":"The title","language":"en"}}, {"id":"malformed"}]}
   """));
  var page=new GoogleBooksService(client).search("q","all",0,20,"es");
  assertThat(page.receivedItems()).isEqualTo(3);assertThat(page.rejectedLanguage()).isEqualTo(1);
  assertThat(page.rejectedMetadata()).isEqualTo(1);assertThat(page.items()).hasSize(1);
  assertThat(page.items().getFirst().coverUrl()).isNull();
 }
}
