package com.davidmartos96.sqflite_sqlcipher.operation;

/**
 * Created by alex on 09/01/18.
 */

public interface OperationResult {
    void error(final String errorCode, final String errorMessage, final Object data);

    void success(final Object result);
}
