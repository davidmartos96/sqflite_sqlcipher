#if TARGET_OS_IPHONE
#import <Flutter/Flutter.h>
#else
#import <FlutterMacOS/FlutterMacOS.h>
#endif

@interface SqfliteSqlCipherPlugin : NSObject<FlutterPlugin>

+ (NSArray*)toSqlArguments:(NSArray*)rawArguments;

@end

extern NSString *const SqfliteSqlCipherParamMethod;
extern NSString *const SqfliteSqlCipherParamSql;
extern NSString *const SqfliteSqlCipherParamSqlArguments;
extern NSString *const SqfliteSqlCipherParamInTransaction;
extern NSString *const SqfliteSqlCipherParamNoResult;
extern NSString *const SqfliteSqlCipherParamContinueOnError;
extern NSString *const SqfliteSqlCipherParamResult;
extern NSString *const SqfliteSqlCipherParamError;
extern NSString *const SqfliteSqlCipherParamErrorCode;
extern NSString *const SqfliteSqlCipherParamErrorMessage;
extern NSString *const SqfliteSqlCipherParamErrorData;
