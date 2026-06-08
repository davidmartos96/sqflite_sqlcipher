package com.davidmartos96.sqflite_sqlcipher.operation;

import com.davidmartos96.sqflite_sqlcipher.SqlCommand;

import java.util.HashMap;
import java.util.Map;

import static com.davidmartos96.sqflite_sqlcipher.Constant.PARAM_SQL;
import static com.davidmartos96.sqflite_sqlcipher.Constant.PARAM_SQL_ARGUMENTS;

public class SqlErrorInfo {

    static public Map<String, Object> getMap(Operation operation) {
        Map<String, Object> map = null;
        SqlCommand command = operation.getSqlCommand();
        if (command != null) {
            map = new HashMap<>();
            map.put(PARAM_SQL, command.getSql());
            map.put(PARAM_SQL_ARGUMENTS, command.getRawSqlArguments());
        }
        return map;
    }
}
