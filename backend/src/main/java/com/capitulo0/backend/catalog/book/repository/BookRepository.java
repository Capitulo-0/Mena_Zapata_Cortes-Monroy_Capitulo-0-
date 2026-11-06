package com.capitulo0.backend.catalog.book.repository;
import com.capitulo0.backend.catalog.book.entity.Book;
import org.springframework.data.jpa.repository.JpaRepository;
public interface BookRepository extends JpaRepository<Book, Long> {}
