package com.capitulo0.backend.integration.googlebooks;
import java.util.List;
import java.util.Map;
/** Application metadata, independent of provider JSON and JPA. */
public record GoogleBook(String volumeId, String title, String subtitle, List<String> authors,
    String description, String publisher, String publishedDate, Integer pageCount,
    List<String> categories, String language, Map<String,String> identifiers,
    String coverUrl, String infoUrl) {}
