package com.capitulo0.backend.integration.googlebooks;
import com.capitulo0.backend.catalog.book.repository.BookRepository;
import com.capitulo0.backend.catalog.book.entity.Book;
import com.capitulo0.backend.catalog.book.dto.BookResponse;
import com.capitulo0.backend.catalog.book.mapper.BookMapper;
import com.capitulo0.backend.common.exception.ApiException;
import org.springframework.stereotype.Service;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import tools.jackson.databind.json.JsonMapper;
@Service
public class GoogleBooksImportService {
    private final GoogleBooksService google;
    private final BookRepository books;
    private final TransactionTemplate tx;
    private final JsonMapper json=JsonMapper.builder().build();
    public GoogleBooksImportService(GoogleBooksService google,BookRepository books,PlatformTransactionManager manager) {
        this.google=google; this.books=books; this.tx=new TransactionTemplate(manager);
    }
    public BookResponse resolve(String id) {
        GoogleBooksService.validateId(id);
        var existing=books.findByGoogleVolumeId(id);
        if(existing.isPresent()) return BookMapper.toResponse(existing.get());
        var metadata=google.detail(id);
        if(!id.equals(metadata.volumeId())) throw ApiException.invalid("Identificador externo inconsistente");
        try {
            return tx.execute(status -> {
                var current=books.findByGoogleVolumeId(id);
                if(current.isPresent()) return BookMapper.toResponse(current.get());
                var book=Book.create();
                book.setTitle(limit(metadata.title(),500)); book.setAuthor(limit(String.join(", ",metadata.authors()),300));
                book.setSynopsis(metadata.description()); book.setPublisher(limit(metadata.publisher(),300));
                book.setTotalPages(metadata.pageCount()); book.setCoverUrl(limit(metadata.coverUrl(),2048));
                book.setIsbn(limit(metadata.identifiers().getOrDefault("ISBN_13",metadata.identifiers().get("ISBN_10")),32));
                if(metadata.publishedDate()!=null && metadata.publishedDate().matches("[0-9]{4}.*")) {
                    int year=Integer.parseInt(metadata.publishedDate().substring(0,4)); if(year>0) book.setPublicationYear(year);
                }
                book.setGoogleVolumeId(id); book.setExternalMetadata(json.writeValueAsString(metadata));
                return BookMapper.toResponse(books.saveAndFlush(book));
            });
        } catch(DataIntegrityViolationException ex) {
            return books.findByGoogleVolumeId(id).map(BookMapper::toResponse).orElseThrow(() -> ex);
        }
    }
    private static String limit(String value,int max) { return value==null?null:value.substring(0,Math.min(max,value.length())); }
}
