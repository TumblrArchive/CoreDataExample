/**
 `JXHTTPJSONBody` conforms to <JXHTTPRequestBody> and provides functionality for JSON
 POST request bodies.
 
 Reports its content type as `application/json; charset=utf-8`.
 */

#import "JXHTTPRequestBody.h"

@interface JXHTTPJSONBody : NSObject <JXHTTPRequestBody>

/**
 Creates a new `JXHTTPJSONBody`.

 @param data The UTF-8 data of a previously serialized JSON string.
 @returns A JSON request body.
 */
+ (instancetype)withData:(NSData *)data;

/**
 Creates a new `JXHTTPJSONBody`.

 @param string A previously serialized JSON string.
 @returns A JSON request body.
 */
+ (instancetype)withString:(NSString *)string;

/**
 Creates a new `JXHTTPJSONBody`.

 @param dictionaryOrArray A dictionary or array, which will be serialized into a JSON string.
 @returns A JSON request body.
 */
+ (instancetype)withJSONObject:(id)dictionaryOrArray;

/**
 Creates a new `JXHTTPJSONBody`.

 @param data The UTF-8 data of a previously serialized JSON string.
 @returns A JSON request body.
 */
- (instancetype)initWithData:(NSData *)data;

@end
