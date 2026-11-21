package com.cineplay.common.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Map;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ErrorResponse(boolean success, String message, String errorCode,
                            Map<String, String> fieldErrors, LocalDateTime timestamp) {
    public static ErrorResponse of(String message, String errorCode, Map<String, String> fieldErrors) {
        return new ErrorResponse(false, message, errorCode, fieldErrors, LocalDateTime.now(ZoneOffset.UTC));
    }
}
