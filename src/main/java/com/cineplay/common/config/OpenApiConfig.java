package com.cineplay.common.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {
    @Bean
    OpenAPI cinePlayOpenApi() {
        return new OpenAPI().info(new Info().title("CinePlay API").version("v1").description("Movie streaming and watch-party backend"));
    }
}
