package com.capitulo0.backend.user.controller;

import com.capitulo0.backend.user.service.UserBookFavoritesService;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/me/favorite-books")
public class UserBookFavoritesController {
    private final UserBookFavoritesService favorites;
    public UserBookFavoritesController(UserBookFavoritesService favorites) { this.favorites = favorites; }

    @GetMapping
    public List<Long> mine() { return favorites.mine(); }

    @PostMapping("/{bookId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void add(@PathVariable Long bookId) { favorites.add(bookId); }

    @DeleteMapping("/{bookId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void remove(@PathVariable Long bookId) { favorites.remove(bookId); }
}
