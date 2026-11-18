package com.capitulo0.backend.integration.googlebooks;
import java.net.URI;
import java.net.http.*;
import java.time.Duration;
import java.util.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.http.HttpStatus;
import org.springframework.web.util.UriComponentsBuilder;
import com.capitulo0.backend.common.exception.ApiException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;
@Component
public class GoogleBooksClient {
    private final String baseUrl, apiKey;
    private final Duration timeout;
    private final HttpClient http;
    private final JsonMapper json = JsonMapper.builder().build();
    public GoogleBooksClient(
        @Value("${google-books.base-url:https://www.googleapis.com/books/v1}") String baseUrl,
        @Value("${google-books.api-key:}") String apiKey,
        @Value("${google-books.timeout-ms:6000}") int timeoutMs) {
        this.baseUrl=baseUrl; this.apiKey=apiKey; this.timeout=Duration.ofMillis(Math.max(100, timeoutMs));
        this.http=HttpClient.newBuilder().connectTimeout(timeout).followRedirects(HttpClient.Redirect.NEVER).build();
    }
    public JsonNode search(String query, int start, int size, String language) {
        var uri=UriComponentsBuilder.fromUriString(baseUrl+"/volumes")
            .queryParam("q",query).queryParam("startIndex",start).queryParam("maxResults",size)
            .queryParam("printType","books");
        if (language!=null && !language.isBlank()) uri.queryParam("langRestrict",language);
        return get(uri);
    }
    public JsonNode volume(String id) {
        return get(UriComponentsBuilder.fromUriString(baseUrl+"/volumes/"+id));
    }
    private record Cached(JsonNode data,long expires) {}
    private final Map<String,Cached> cache=new LinkedHashMap<>();
    private long budgetWindow=0;
    private int budgetUsed=0;
    // Small bounded process-local cache and request budget; no bulk catalog persistence.
    private static final ThreadLocal<Long> recommendationDeadline = new ThreadLocal<>();
    public static <T> T withinRecommendationDeadline(long deadline, java.util.function.Supplier<T> action) {
        Long previous = recommendationDeadline.get();
        recommendationDeadline.set(deadline);
        try { return action.get(); }
        finally { if(previous==null) recommendationDeadline.remove(); else recommendationDeadline.set(previous); }
    }
    private JsonNode get(UriComponentsBuilder uri) {
        String cacheKey=uri.build().encode().toUriString();
        long now=System.currentTimeMillis();
        synchronized(cache) {
        var cached=cache.get(cacheKey);
        if(cached!=null && cached.expires()>now) return cached.data();
        cache.entrySet().removeIf(entry -> entry.getValue().expires()<=now);
        if(now-budgetWindow>=60_000) { budgetWindow=now; budgetUsed=0; }
        if(budgetUsed>=60) throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE,"Catálogo ocupado; reintenta más tarde");

        if(apiKey.isBlank()) throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE,"Catálogo externo no configurado");
        budgetUsed++;
        }
        Long deadline=recommendationDeadline.get();
        long remainingMs=deadline==null?timeout.toMillis():Math.min(1500, (deadline-System.nanoTime())/1_000_000);
        if(remainingMs<=0) throw unavailable();
        Duration requestTimeout=Duration.ofMillis(Math.min(timeout.toMillis(),remainingMs));
        uri.queryParam("key",apiKey);
        try {
            var request=HttpRequest.newBuilder(uri.build().encode().toUri()).timeout(requestTimeout)
                .header("Accept","application/json").GET().build();
            var response=http.send(request,HttpResponse.BodyHandlers.ofString());
            if(response.statusCode()==404) throw ApiException.notFound("Volumen");
            if(response.statusCode()==429 || response.statusCode()==403)
                throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE,"Catálogo externo temporalmente no disponible");
            if(response.statusCode()!=200) throw new ApiException(HttpStatus.BAD_GATEWAY,"Error del catálogo externo");
            if(response.body().length()>4_000_000) throw new ApiException(HttpStatus.BAD_GATEWAY,"Respuesta externa no válida");
            var result=json.readTree(response.body());
            if(!result.isObject() || result.has("error")) throw new ApiException(HttpStatus.BAD_GATEWAY,"Respuesta externa no válida");
            synchronized(cache) {
            if(cache.size()>=128) cache.remove(cache.keySet().iterator().next());
            cache.put(cacheKey,new Cached(result,System.currentTimeMillis()+60_000));
            }
            return result;
        } catch(ApiException ex) { throw ex; }
        catch(InterruptedException ex) { Thread.currentThread().interrupt(); throw unavailable(); }
        catch(Exception ex) { throw unavailable(); }
    }
    private ApiException unavailable() {
        return new ApiException(HttpStatus.SERVICE_UNAVAILABLE,"No se pudo consultar el catálogo externo");
    }
    public static GoogleBook map(JsonNode node) {
        var v=node.path("volumeInfo"); String id=text(node,"id"), title=text(v,"title");
        if(id==null || title==null) throw new ApiException(HttpStatus.BAD_GATEWAY,"Volumen incompleto");
        var identifiers=new LinkedHashMap<String,String>();
        for(var item:v.path("industryIdentifiers")) {
            var type=text(item,"type"); var value=text(item,"identifier");
            if(type!=null && value!=null) identifiers.put(type,value);
        }
        int pages=v.path("pageCount").asInt(0);
        return new GoogleBook(id,title,text(v,"subtitle"),strings(v.path("authors")),
            plain(text(v,"description")),text(v,"publisher"),text(v,"publishedDate"),pages>0?pages:null,
            strings(v.path("categories")),text(v,"language"),Map.copyOf(identifiers),
            cover(v.path("imageLinks"),id),safeUrl(text(v,"infoLink")));
    }
    private static String cover(JsonNode links,String id) {
        for(String size:List.of("medium","thumbnail","smallThumbnail")) {
            String cover=verifiedCoverUrl(text(links,size),id); if(cover!=null) return cover;
        }
        return null;
    }
    public static String verifiedCoverUrl(String value,String id) {
        String safe=safeUrl(value); if(safe==null) return null;
        try {
            var uri=URI.create(safe);
            if(!uri.getHost().equals("books.google.com") && !uri.getHost().endsWith(".googleusercontent.com")) return null;
            var query=UriComponentsBuilder.fromUri(uri).build().getQueryParams();
            var ids=query.get("id");
            if(id!=null && ((uri.getHost().equals("books.google.com") && ids==null) ||
                (ids!=null && (ids.size()!=1 || !java.net.URLDecoder.decode(ids.getFirst(),java.nio.charset.StandardCharsets.UTF_8).equals(id))))) return null;
            return safe;
        } catch(Exception invalid) { return null; }
    }
    private static List<String> strings(JsonNode node) {
        var result=new ArrayList<String>();
        if(node.isArray()) for(var value:node) if(value.isString() && !value.asText().isBlank()) result.add(value.asText());
        return List.copyOf(result);
    }
    private static String text(JsonNode n,String key) {
        var value=n.path(key); return value.isString() && !value.asText().isBlank()?value.asText():null;
    }
    private static String plain(String value) {
        if(value==null) return null;
        return value.replaceAll("(?is)<(script|style)\\b[^>]*>.*?</\\1>","")
            .replaceAll("(?i)<br\\s*/?>|</p>","\n").replaceAll("<[^>]*>","")
            .replace("&nbsp;"," ").replace("&amp;","&").replace("&lt;","<").replace("&gt;",">").strip();
    }
    private static String safeUrl(String value) {
        if(value==null) return null;
        try {
            var uri=URI.create(value);
            if(uri.getUserInfo()!=null || uri.getHost()==null) return null;
            if("http".equals(uri.getScheme()) && (uri.getHost().equals("books.google.com") || uri.getHost().endsWith(".googleusercontent.com")))
                return "https"+value.substring(4);
            return "https".equals(uri.getScheme())?value:null;
        } catch(Exception ex) { return null; }
    }
}
