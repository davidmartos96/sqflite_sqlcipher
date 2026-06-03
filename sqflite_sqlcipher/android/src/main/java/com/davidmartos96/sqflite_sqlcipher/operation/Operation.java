package com.davidmartos96.sqflite_sqlcipher.operation;

import com.davidmartos96.sqflite_sqlcipher.SqlCommand;

/**
 * Created by alex on 09/01/18.
 */

public interface Operation extends OperationResult {

    String getMethod();

    <T> T getArgument(String key);

    SqlCommand getSqlCommand();

    boolean getNoResult();

    // In batch, means ignoring the error
    boolean getContinueOnError();

    // Only for execute command
    Boolean getInTransaction();
}
