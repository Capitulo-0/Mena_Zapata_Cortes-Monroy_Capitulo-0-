package com.capitulo0.backend.writer;
import com.capitulo0.backend.common.exception.ApiException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.databind.json.JsonMapper;
import java.time.Instant;
import java.util.*;
@Service
public class WriterService {
 private final WriterStoryRepository stories;
 private final com.capitulo0.backend.user.repository.UserRepository users;
 private final JsonMapper json = JsonMapper.builder().build();
 public WriterService(WriterStoryRepository stories, com.capitulo0.backend.user.repository.UserRepository users){this.stories=stories;this.users=users;}
 private WriterStoryEntity own(Long owner,String id){return stories.findByStoryKeyAndOwnerId(id,owner).orElseThrow(()->ApiException.notFound("Historia"));}
 private WriterDocument document(WriterStoryEntity row){
  var d=json.readValue(row.payload,WriterDocument.class);
  return d.state(d.status(),d.chapters(),row.createdAt,row.updatedAt,row.revision);
 }
 private void revision(WriterStoryEntity row,Long expected){
  if(expected==null||row.revision!=expected) throw new ApiException(HttpStatus.CONFLICT,"WRITER_CONFLICT","La historia cambio. Recarga antes de guardar; conserva tu texto.");
 }
 private void validateContent(WriterDocument d){
  Set<String> ids=new HashSet<>(); Set<Integer> orders=new HashSet<>();long size=0;
  for(var c:d.chapters()){
   if(!ids.add(c.id())||!orders.add(c.order()))throw ApiException.invalid("Capitulos duplicados u orden repetido");
   size+=c.content().length();
  }
  if(size>1000000)throw ApiException.invalid("La historia excede un millon de caracteres");
 }
 private WriterDocument persist(WriterStoryEntity row,WriterDocument d){
  row.updatedAt=Instant.now();
  row.payload=json.writeValueAsString(d.state(d.status(),d.chapters(),row.createdAt,row.updatedAt,row.revision));
  return document(stories.saveAndFlush(row));
 }
 @Transactional(readOnly=true) public List<WriterDocument> list(Long owner){return stories.findByOwnerIdOrderByUpdatedAtDesc(owner).stream().map(this::document).toList();}
 @Transactional(readOnly=true) public WriterDocument get(Long owner,String id){return document(own(owner,id));}
 @Transactional public WriterDocument save(Long owner,String id,WriterDocument d){
  if(!id.equals(d.id()))throw ApiException.invalid("Identificador de historia distinto");validateContent(d);
  var found=stories.findByStoryKey(id);
  WriterStoryEntity row;
  if(found.isPresent()){
   row=found.get();if(!owner.equals(row.ownerId))throw ApiException.notFound("Historia");revision(row,d.revision());
   if(!document(row).status().equals(d.status()))throw ApiException.invalid("Usa la accion de publicacion");
  }else{
   if(d.revision()!=null&&d.revision()!=0)throw ApiException.notFound("Historia");
   if(!"draft".equals(d.status()))throw ApiException.invalid("Crea primero un borrador");
   row=new WriterStoryEntity();row.storyKey=id;row.ownerId=owner;row.createdAt=Instant.now();
  }
  // Store the entire chapter set in the same transaction as metadata. Revision
  // checks prevent a stale editor from silently deleting chapters saved elsewhere.
  // Published edits are live: reject incomplete content and normalize every flag.
  boolean published="published".equals(d.status());
  if(published) requireComplete(d);
  return persist(row,d.state(d.status(),chapterState(d,published),row.createdAt,Instant.now(),row.revision));
 }
 @Transactional public WriterDocument publication(Long owner,String id,long revision,boolean published){
  var row=own(owner,id);revision(row,revision);var d=document(row);
  if(published) requireComplete(d);
  var chapters=chapterState(d,published);
  return persist(row,d.state(published?"published":"draft",chapters,row.createdAt,Instant.now(),row.revision));
 }
 private void requireComplete(WriterDocument d){
  if(d.chapters().isEmpty()||d.chapters().stream().anyMatch(c->c.title().isBlank()||c.content().isBlank()))
   throw ApiException.invalid("Completa todos los capitulos o retira la historia antes de guardar contenido incompleto");
 }
 private List<WriterDocument.Chapter> chapterState(WriterDocument d,boolean published){
  return d.chapters().stream().sorted(Comparator.comparingInt(WriterDocument.Chapter::order))
   .map(c->new WriterDocument.Chapter(c.id(),c.title(),c.content(),c.order(),published,c.createdAt(),c.updatedAt())).toList();
 }
 public record PublicationSummary(String id,String title,String synopsis,String genre,String coverPath,
  String authorName,String authorUsername,Instant updatedAt,int chapterCount){}
 @Transactional(readOnly=true) public List<PublicationSummary> community(Long reader){
  // Payload is an aggregate TEXT in V10. Filter on the server; never return private documents.
  var published=stories.findByOwnerIdNotOrderByUpdatedAtDesc(reader).stream()
   .filter(row->"published".equals(document(row).status())).limit(100).toList();
  var authors=new HashMap<Long,com.capitulo0.backend.user.entity.User>();
  users.findAllById(published.stream().map(row->row.ownerId).distinct().toList()).forEach(u->authors.put(u.getId(),u));
  return published.stream().map(row->{var d=document(row);var author=authors.get(row.ownerId);
   return new PublicationSummary(d.id(),d.title(),d.synopsis(),d.genre(),d.coverPath(),
    author==null||author.getDisplayName()==null?"Autor de Capitulo 0":author.getDisplayName(),
    author==null?null:author.getUsername(),d.updatedAt(),(int)d.chapters().stream().filter(WriterDocument.Chapter::isPublished).count());
  }).toList();
 }
 @Transactional public void delete(Long owner,String id,long revision){var row=own(owner,id);revision(row,revision);stories.delete(row);stories.flush();}
 @Transactional(readOnly=true) public WriterDocument published(String id){
  var row=stories.findByStoryKey(id).orElseThrow(()->ApiException.notFound("Historia"));var d=document(row);
  if(!"published".equals(d.status()))throw ApiException.notFound("Historia");
  return d.state(d.status(),d.chapters().stream().filter(WriterDocument.Chapter::isPublished).toList(),row.createdAt,row.updatedAt,row.revision);
 }
}
