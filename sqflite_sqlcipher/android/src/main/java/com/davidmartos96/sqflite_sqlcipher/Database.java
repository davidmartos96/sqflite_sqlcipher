package com.davidmartos96.sqflite_sqlcipher;

import android.database.sqlite.SQLiteException;
import android.os.Build;
import android.util.Log;


import java.io.File;
import static com.davidmartos96.sqflite_sqlcipher.Constant.TAG;

import net.zetetic.database.DatabaseErrorHandler;
import net.zetetic.database.sqlcipher.SQLiteConnection;
import net.zetetic.database.sqlcipher.SQLiteDatabase;
import net.zetetic.database.sqlcipher.SQLiteDatabaseHook;

class Database {
    final boolean singleInstance;
    final String path;
    final String password;
    final int id;
    final int logLevel;
    SQLiteDatabase sqliteDatabase;
    boolean inTransaction;


    Database(String path, String password, int id, boolean singleInstance, int logLevel) {
        this.path = path;
        this.password = (password != null) ? password : "";

        this.singleInstance = singleInstance;
        this.id = id;
        this.logLevel = logLevel;
    }

    public void open() {
        openWithFlags(SQLiteDatabase.CREATE_IF_NECESSARY);

    }

    // Change default error handler to avoid erasing the existing file.
    public void openReadOnly() {
        openWithFlags(SQLiteDatabase.OPEN_READONLY, new DatabaseErrorHandler() {
            @Override
            public void onCorruption(SQLiteDatabase dbObj, SQLiteException exception) {

                // ignored
                // default implementation delete the file
                //
                // This happens asynchronously so cannot be tracked. However a simple
                // access should fail
            }

        });
    }

    private void openWithFlags(int flags) {
        openWithFlags(flags, null);
    }

    private void openWithFlags(int flags, DatabaseErrorHandler errorHandler) {
        try {
            sqliteDatabase = SQLiteDatabase.openDatabase(path, password, null, flags, errorHandler, null);

        }catch (Exception e) {
            Log.d(TAG, "Opening db in " + path + " with PRAGMA cipher_migrate");
            SQLiteDatabaseHook hook = new SQLiteDatabaseHook() {
                @Override
                public void preKey(SQLiteConnection database) {

                }

                @Override
                public void postKey(SQLiteConnection database) {
                    long migrateRes = database.executeForLong("PRAGMA cipher_migrate;", null, null);

                    if (migrateRes != 0) {
                        // Throw the original exception, assuming a wrong password was provided
                        throw e;
                    }
                }
            };

            sqliteDatabase = SQLiteDatabase.openDatabase(path, password, null, flags, errorHandler, hook);
        }
    }

    public void close() {
        sqliteDatabase.close();
    }

    public SQLiteDatabase getWritableDatabase() {
        return sqliteDatabase;
    }

    public SQLiteDatabase getReadableDatabase() {
        return sqliteDatabase;
    }

    public boolean enableWriteAheadLogging() {
        try {
            sqliteDatabase.rawExecSQL("PRAGMA journal_mode=WAL;");
        } catch (Exception e) {
            Log.e(TAG, getThreadLogPrefix() + "enable WAL error: " + e);
            return false;
        }
        return true;
    }

    String getThreadLogTag() {
        Thread thread = Thread.currentThread();

        return id + "," + thread.getName() + "(" + getThreadId(thread)+ ")";
    }

    String getThreadLogPrefix() {
        return "[" + getThreadLogTag() + "] ";
    }


    static void deleteDatabase(String path) {
        File file = new File(path);

        file.delete();
        new File(file.getPath() + "-journal").delete();
        new File(file.getPath() + "-shm").delete();
        new File(file.getPath() + "-wal").delete();
    }

    public static long getThreadId(Thread thread) {
        // SDK 36 is the minimum supported version
        // Build.VERSION_CODES.BAKLAVA is Android 36
        // for when Thread.threadId() is definitely available and getId() is deprecated.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA) { // Android 16 (API 36) and above
            // Use the new, recommended method
            return thread.threadId();
        } else {
            // For older Android versions where threadId() might not be available
            // and getId() is still the primary way to get a thread ID.
            // Suppress the deprecation warning for this specific line.
            @SuppressWarnings("deprecation")
            long id = thread.getId();
            return id;
        }
    }
}
