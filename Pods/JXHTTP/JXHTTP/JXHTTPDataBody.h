/**
 `JXHTTPDataBody` conforms to <JXHTTPRequestBody> and provides functionality for streaming
 request bodies directly from memory, with any content type.
 */

#import "JXHTTPRequestBody.h"

@interface JXHTTPDataBody : NSObject <JXHTTPRequestBody>

/**
 The data to upload.
 */
@property (strong, nonatomic) NSData *data;

/**
 The MIME content type of the data to upload.
 */
@property (copy, nonatomic) NSString *httpContentType;

/**
 Creates a new `JXHTTPDataBody` with the given data.

 @param data The data to upload.
 @returns A request body.
 */
+ (instancetype)withData:(NSData *)data;

/**
 Creates a new `JXHTTPDataBody` with the given data and MIME content type.

 @param data The data to upload.
 @param contentType The MIME content type of the data to upload.
 @returns A request body.
 */
+ (instancetype)withData:(NSData *)data contentType:(NSString *)contentType;

/**
 Creates a new `JXHTTPDataBody` with the given data and MIME content type.

 @param data The data to upload.
 @param contentType The MIME content type of the data to upload.
 @returns A request body.
 */
- (instancetype)initWithData:(NSData *)data contentType:(NSString *)contentType;

@end
