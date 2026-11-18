package com.capitulo0.backend.recommendation;

import com.capitulo0.backend.integration.googlebooks.*;
import com.capitulo0.backend.catalog.book.dto.BookResponse;
import com.capitulo0.backend.library.dto.LibraryEntryResponse;
import com.capitulo0.backend.library.entity.ReadingStatus;
import com.capitulo0.backend.library.service.LibraryService;
import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.common.exception.ApiException;
import org.junit.jupiter.api.*;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;
import static com.capitulo0.backend.recommendation.Recommendations.*;

class RecommendationTests {
    LibraryService library = mock(LibraryService.class);
    GoogleBooksService books = mock(GoogleBooksService.class);
    Provider provider = mock(Provider.class);
    static class TestClock extends Clock {
        long now = System.currentTimeMillis();
        @Override public ZoneId getZone() { return ZoneOffset.UTC; }
        @Override public Clock withZone(ZoneId zone) { return this; }
        @Override public Instant instant() { return Instant.ofEpochMilli(now); }
        @Override public long millis() { return now; }
    }
    TestClock clock = new TestClock();
    RecommendationService service = new RecommendationService(library, books, provider, clock);
    GoogleBook book(String id, String title, String author, String genre) {
        return new GoogleBook(id, title, null, author == null ? List.of() : List.of(author), null,
            null, null, null, genre == null ? List.of() : List.of(genre), "es", Map.of(), null, null);
    }
    LibraryEntryResponse entry(long user, GoogleBook b, ReadingStatus status) {
        return new LibraryEntryResponse(1L,user,new BookResponse(1L,b.title(),
            b.authors().isEmpty()?null:b.authors().getFirst(),null,null,null,null,null,null,null,null,
            b.volumeId(),b),status,null,0,null,null,null,null,null);
    }
    GoogleBooksService.Page page(GoogleBook... b) { return new GoogleBooksService.Page(List.of(b),b.length,0,20,null); }
    void fixture() {
        when(library.list(1L)).thenReturn(List.of(entry(1,book("saved","Saved","Autora","Fantasía"),ReadingStatus.LEIDO)));
        when(books.search(anyString(),anyString(),eq(0),eq(20),eq("es"))).thenReturn(page(
            book("saved","Saved","Autora","Fantasía"),book("candidate","Other","Autora","Fantasía")));
        when(provider.configured()).thenReturn(true);
        when(provider.available()).thenReturn(true);
        when(provider.select(any())).thenReturn(List.of(new Selection("candidate","AUTHOR:Autora")));
    }
    @Test void readAuthorsAndGenresDriveTwoQueriesExcludingOwnedAndDuplicateWorks() {
        fixture();
        when(books.search(anyString(),anyString(),eq(0),eq(20),eq("es"))).thenReturn(page(
            book("saved","Saved","Autora","Fantasía"), book("anotherEdition","Saved","Autora","Fantasía"),
            book("candidate","Other","Autora","Fantasía"),book("duplicate","Other","Autora","Fantasía"),
            book("unrelated","No","Otra","Ciencia")));
        var result=service.recommendations(1L);
        assertThat(result.personalized()).isTrue();
        assertThat(result.items()).extracting(i->i.book().volumeId()).contains("candidate").doesNotContain("saved","anotherEdition","duplicate");
        assertThat(result.items().getFirst().reasonCodes()).contains("AUTHOR:Autora","GENRE:Fantasía");
        verify(books).search("\"Autora\"","author",0,20,"es");
        verify(books).search("subject:\"Fantasía\"","all",0,20,"es");
        service.recommendations(1L);
        verify(books,times(service.searchStats(1L).requests)).search(anyString(),anyString(),anyInt(),anyInt(),anyString());
    }
    @Test void readStateOutweighsPendingAndMissingFieldsDoNotInventPreferences() {
        when(library.list(1L)).thenReturn(List.of(
            entry(1,book("read","Read","Read author",null),ReadingStatus.LEIDO),
            entry(1,book("pending","Pending","Pending author",null),ReadingStatus.POR_LEER)));
        when(books.search(anyString(),anyString(),anyInt(),anyInt(),anyString())).thenReturn(page());
        service.recommendations(1L);
        verify(books).search("\"Read author\"","author",0,20,"es");
        when(library.list(2L)).thenReturn(List.of(entry(2,book("missing","Missing",null,null),ReadingStatus.LEIDO)));
        var result=service.recommendations(2L);
        assertThat(result.personalized()).isFalse();
        assertThat(result.notice()).contains("faltan autores");
        verify(books,atLeastOnce()).search("subject:fiction","all",0,20,"es");
    }
    @Test void emptyLibraryIsExplicitGeneralExploration() {
        when(library.list(1L)).thenReturn(List.of());
        when(books.search("subject:fiction","all",0,20,"es")).thenReturn(page(book("x","Explore",null,null)));
        var result=service.recommendations(1L);
        assertThat(result.personalized()).isFalse(); assertThat(result.notice()).contains("Exploración general");
        assertThat(result.items().getFirst().reasonCodes()).containsExactly("EXPLORE");
        assertThat(service.enrich(1L,result.candidateSetId()).aiStatus()).isEqualTo("NO_PREFERENCES");
        verify(provider,never()).select(any());
    }
    @Test void accountsHaveDifferentCandidatesAndCannotUseEachOthersSets() {
        fixture();
        when(library.list(2L)).thenReturn(List.of(entry(2,book("b","B","Otra","Historia"),ReadingStatus.LEYENDO)));
        when(books.search("\"Otra\"","author",0,20,"es")).thenReturn(page(book("history","Historia","Otra","Historia")));
        when(books.search("subject:\"Historia\"","all",0,20,"es")).thenReturn(page());
        var first=service.recommendations(1L); var second=service.recommendations(2L);
        assertThat(second.items()).extracting(i->i.book().volumeId()).contains("history").doesNotContain("b");
        assertThat(second.candidateSetId()).isNotEqualTo(first.candidateSetId());
        assertThatThrownBy(()->service.enrich(2L,first.candidateSetId())).isInstanceOf(ApiException.class);
        verify(provider,never()).select(any());
    }
    @Test void libraryChangesInvalidateCacheAndRejectStaleAi() {
        fixture(); var first=service.recommendations(1L);
        when(library.list(1L)).thenReturn(List.of());
        assertThatThrownBy(()->service.enrich(1L,first.candidateSetId())).isInstanceOf(ApiException.class);
        var refreshed=service.recommendations(1L);
        assertThat(refreshed.personalized()).isFalse();
        assertThat(refreshed.candidateSetId()).isNotEqualTo(first.candidateSetId());
        verify(provider,never()).select(any());
    }
    @Test void validGeminiCanOnlySelectVerifiedCandidateAndGroundedReason() {
        fixture(); var normal=service.recommendations(1L);
        var result=service.enrich(1L,normal.candidateSetId());
        assertThat(result.aiStatus()).isEqualTo("ENRICHED");
        assertThat(result.items().getFirst().book()).isEqualTo(normal.items().getFirst().book());
        assertThat(result.items().getFirst().reason()).contains("Autora");
        service.enrich(1L,normal.candidateSetId());
        verify(provider,times(1)).select(any());
        var capture=org.mockito.ArgumentCaptor.forClass(Input.class);
        verify(provider).select(capture.capture());
        assertThat(capture.getValue().preferences().getFirst().status()).isEqualTo("LEIDO");
        assertThat(capture.getValue().candidates()).extracting(Candidate::id).containsExactly("candidate");
    }
    @Test void inventedIdsReasonsAndDuplicatesAlwaysRetainNormalRecommendations() {
        for(var invalid:List.of(List.of(new Selection("invented","AUTHOR:Autora")),
                List.of(new Selection("candidate","Invented fact")),
                List.of(new Selection("candidate","AUTHOR:Autora"),new Selection("candidate","AUTHOR:Autora")))) {
            fixture(); var normal=service.recommendations(1L);
            clock.now += 11000;
            when(provider.select(any())).thenReturn(invalid);
            var result=service.enrich(1L,normal.candidateSetId());
            assertThat(result.aiStatus()).isEqualTo("INVALID"); assertThat(result.items()).isEqualTo(normal.items());
        }
    }
    @Test void absentKeyHttpQuotaAndTimeoutRetainNormalData() {
        fixture(); var normal=service.recommendations(1L);
        when(provider.configured()).thenReturn(false);
        assertThat(service.enrich(1L,normal.candidateSetId()).aiStatus()).isEqualTo("NOT_CONFIGURED");
        verify(provider,never()).select(any());
        when(provider.configured()).thenReturn(true);
        when(provider.available()).thenReturn(true);
        for(var status:List.of("HTTP_ERROR","QUOTA","TIMEOUT")) {
            doThrow(new Unavailable(status)).when(provider).select(any());
            var result=service.enrich(1L,normal.candidateSetId());
            assertThat(result.aiStatus()).isEqualTo(status); assertThat(result.items()).isEqualTo(normal.items());
            clock.now += 11000;
        }
        assertThat(service.enrich(1L,normal.candidateSetId()).aiStatus()).isEqualTo("QUOTA");
        verify(provider,times(3)).select(any());
    }
    @Test void duplicateConcurrentRequestsShareGoogleBooksWorkAndAiCall() throws Exception {
        fixture();
        try(var executor=Executors.newVirtualThreadPerTaskExecutor()) {
            var normal=executor.submit(()->service.recommendations(1L));
            var duplicate=executor.submit(()->service.recommendations(1L));
            assertThat(normal.get().candidateSetId()).isEqualTo(duplicate.get().candidateSetId());
            verify(books,times(service.searchStats(1L).requests)).search(anyString(),anyString(),anyInt(),anyInt(),anyString());
            String id=normal.get().candidateSetId();
            var a=executor.submit(()->service.enrich(1L,id));
            var b=executor.submit(()->service.enrich(1L,id));
            assertThat(a.get()).isEqualTo(b.get()); verify(provider,times(1)).select(any());
        }
    }
    @Test void libraryChangingDuringAiNeverPublishesOldSelection() {
        fixture(); var normal=service.recommendations(1L);
        when(provider.select(any())).thenAnswer(ignored->{
            when(library.list(1L)).thenReturn(List.of());
            return List.of(new Selection("candidate","AUTHOR:Autora"));
        });
        assertThatThrownBy(()->service.enrich(1L,normal.candidateSetId())).isInstanceOf(ApiException.class);
    }
    @Test void authenticatedControllerUsesServerIdentityNotClientUserId() {
        var current=mock(CurrentUserService.class);
        var user=mock(com.capitulo0.backend.user.entity.User.class); when(user.getId()).thenReturn(77L);
        when(current.require()).thenReturn(user);
        var recommendations=mock(RecommendationService.class);
        var controller=new RecommendationController(current,recommendations);
        controller.list(); controller.enrich(new RecommendationController.EnrichRequest("set"));
        verify(recommendations).recommendations(77L); verify(recommendations).enrich(77L,"set");
        when(current.require()).thenThrow(new org.springframework.security.authentication.AuthenticationCredentialsNotFoundException("required"));
        assertThatThrownBy(controller::list).isInstanceOf(org.springframework.security.core.AuthenticationException.class);
    }
    @Test void isbnCheckAndCanonicalizationRejectUnreliableMatches() {
        assertThat(RecommendationService.isbn("0-306-40615-2")).isEqualTo("9780306406157");
        assertThat(RecommendationService.isbn("9780306406157")).isEqualTo("9780306406157");
        assertThat(RecommendationService.isbn("9780000000001")).isNull();
        assertThat(RecommendationService.isbn("garbage")).isNull();
    }
    @Test void failedAiDuplicateUsesCooldownAndExpiredCandidateSetsCannotCallProvider() {
        fixture(); var normal=service.recommendations(1L);
        doThrow(new Unavailable("TIMEOUT")).when(provider).select(any());
        assertThat(service.enrich(1L,normal.candidateSetId()).aiStatus()).isEqualTo("TIMEOUT");
        assertThat(service.enrich(1L,normal.candidateSetId()).aiStatus()).isEqualTo("BUSY");
        verify(provider,times(1)).select(any());
        clock.now += 61000;
        assertThatThrownBy(()->service.enrich(1L,normal.candidateSetId())).isInstanceOf(ApiException.class);
        assertThat(service.recommendations(1L).candidateSetId()).isNotEqualTo(normal.candidateSetId());
    }
}
