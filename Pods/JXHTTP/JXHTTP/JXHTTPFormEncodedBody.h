/**
 `JXHTTPFormEncodedBody` conforms to <JXHTTPRequestBody> and provides functionality for
 form-encoded request bodies (i.e., the type usually sent by browsers.)
 
 Reports its content type as `application/x-www-form-urlencoded; charset=utf-8`.
 */

#import "JXHTTPRequestBody.h"

@interface JXHTTPFormEncodedBody : NSObject <JXHTTPRequestBody>

/**
 A dictionary that will be form-encoded upon transmission.
 */
@property (strong, readonly, nonatomic) NSMutableDictionary *dictionary;

/**
 Creates a new `JXHTTPFormEncodedBody`.
 
 @see <JXURLEncoding>

 @param dictionary A dictionary that will be form-encoded upon transmission.
 @returns A request body.
 */
+ (instancetype)withDictionary:(NSDictionary *)dictionary;

/**
 Creates a new `JXHTTPFormEncodedBody`.

 @see <JXURLEncoding>

 @param dictionary A dictionary that will be form-encoded upon transmission.
 @returns A request body.
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
