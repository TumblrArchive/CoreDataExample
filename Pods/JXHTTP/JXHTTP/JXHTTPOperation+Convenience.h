/**
 These methods and properties provide convenient access to the request and response objects of
 the underlying `NSURLConnection`. In most cases they simply pass through the property of the
 same name.
 */

#import "JXHTTPOperation.h"

@interface JXHTTPOperation (JXHTTPOperationConvenience)

@property (assign, nonatomic) NSURLCacheStoragePolicy requestCachePolicy;
@property (assign, nonatomic) BOOL requestShouldUsePipelining;
@property (strong, nonatomic) NSURL *requestMainDocumentURL;
@property (assign, nonatomic) NSTimeInterval requestTimeoutInterval;
@property (assign, nonatomic) NSURLRequestNetworkServiceType requestNetworkServiceType;
@property (strong, nonatomic) NSURL *requestURL;
@property (strong, nonatomic) NSDictionary *requestHeaders;
@property (strong, nonatomic) NSString *requestMethod;
@property (assign, nonatomic) BOOL requestShouldHandleCookies;

- (void)addValue:(NSString *)valueString forRequestHeader:(NSString *)headerFieldString;
- (void)setValue:(NSString *)valueString forRequestHeader:(NSString *)headerFieldString;

- (NSData *)responseData;
- (NSString *)responseString;
- (id)responseJSON;
- (NSDictionary *)responseHeaders;
- (NSInteger)responseStatusCode;
- (NSString *)responseStatusString;
- (long long)responseExpectedContentLength;
- (NSString *)responseExpectedFileName;
- (NSString *)responseMIMEType;
- (NSString *)responseTextEncodingName;
- (NSURL *)responseURL;

@end
