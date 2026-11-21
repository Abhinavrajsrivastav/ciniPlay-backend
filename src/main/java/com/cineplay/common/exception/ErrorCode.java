package com.cineplay.common.exception;

import org.springframework.http.HttpStatus;

public enum ErrorCode {
    VALIDATION_FAILED(HttpStatus.BAD_REQUEST),
    UNAUTHORIZED(HttpStatus.UNAUTHORIZED),
    FORBIDDEN(HttpStatus.FORBIDDEN),
    NOT_FOUND(HttpStatus.NOT_FOUND),
    CONFLICT(HttpStatus.CONFLICT),
    EMAIL_ALREADY_REGISTERED(HttpStatus.CONFLICT),
    ROOM_CAPACITY_EXCEEDED(HttpStatus.CONFLICT),
    ROOM_CLOSED(HttpStatus.CONFLICT),
    RATE_LIMITED(HttpStatus.TOO_MANY_REQUESTS),
    INTERNAL_ERROR(HttpStatus.INTERNAL_SERVER_ERROR);

    private final HttpStatus status;
    ErrorCode(HttpStatus status) { this.status = status; }
    public HttpStatus status() { return status; }
}
