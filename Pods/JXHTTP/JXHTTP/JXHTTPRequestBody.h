/**
 `JXHTTPRequestBody` is a protocol that allows any object to provide request body data for a
 `JXHTTPOperation`. Conforming objects also receive the standard <JXHTTPOperationDelegate>
 calls (if implemented). This allows, for example, last minute creation of an input stream
 when the operation starts.
 
 All methods are guaranteed to be called serially from the same thread.
 */

#import "JXHTTPOperationDelegate.h"

@protocol JXHTTPRequestBody <JXHTTPOperationDelegate>
@required

/**
 A stream that will supply the data for the request body section of an HTTP request.

 @warning This method may be called multiple times and must return a new, unopened stream.
 
 @returns An input stream.
 */
- (NSInputStream *)httpInputStream;

/**
 A string that represents the MIME content type of the request data. If nil, defaults to
 `application/octet-stream`.

 @returns A string.
 */
- (NSString *)httpContentType;

/**
 The expected length of the request data, used to calculate upload progress. If unknown
 this method is expected to return `NSURLResponseUnknownLength`.

 @returns An integer.
 */
- (long long)httpContentLength;
@end
