package com.capitulo0.backend.readingclub.controller;

import com.capitulo0.backend.readingclub.dto.CreateReadingClubRequest;
import com.capitulo0.backend.readingclub.dto.ReadingClubResponse;
import com.capitulo0.backend.readingclub.service.ReadingClubService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/clubs")
public class ReadingClubController {

    private final ReadingClubService clubs;

    public ReadingClubController(ReadingClubService clubs) {
        this.clubs = clubs;
    }

    @GetMapping("/home")
    public List<ReadingClubResponse> home() {
        return clubs.homeClubs();
    }

    @GetMapping
    public Page<ReadingClubResponse> all(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "12") int size
    ) {
        return clubs.allClubs(page, size);
    }

    @GetMapping("/mine")
    public List<ReadingClubResponse> mine() {
        return clubs.myClubs();
    }

    @GetMapping("/{id}")
    public ReadingClubResponse detail(@PathVariable Long id) {
        return clubs.clubDetail(id);
    }

    @PostMapping
    public ResponseEntity<ReadingClubResponse> create(
            @Valid @RequestBody CreateReadingClubRequest form
    ) {
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(clubs.create(form));
    }

    @PostMapping("/{id}/join")
    public ReadingClubResponse join(@PathVariable Long id) {
        return clubs.joinClub(id);
    }

    @DeleteMapping("/{id}/membership")
    public ReadingClubResponse leave(@PathVariable Long id) {
        return clubs.leaveClub(id);
    }
}
