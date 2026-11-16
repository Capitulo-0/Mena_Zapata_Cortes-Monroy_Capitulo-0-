package com.capitulo0.backend.recommendation;
import com.capitulo0.backend.integration.googlebooks.*;
import com.capitulo0.backend.catalog.book.dto.BookResponse;
import com.capitulo0.backend.library.dto.LibraryEntryResponse;
import com.capitulo0.backend.library.entity.ReadingStatus;
import com.capitulo0.backend.library.service.LibraryService;
import org.junit.jupiter.api.Test;
import java.time.Clock;
import java.util.*;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;
import static com.capitulo0.backend.recommendation.Recommendations.*;

class RecommendationUniqueTitleTests {
    LibraryService library=mock(LibraryService.class);
    GoogleBooksService books=mock(GoogleBooksService.class);
    Provider provider=mock(Provider.class);
    RecommendationService service=new RecommendationService(library,books,provider,Clock.systemUTC());
    GoogleBook book(String id,String title,String author,boolean rich) {
        return new GoogleBook(id,title,null,List.of(author),rich?"Descripción bibliográfica":null,
            rich?"Editorial":null,rich?"2020":null,rich?250:null,List.of("Fantasía"),"es",
            rich?Map.of("ISBN_13","9780306406157"):Map.of(),rich?"https://covers.example.test/real.jpg":null,null);
    }
    LibraryEntryResponse entry(String id,String title,String author,ReadingStatus status) {
        var b=book(id,title,author,false);
        return new LibraryEntryResponse(1L,1L,new BookResponse(1L,title,author,null,null,null,null,null,null,null,null,id,b),
            status,null,0,null,null,null,null,null);
    }
    GoogleBooksService.Page page(GoogleBook... b) { return new GoogleBooksService.Page(List.of(b),b.length,0,20,null); }
    void fixture() {
        when(library.list(1L)).thenReturn(List.of(
            entry("saved","Base A","Autora A",ReadingStatus.LEIDO),
            entry("savedB","Base B","Autora B",ReadingStatus.LEYENDO)));
        when(provider.configured()).thenReturn(true); when(provider.available()).thenReturn(true);
    }
    @Test void titleIsUniqueAcrossSearchesAndAuthorsAndRichEditionWins() {
        fixture();
        when(books.search("\"Autora A\"","author",0,20,"")).thenReturn(page(
            book("bare","Café de otoño!","Autora A",false),book("a2","Otra lectura","Autora A",false)));
        when(books.search("subject:\"Fantasía\"","all",0,20,"")).thenReturn(page(
            book("rich","CAFE DE OTOÑO (Edición ilustrada)","Autora A",true)));
        when(books.search("\"Autora B\"","author",0,20,"")).thenReturn(page(
            book("homonym","Café   de otoño","Autora B",false),book("b2","Lectura distinta","Autora B",false)));
        var result=service.recommendations(1L);
        assertThat(result.items()).extracting(i->i.book().volumeId()).containsExactly("rich","b2","a2");
        assertThat(result.items().getFirst().book().coverUrl()).isEqualTo("https://covers.example.test/real.jpg");
        assertThat(result.items().getFirst().book().title()).isEqualTo("CAFE DE OTOÑO (Edición ilustrada)");
        assertThat(result.items().getFirst().reasonCodes()).contains("AUTHOR:Autora A");
    }
    @Test void normalizedTitlesCollapseEvenWhenAuthorsAndIdsDiffer() {
        fixture();
        when(books.search(anyString(),anyString(),anyInt(),anyInt(),anyString())).thenReturn(page(
            book("one","El río azul","Autora A",false),
            book("two","EL RIO   AZUL: Una novela","Autora B",false),
            book("four","El río azul (Edición ilustrada) [Spanish Edition]","Autora A",false),
            book("three","El ri\u0301o azul!","Autora A",false)));
        assertThat(service.recommendations(1L).items()).hasSize(1);
    }
    @Test void savedIdentityIsExcludedBeforeSelectingBestEdition() {
        fixture();
        when(books.search(anyString(),anyString(),anyInt(),anyInt(),anyString())).thenReturn(page(
            book("saved","Distinto título externo","Autora A",true),
            book("edition","Base A (Spanish Edition)","Autora A",true),
            book("allowed","Una lectura nueva","Autora A",false)));
        assertThat(service.recommendations(1L).items()).extracting(i->i.book().volumeId()).containsExactly("allowed");
    }
    @Test void metadataQualityNeverAdmitsUnrelatedCandidates() {
        when(library.list(1L)).thenReturn(List.of(entry("saved","Base","Autora A",ReadingStatus.LEIDO)));
        var unrelated=new GoogleBook("unrelated","Mismo título",null,List.of("Otra"),"Descripción","Editorial","2024",500,
            List.of("Deportes"),"es",Map.of(),"https://covers.example.test/other.jpg",null);
        when(books.search(anyString(),anyString(),anyInt(),anyInt(),anyString())).thenReturn(page(
            book("valid","Mismo título","Autora A",false),unrelated));
        assertThat(service.recommendations(1L).items()).extracting(i->i.book().volumeId()).containsExactly("valid");
    }
    @Test void geminiReceivesOnlyUniqueRealTitlesAndCannotReintroduceDiscardedEditions() {
        fixture();
        when(books.search(anyString(),anyString(),anyInt(),anyInt(),anyString())).thenReturn(page(
            book("bare","Café","Autora A",false),book("rich","CAFE (Edition)","Autora A",true),
            book("other","Otra lectura","Autora B",false)));
        var normal=service.recommendations(1L);
        when(provider.select(any())).thenReturn(List.of(new Selection("bare","AUTHOR:Autora A")));
        var invalid=service.enrich(1L,normal.candidateSetId());
        assertThat(invalid.aiStatus()).isEqualTo("INVALID"); assertThat(invalid.items()).isEqualTo(normal.items());
        var input=org.mockito.ArgumentCaptor.forClass(Input.class);
        verify(provider).select(input.capture());
        assertThat(input.getValue().candidates()).extracting(Candidate::id).containsExactly("rich","other");
    }
    @Test void validGeminiSelectionKeepsOnlyVerifiedUniqueCandidates() {
        fixture();
        when(books.search(anyString(),anyString(),anyInt(),anyInt(),anyString())).thenReturn(page(
            book("bare","Café","Autora A",false),book("rich","CAFE (Edition)","Autora A",true),
            book("other","Otra lectura","Autora B",false)));
        var normal=service.recommendations(1L);
        when(provider.select(any())).thenReturn(List.of(
            new Selection("other","AUTHOR:Autora B"),new Selection("rich","AUTHOR:Autora A")));
        var result=service.enrich(1L,normal.candidateSetId());
        assertThat(result.aiStatus()).isEqualTo("ENRICHED");
        assertThat(result.items()).extracting(i->i.book().volumeId()).containsExactly("other","rich");
    }
}
