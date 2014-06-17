/**
 `JXHTTPOperation` adds many features to <JXURLConnectionOperation>, including blocks
 and delegate methods via the <JXHTTPOperationDelegate> protocol. Blocks are
 performed serially on a private background queue unless <performsBlocksOnMainQueue>
 is set to `YES`.
 
 <JXHTTPOperationQueue> can be used to group multiple operations for progress tracking.
 
 Request data (i.e., POST bodies) can be supplied with an `NSInputStream` via the
 <requestBody> property, which takes any object conforming to the <JXHTTPRequestBody>
 protocol. The most common are premade:
 
 - <JXHTTPFormEncodedBody> (browser-style form encoding)
 - <JXHTTPMultipartBody> (multipart streaming from disk or memory)
 - <JXHTTPFileBody> (single part streaming from disk)
 - <JXHTTPJSONBody> (JSON from collection objects or string)
 - <JXHTTPDataBody> (raw request data)
 
 In addition, this family of classes makes use of <JXURLEncoding> to escape strings
 and <JXHTTPOperation+Convenience> to provide easier access to the underlying
 properties of request and response objects.
 
 On iOS, the system network activity indicator is updated by default. It waits on a
 0.25 second timer from the end of the last operation to prevent flickering.
 
 ## Examples ##
 
 ### Basic Operation ###
    
     JXHTTPOperation *op = [JXHTTPOperation withURLString:@"http://jxhttp.com/"];
     op.didFinishLoadingBlock = ^(JXHTTPOperation *op) {
        NSLog(@"some html: %@", op.responseString);
     };
     
     [[JXHTTPOperationQueue sharedQueue] addOperation:op];
 
 */

#import "JXURLConnectionOperation.h"
#import "JXHTTPOperationDelegate.h"
#import "JXHTTPRequestBody.h"

typedef void (^JXHTTPBlock)(JXHTTPOperation *operation);
typedef NSCachedURLResponse * (^JXHTTPCacheBlock)(JXHTTPOperation *operation, NSCachedURLResponse *response);
typedef NSURLRequest * (^JXHTTPRedirectBlock)(JXHTTPOperation *operation, NSURLRequest *request, NSURLResponse *response);

@interface JXHTTPOperation : JXURLConnectionOperation

/// @name Core

/**
 An optional, non-retained object conforming to the <JXHTTPOperationDelegate> protocol.
 
 Safe to access from any thread at any time.
 
 @warning Delegate methods will be called on a background thread. No other
 guarantees are made about thread continuity.
 */
@property (weak) NSObject <JXHTTPOperationDelegate> *delegate;

/**
 An optional request body object. The <JXHTTPRequestBody> protocol extends <JXHTTPOperationDelegate>,
 and has an opportunity to respond to the same messages immediately after the <delegate>.
 
 Safe to access from any thread at any time, should only be changed before operation start.
 */
@property (strong) NSObject <JXHTTPRequestBody> *requestBody;

/**
 A string guaranteed to be unique for the lifetime of the application process, useful
 for keying operations stored in a collection.
 
 Safe to access from any thread at any time.
 */
@property (strong, readonly) NSString *uniqueString;

/**
 A convenience property for creating an `NSOutputStream` that streams response data to disk.
 If this property is nil when the operation starts the `outputStream` property is used instead,
 which defaults to in-memory storage.
 
 @warning Unlike most properties of `JXHTTPOperation`, `responseDataFilePath` should not be accessed
 from mulitiple threads simultaneously and should only be changed before operation start.
 */
@property (copy, nonatomic) NSString *responseDataFilePath;

/**
 A user-supplied object retained for the lifetime of the operation.

 Safe to access and change from any thread at any time.
 */
@property (strong) id userObject;

/// @name Security

@property (strong, readonly) NSURLAuthenticationChallenge *authenticationChallenge;
@property (strong) NSURLCredential *credential;
@property (assign) BOOL useCredentialStorage;
@property (assign) BOOL trustAllHosts;
@property (copy) NSArray *trustedHosts;
@property (copy) NSString *username;
@property (copy) NSString *password;

/// @name Progress

/**
 A number between 0.0 and 1.0 indicating the download progress of the response,
 or `NSURLResponseUnknownLength` if the expected content length is unknown.
 
 Safe to access from any thread at any time.
 */
@property (strong, readonly) NSNumber *downloadProgress;

/**
 A number between 0.0 and 1.0 indicating the upload progress of the response,
 or `NSURLResponseUnknownLength` if the expected content length is unknown.
 
 Safe to access from any thread at any time.
 */
@property (strong, readonly) NSNumber *uploadProgress;

