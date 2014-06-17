/**
 `JXHTTPMultipartBody` conforms to <JXHTTPRequestBody> and provides functionality for
 mulitpart MIME request bodies (with potentially multiple content types).
 
 File parts are streamed from disk using an `NSInputStream` and therefore memory
 efficient even in the case of very large files.
 */

#import "JXHTTPRequestBody.h"

@interface JXHTTPMultipartBody : NSObject <NSStreamDelegate, JXHTTPRequestBody>

/**
 The stream buffer size for the file input stream. In most cases you shouldn't need to
 change this, the 64K default is intended to match the output stream of `NSURLConnection`.
 */
@property (assign, nonatomic) NSUInteger streamBufferLength;

/**
 Creates a new `JXHTTPMultipartBody`.
 
 @param stringParameters A dictionary of keys and values that will be added as a text part.
 @returns A multipart request body.
 */
+ (instancetype)withDictionary:(NSDictionary *)stringParameters;

/**
 Creates a new `JXHTTPMultipartBody`.

 @param stringParameters A dictionary of keys and values that will be added as a `text/plain` part.
 @returns A multipart request body.
 */
- (instancetype)initWithDictionary:(NSDictionary *)stringParameters;

/**
 Adds a new `text/plain` part with the specified key.

 @param string The value.
 @param key The key.
 */
- (void)addString:(NSString *)string forKey:(NSString *)key;

/**
 Adds a new `text/plain` part with the specified key and overwrites any existing value.

 @param string The value.
 @param key The key.
 */
- (void)setString:(NSString *)string forKey:(NSString *)key;

/**
 Adds a new data part with the specified content type.

 @param data The data.
 @param key The key.
 @param contentTypeOrNil The content type, or `nil` to default to `application/octet-stream`.
 @param fileNameOrNil A suggested file name for the recipient, ignored by most servers (safe to pass nil).
 */
- (void)addData:(NSData *)data forKey:(NSString *)key contentType:(NSString *)contentTypeOrNil fileName:(NSString *)fileNameOrNil;

/**
 Adds a new data part with the specified content type and overwrites any existing value.

 @param data The data.
 @param key The key.
 @param contentTypeOrNil The content type, or `nil` to default to `application/octet-stream`.
 @param fileNameOrNil A suggested file name for the recipient, ignored by most servers (safe to pass nil).
 */
- (void)setData:(NSData *)data forKey:(NSString *)key contentType:(NSString *)contentTypeOrNil fileName:(NSString *)fileNameOrNil;

/**
 Adds a new file part with the specified content type. The file will not be accessed until
 the connection begins but it must exist at the time it's added.

 @param filePath The local path of the file.
 @param key The key.
 @param contentTypeOrNil The content type, or `nil` to default to `application/octet-stream`.
 @param fileNameOrNil A suggested file name for the recipient, ignored by most servers (safe to pass nil).
 */
- (void)addFile:(NSString *)filePath forKey:(NSString *)key contentType:(NSString *)contentTypeOrNil fileName:(NSString *)fileNameOrNil;

/**
 Adds a new file part with the specified content type. The file will not be accessed until
 the connection begins but it must exist at the time it's added. Overwrites any existing value.

 @param filePath The local path of the file.
 @param key The key.
 @param contentTypeOrNil The content type, or `nil` to default to `application/octet-stream`.
 @param fileNameOrNil A suggested file name for the recipient, ignored by most servers (safe to pass nil).
 */
- (void)setFile:(NSString *)filePath forKey:(NSString *)key contentType:(NSString *)contentTypeOrNil fileName:(NSString *)fileNameOrNil;

@end
