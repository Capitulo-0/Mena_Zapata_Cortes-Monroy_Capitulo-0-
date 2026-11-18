package com.capitulo0.backend.writer;
import com.capitulo0.backend.auth.service.CurrentUserService;
import com.capitulo0.backend.common.exception.ApiException;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.*;
import org.springframework.dao.OptimisticLockingFailureException;
import java.util.List;
@RestController
public class WriterController {
 private final WriterService service;private final CurrentUserService current;
 public WriterController(WriterService service,CurrentUserService current){this.service=service;this.current=current;}
 @GetMapping("/api/me/writer/stories") public List<WriterDocument> list(){return service.list(current.require().getId());}
 @GetMapping("/api/me/writer/stories/{id}") public WriterDocument get(@PathVariable String id){return service.get(current.require().getId(),id);}
 @PostMapping("/api/me/writer/stories/{id}") public WriterDocument save(@PathVariable String id,@Valid @RequestBody WriterDocument d){return service.save(current.require().getId(),id,d);}
 public record Publication(long revision,boolean published){}
 @PostMapping("/api/me/writer/stories/{id}/publication") public WriterDocument publication(@PathVariable String id,@RequestBody Publication p){return service.publication(current.require().getId(),id,p.revision(),p.published());}
 @DeleteMapping("/api/me/writer/stories/{id}") @ResponseStatus(HttpStatus.NO_CONTENT)
 public void delete(@PathVariable String id,@RequestParam long revision){service.delete(current.require().getId(),id,revision);}
 @GetMapping("/api/writer/stories") public List<WriterService.PublicationSummary> community(){return service.community(current.require().getId());}
 // Community is authenticated; private modification endpoints remain owner scoped.
 @GetMapping("/api/writer/stories/{id}") public WriterDocument published(@PathVariable String id){current.require();return service.published(id);}
 @ExceptionHandler(OptimisticLockingFailureException.class) public ResponseEntity<java.util.Map<String,Object>> conflict(){
  return ResponseEntity.status(409).body(java.util.Map.of("status",409,"code","WRITER_CONFLICT","message","La historia cambio. Conserva tu texto y recarga."));
 }
}
