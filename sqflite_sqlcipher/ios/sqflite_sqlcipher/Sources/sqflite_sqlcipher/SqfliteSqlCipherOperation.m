//
//  Operation.m
//  sqflite
//
//  Created by Alexandre Roux on 09/01/2018.
//

#import <Foundation/Foundation.h>
#import "SqfliteSqlCipherOperation.h"
#import "SqfliteSqlCipherPlugin.h"

// Abstract
@implementation SqfliteSqlCipherOperation

- (NSString*)getMethod {
    return  nil;
}
- (NSString*)getSql {
    return nil;
}
- (NSArray*)getSqlArguments {
    return nil;
}
- (NSNumber*)getInTransactionArgument {
    return nil;
}
- (bool)getNoResult {
    return false;
}
- (bool)getContinueOnError {
    return false;
}
- (void)success:(NSObject*)results {}

- (void)error:(NSObject*)error {}

@end

@implementation SqfliteSqlCipherBatchOperation

@synthesize dictionary, results, error, noResult, continueOnError;

- (NSString*)getMethod {
    return [dictionary objectForKey:SqfliteSqlCipherParamMethod];
}

- (NSString*)getSql {
    return [dictionary objectForKey:SqfliteSqlCipherParamSql];
}

- (NSArray*)getSqlArguments {
    NSArray* arguments = [dictionary objectForKey:SqfliteSqlCipherParamSqlArguments];
    return [SqfliteSqlCipherPlugin toSqlArguments:arguments];
}

- (NSNumber*)getInTransactionArgument {
    return [dictionary objectForKey:SqfliteSqlCipherParamInTransaction];
}

- (bool)getNoResult {
    return noResult;
}

- (bool)getContinueOnError {
    return continueOnError;
}

- (void)success:(NSObject*)results {
    self.results = results;
}

- (void)error:(FlutterError*)error {
    self.error = error;
}

- (void)handleSuccess:(NSMutableArray*)results {
    if (![self getNoResult]) {
        // We wrap the result in 'result' map
        [results addObject:[NSDictionary dictionaryWithObject:((self.results == nil) ? [NSNull null] : self.results)
                                                       forKey:SqfliteSqlCipherParamResult]];
    }
}

// Encore the flutter error in a map
- (void)handleErrorContinue:(NSMutableArray*)results {
    if (![self getNoResult]) {
        // We wrap the error in an 'error' map
        NSMutableDictionary* error = [NSMutableDictionary new];
        error[SqfliteSqlCipherParamErrorCode] = self.error.code;
        if (self.error.message != nil) {
            error[SqfliteSqlCipherParamErrorMessage] = self.error.message;
        }
        if (self.error.details != nil) {
            error[SqfliteSqlCipherParamErrorData] = self.error.details;
        }
        [results addObject:[NSDictionary dictionaryWithObject:error
                                                       forKey:SqfliteSqlCipherParamError]];
    }
}

- (void)handleError:(FlutterResult)result {
    result(error);
}

@end

@implementation SqfliteSqlCipherMethodCallOperation

@synthesize flutterMethodCall;
@synthesize flutterResult;

+ (SqfliteSqlCipherMethodCallOperation*)newWithCall:(FlutterMethodCall*)flutterMethodCall result:(FlutterResult)flutterResult {
    SqfliteSqlCipherMethodCallOperation* operation = [SqfliteSqlCipherMethodCallOperation new];
    operation.flutterMethodCall = flutterMethodCall;
    operation.flutterResult = flutterResult;
    return operation;
}

- (NSString*)getMethod {
    return flutterMethodCall.method;
}

- (NSString*)getSql {
    return flutterMethodCall.arguments[SqfliteSqlCipherParamSql];
}

- (bool)getNoResult {
    NSNumber* noResult = flutterMethodCall.arguments[SqfliteSqlCipherParamNoResult];
    return [noResult boolValue];
}

- (bool)getContinueOnError {
    NSNumber* noResult = flutterMethodCall.arguments[SqfliteSqlCipherParamContinueOnError];
    return [noResult boolValue];
}

- (NSArray*)getSqlArguments {
    NSArray* arguments = flutterMethodCall.arguments[SqfliteSqlCipherParamSqlArguments];
    return [SqfliteSqlCipherPlugin toSqlArguments:arguments];
}

- (NSNumber*)getInTransactionArgument {
    return flutterMethodCall.arguments[SqfliteSqlCipherParamInTransaction];
}

- (void)success:(NSObject*)results {
    flutterResult(results);
}
- (void)error:(NSObject*)error {
    flutterResult(error);
}
@end
