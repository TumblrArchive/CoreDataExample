/**
 `JXHTTPFileBody` conforms to <JXHTTPRequestBody> and provides functionality for streaming
 request bodies directly from disk, with any content type.
 */

#import "JXHTTPRequestBody.h"

@interface JXHTTPFileBody : NSObject <JXHTTPRequestBody>

/**
 The path of the file to upload.
 */
@property (copy, nonatomic) NSString *filePath;

/**
 The MIME content type of the file to upload.
 */
@property (copy, nonatomic) NSString *httpContentType;

/**
 Creates a new `JXHTTPFileBody` with the given local file path.
 
 @param filePath The local path of the file.
 @returns A request body.
 */
+ (instancetype)withFilePath:(NSString *)filePath;

/**
 Creates a new `JXHTTPFileBody` with the given local file path.

 @param filePath The local path of the file.
 @param contentType The MIME content type of the file.
 @returns A request body.
 */
+ (instancetype)withFilePath:(NSString *)filePath contentType:(NSString *)contentType;

/**
 Creates a new `JXHTTPFileBody` with the given local file path.

 @param filePath The local path of the file.
 @param contentType The MIME content type of the file.
 @returns A request body.
 */
- (instancetype)initWithFilePath:(NSString *)filePath contentType:(NSString *)contentType;

@end
