package com.capitulo0.backend.integration.googlebooks;
import java.util.*;
import org.springframework.stereotype.Service;
import com.capitulo0.backend.common.exception.ApiException;
@Service
public class GoogleBooksService {
    public record Page(List<GoogleBook> items, int totalItems, int startIndex, int maxResults, Integer nextStartIndex) {}
    private final GoogleBooksClient client;
    public GoogleBooksService(GoogleBooksClient client) { this.client=client; }
    public Page search(String query,String mode,int start,int size,String language) {
        if(query==null || query.isBlank() || query.length()>200 || start<0 || start>10000 || size<1 || size>40)
            throw ApiException.invalid("Consulta o paginación no válida");
        if(language!=null && !language.isBlank() && !language.matches("[a-z]{2}"))
            throw ApiException.invalid("Idioma no válido");
        String prefix=switch(mode) { case "title" -> "intitle:"; case "author" -> "inauthor:"; case "isbn" -> "isbn:"; case "all" -> ""; default -> throw ApiException.invalid("Tipo de búsqueda no válido"); };
        var data=client.search(prefix+query.strip(),start,size,language);
        if(!data.isObject() || !data.path("totalItems").isNumber()
            || (data.path("totalItems").asInt(0)>0 && !data.path("items").isArray())) {
            throw new ApiException(org.springframework.http.HttpStatus.BAD_GATEWAY,"Respuesta externa incompleta");
        }
        var results=new ArrayList<GoogleBook>();
        for(var node:data.path("items")) {
            try { results.add(GoogleBooksClient.map(node)); } catch(ApiException ignored) { }
        }
        results.sort(Comparator.comparing(book -> !"es".equals(book.language())));
        int total=Math.max(0,data.path("totalItems").asInt(0));
        int received=data.path("items").isArray()?data.path("items").size():0;
        return new Page(List.copyOf(results),total,start,size,received==size && start+received<total?start+received:null);
    }
    public GoogleBook detail(String id) { validateId(id); return GoogleBooksClient.map(client.volume(id)); }
    public static void validateId(String id) {
        if(id==null || !id.matches("[A-Za-z0-9_-]{1,128}")) throw ApiException.invalid("Identificador de volumen no válido");
    }
}
