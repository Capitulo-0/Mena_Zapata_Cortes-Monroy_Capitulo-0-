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

class RecommendationDiversityTests {
    LibraryService library=mock(LibraryService.class);
    GoogleBooksService books=mock(GoogleBooksService.class);
    Provider provider=mock(Provider.class);
    RecommendationService service=new RecommendationService(library,books,provider,Clock.systemUTC());
    GoogleBook book(String id,String title,String subtitle,String author,String genre) {
        return new GoogleBook(id,title,subtitle,author==null?List.of():List.of(author),null,null,null,null,
            genre==null?List.of():List.of(genre),"es",Map.of(),null,null);
    }
    LibraryEntryResponse entry(GoogleBook b,ReadingStatus status) {
        return new LibraryEntryResponse(1L,1L,new BookResponse(1L,b.title(),
            b.authors().isEmpty()?null:b.authors().getFirst(),null,null,null,null,null,null,null,null,
            b.volumeId(),b),status,null,0,null,null,null,null,null);
    }
    GoogleBooksService.Page page(GoogleBook... values) {
        return new GoogleBooksService.Page(List.of(values),values.length,0,20,null);
    }
    @Test void severalPreferencesProvideDifferentAuthorsWithoutUnrelatedPadding() {
        when(library.list(1L)).thenReturn(List.of(
            entry(book("a","Leído",null,"Autora A","Fantasía"),ReadingStatus.LEIDO),
            entry(book("b","Leyendo",null,"Autora B","Historia"),ReadingStatus.LEYENDO),
            entry(book("c","Pendiente",null,"Autora C","Ciencia"),ReadingStatus.POR_LEER)));
        when(books.search(anyString(),anyString(),eq(0),eq(20),eq(""))).thenReturn(page(
            book("a1","Otra A uno",null,"Autora A","Fantasía"),
            book("a2","Otra A dos",null,"Autora A","Fantasía"),
            book("a3","Otra A tres",null,"Autora A","Fantasía"),
            book("b1","Otra B",null,"Autora B","Historia"),
            book("c1","Otra C",null,"Autora C","Ciencia"),
            book("no","Ajeno",null,"Desconocida","Deportes")));
        var result=service.recommendations(1L);
        assertThat(result.items().subList(0,3)).extracting(i->i.book().authors().getFirst())
            .containsExactly("Autora A","Autora B","Autora C");
        assertThat(result.items()).extracting(i->i.book().volumeId()).doesNotContain("a3","no");
        verify(books).search("\"Autora A\"","author",0,20,"");
        verify(books).search("\"Autora B\"","author",0,20,"");
        verify(books).search("subject:\"Fantasía\"","all",0,20,"");
        verify(books,times(3)).search(anyString(),anyString(),anyInt(),anyInt(),anyString());
    }
    @Test void obviousEditionsAndEditorialSubtitlesAreExcludedButDifferentNumberedPartsSurvive() {
        when(library.list(1L)).thenReturn(List.of(
            entry(book("saved","El jardín de la memoria",null,"María López","Ficción"),ReadingStatus.LEIDO),
            entry(book("part1","Viajes del norte: Tomo 1",null,"María López","Ficción"),ReadingStatus.LEIDO)));
        when(books.search(anyString(),anyString(),anyInt(),anyInt(),anyString())).thenReturn(page(
            book("edition","El jardín de la memoria (Edición ilustrada)",null,"MARIA LOPEZ","Ficción"),
            book("subtitle","El jardín de la memoria: Una novela","Una novela","María López","Ficción"),
            book("part2","Viajes del norte: Tomo 2",null,"María López","Ficción"),
            book("other","Libro diferente",null,"María López","Ficción")));
        var result=service.recommendations(1L);
        assertThat(result.items()).extracting(i->i.book().volumeId()).contains("part2","other")
            .doesNotContain("edition","subtitle");
        assertThat(result.notice()).contains("limitadas a un autor");
    }
    @Test void explicitSagaHasOneSlotAndOtherRelatedAuthorsArePreferred() {
        when(library.list(1L)).thenReturn(List.of(entry(book("saved","Base",null,"Autora","Ficción"),ReadingStatus.LEIDO)));
        when(books.search(anyString(),anyString(),anyInt(),anyInt(),anyString())).thenReturn(page(
            book("s1","Saga Horizonte, libro 1",null,"Autora","Ficción"),
            book("s2","Saga Horizonte, libro 2",null,"Autora","Ficción"),
            book("other","Otra historia",null,"Otra autora","Ficción")));
        assertThat(service.recommendations(1L).items()).extracting(i->i.book().volumeId()).containsExactly("s1","other");
    }
    @Test void missingOrUnavailableProviderNeverAdvertisesGeminiAndMakesNoGenerationCall() {
        when(library.list(1L)).thenReturn(List.of(entry(book("saved","Base",null,"Autora","Ficción"),ReadingStatus.LEIDO)));
        when(books.search(anyString(),anyString(),anyInt(),anyInt(),anyString())).thenReturn(page(
            book("new","Nueva",null,"Autora","Ficción")));
        when(provider.configured()).thenReturn(true); when(provider.available()).thenReturn(false);
        var result=service.recommendations(1L);
        assertThat(result.geminiAvailable()).isFalse();
        assertThat(service.enrich(1L,result.candidateSetId()).aiStatus()).isEqualTo("NOT_AVAILABLE");
        verify(provider,never()).select(any());
    }
    @Test void verifiedProviderAdvertisesAvailabilityWithoutAutomaticGeneration() {
        when(library.list(1L)).thenReturn(List.of(entry(book("saved","Base",null,"Autora","Ficción"),ReadingStatus.LEIDO)));
        when(books.search(anyString(),anyString(),anyInt(),anyInt(),anyString())).thenReturn(page(
            book("new","Nueva",null,"Autora","Ficción")));
        when(provider.available()).thenReturn(true);
        assertThat(service.recommendations(1L).geminiAvailable()).isTrue();
        verify(provider,never()).select(any());
    }
    @Test void incompleteMetadataUsesGeneralExplorationAndNoFabricatedGenre() {
        when(library.list(1L)).thenReturn(List.of(entry(book("saved","Sin datos",null,null,null),ReadingStatus.LEIDO)));
        when(books.search("subject:fiction","all",0,20,"")).thenReturn(page(book("new","Explorar",null,null,null)));
        var result=service.recommendations(1L);
        assertThat(result.personalized()).isFalse(); assertThat(result.geminiAvailable()).isFalse();
        assertThat(result.items().getFirst().reasonCodes()).containsExactly("EXPLORE");
        verifyNoInteractions(provider);
    }
}
