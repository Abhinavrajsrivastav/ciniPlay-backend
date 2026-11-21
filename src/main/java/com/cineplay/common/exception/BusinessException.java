package com.cineplay.common.exception;

/** Expected, user-facing failure. Mapped to an HTTP status by {@link GlobalExceptionHandler}. */
public class BusinessException extends RuntimeException {
    private final ErrorCode code;
    public BusinessException(ErrorCode code, String message) { super(message); this.code = code; }
    public ErrorCode code() { return code; }
}
