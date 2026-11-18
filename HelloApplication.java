package com.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@SpringBootApplication
@RestController
public class HelloApplication {

    public static void main(String[] args) {
        SpringApplication.run(HelloApplication.class, args);
    }

    @GetMapping("/")
    public Map<String, String> hello() {
        return Map.of(
                "message", "Hello from a Dockerized Java app!",
                "javaVersion", System.getProperty("java.version"),
                "imageVariant", System.getenv().getOrDefault("IMAGE_VARIANT", "unknown")
        );
    }
}