/**
 If `YES`, the system network activity indicator is updated (iOS only). Defaults to `YES`.
 A timer is used to prevent flickering.
 
 Safe to access and change from any thread at any time.
 */
@property (assign) BOOL updatesNetworkActivityIndicator;

/// @name Timing

/**
 The start date of the operation or `nil` if the operation has not started.
 
 Safe to access from any thread at any time.
 */
@property (strong, readonly) NSDate *startDate;

/**
 The finish date of the operation or `nil` if the operation has not finished.
 
 Safe to access from any thread at any time.
 */
@property (strong, readonly) NSDate *finishDate;

/**
 The number of seconds elapsed since the operation started, 0.0 if it has not.
 
 Safe to access from any thread at any time.
 */
@property (readonly) NSTimeInterval elapsedSeconds;

/// @name Blocks

/**
 If `YES`, blocks are dispatched to the main queue and run on the main thread.
 
 Defaults to `NO`, blocks are run a private serial dispatch queue.
 
 Safe to access and change from any thread at any time.
 */
@property (assign) BOOL performsBlocksOnMainQueue;

/**
 Performed at the very start of the operation, before the connection object is created.
 
 Safe to access and change from any thread at any time.
 
  @see <JXHTTPOperationDelegate>
 */
@property (copy) JXHTTPBlock willStartBlock;

/**
 Performed when the underlying `NSURLConnection` requires a new, unopened stream
 for the <requestBody> when a retransmission is necessary.
 
 Safe to access and change from any thread at any time.
 
 @warning For notification purposes only, do not use this block to supply the stream.
 
 @see <JXHTTPOperationDelegate>
 */
@property (copy) JXHTTPBlock willNeedNewBodyStreamBlock;

/**
 Performed when the underlying `NSURLConnection` receives a request for authentication.
 
 Safe to access and change from any thread at any time.
 
 @warning For notification purposes only, do not use this block to supply the credential.
 @see <JXHTTPOperationDelegate>
 */
@property (copy) JXHTTPBlock willSendRequestForAuthenticationChallengeBlock;

/**
 Performed immediately after the underlying `NSURLConnection` begins.
 
 Safe to access and change from any thread at any time.
 
  @see <JXHTTPOperationDelegate>
 */
@property (copy) JXHTTPBlock didStartBlock;

/**
 Performed immediately after the underlying `NSURLConnection` receives a response.
 
 Safe to access and change from any thread at any time.
 
  @see <JXHTTPOperationDelegate>
 */
@property (copy) JXHTTPBlock didReceiveResponseBlock;

/**
 Performed every time the underlying `NSURLConnection` receives response data.
 
 Safe to access and change from any thread at any time.
 
  @see <JXHTTPOperationDelegate>
 */
@property (copy) JXHTTPBlock didReceiveDataBlock;

/**
 Performed every time the underlying `NSURLConnection` sends request data.
 
 Safe to access and change from any thread at any time.
 
  @see <JXHTTPOperationDelegate>
 */
@property (copy) JXHTTPBlock didSendDataBlock;

/**
 Performed when the underlying `NSURLConnection` finishes loading successfully.
 
 Safe to access and change from any thread at any time.
 
  @see <JXHTTPOperationDelegate>
 */
@property (copy) JXHTTPBlock didFinishLoadingBlock;

/**
 Performed when the underlying `NSURLConnection` fails to load. The `error` property
 is available for inspection.
 
 Safe to access and change from any thread at any time.
 
  @see <JXHTTPOperationDelegate>
 */
@property (copy) JXHTTPBlock didFailBlock;

/**
 TKTK
 
 Safe to access and change from any thread at any time.
 
  @see <JXHTTPOperationDelegate>
 */
@property (copy) JXHTTPCacheBlock willCacheResponseBlock;

/**
 TKTK
 
 Safe to access and change from any thread at any time.
 
  @see <JXHTTPOperationDelegate>
 */
@property (copy) JXHTTPRedirectBlock willSendRequestRedirectBlock;

/// @name Initialization

/**
 Creates a new `JXHTTPOperation` with the specified URL.
 
 @param urlString The URL to request.
 @returns An operation.
 */
+ (instancetype)withURLString:(NSString *)urlString;

/**
 Creates a new `JXHTTPOperation` with the specified URL and query parameters,
 escaped via <JXURLEncoding>.
 
 @param urlString The URL to request.
 @param parameters A dictionary of keys and values to form the query string.
 @returns An operation.
 */
+ (instancetype)withURLString:(NSString *)urlString queryParameters:(NSDictionary *)parameters;

@end
