package com.cineplay.common.security;

import com.cineplay.common.exception.ErrorCode;
import com.cineplay.common.response.ErrorResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;

/** Returns the standard JSON error body for 401/403 raised inside the security filter chain. */
@Component
public class JsonSecurityHandlers implements AuthenticationEntryPoint, AccessDeniedHandler {
    private final ObjectMapper mapper;
    public JsonSecurityHandlers(ObjectMapper mapper) { this.mapper = mapper; }

    @Override
    public void commence(HttpServletRequest req, HttpServletResponse res, AuthenticationException e) throws IOException {
        write(res, HttpServletResponse.SC_UNAUTHORIZED, "Authentication required", ErrorCode.UNAUTHORIZED);
    }

    @Override
    public void handle(HttpServletRequest req, HttpServletResponse res, AccessDeniedException e) throws IOException {
        write(res, HttpServletResponse.SC_FORBIDDEN, "Access denied", ErrorCode.FORBIDDEN);
    }

    private void write(HttpServletResponse res, int status, String msg, ErrorCode code) throws IOException {
        res.setStatus(status);
        res.setContentType(MediaType.APPLICATION_JSON_VALUE);
        mapper.writeValue(res.getOutputStream(), ErrorResponse.of(msg, code.name(), null));
    }
}
