
package com.capitulo0.backend.user.controller;

import com.capitulo0.backend.user.dto.PublicProfileResponse;
import com.capitulo0.backend.user.dto.UserSearchResponse;
import com.capitulo0.backend.user.service.PublicProfileService;
import com.capitulo0.backend.user.service.UserSearchService;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/users")
public class PublicProfileController {

    private final PublicProfileService profiles;
    private final UserSearchService searchService;

    public PublicProfileController(
        PublicProfileService profiles,
        UserSearchService searchService
    ) {
        this.profiles = profiles;
        this.searchService = searchService;
    }

    @GetMapping("/search")
    public List<UserSearchResponse> search(
        @RequestParam(name = "q", required = false) String query
    ) {
        return searchService.search(query);
    }

    @GetMapping("/{username}")
    public PublicProfileResponse findByUsername(
        @PathVariable String username
    ) {
        return profiles.findByUsername(username);
    }
}
