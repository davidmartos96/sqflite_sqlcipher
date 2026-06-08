//
//  Operation.h
//  sqflite
//
//  Created by Alexandre Roux on 09/01/2018.
//
#import "SqfliteSqlCipherPlugin.h"

#ifndef SqfliteSqlCipherOperation_h
#define SqfliteSqlCipherOperation_h

@interface SqfliteSqlCipherOperation : NSObject

- (NSString*)getMethod;
- (NSString*)getSql;
- (NSArray*)getSqlArguments;
- (NSNumber*)getInTransactionArgument;
- (void)success:(NSObject*)results;
- (void)error:(FlutterError*)error;
- (bool)getNoResult;
- (bool)getContinueOnError;

@end

@interface SqfliteSqlCipherBatchOperation : SqfliteSqlCipherOperation

@property (atomic, retain) NSDictionary* dictionary;
@property (atomic, retain) NSObject* results;
@property (atomic, retain) FlutterError* error;
@property (atomic, assign) bool noResult;
@property (atomic, assign) bool continueOnError;

- (void)handleSuccess:(NSMutableArray*)results;
- (void)handleErrorContinue:(NSMutableArray*)results;
- (void)handleError:(FlutterResult)result;

@end

@interface SqfliteSqlCipherMethodCallOperation : SqfliteSqlCipherOperation

@property (atomic, retain) FlutterMethodCall* flutterMethodCall;
@property (atomic, assign) FlutterResult flutterResult;

+ (SqfliteSqlCipherMethodCallOperation*)newWithCall:(FlutterMethodCall*)flutterMethodCall result:(FlutterResult)flutterResult;

@end

#endif /* SqfliteSqlCipherOperation_h */
