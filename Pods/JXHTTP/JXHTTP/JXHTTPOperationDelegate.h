/**
 `JXHTTPOperationDelegate` is a protocol that allows any object to receive synchronous callbacks about
 the progress of a `JXHTTPOperation` and optionally influence its execution.
 
 These methods may be called from different threads.
 */
@class JXHTTPOperation;

@protocol JXHTTPOperationDelegate <NSObject>

@optional

/**
 Called at the very beginning of the operation, before the connection starts and before the
 request body is setup.
 
 @param operation The operation.
 */
- (void)httpOperationWillStart:(JXHTTPOperation *)operation;

/**
 Called when the connection needs a new, unopened body stream.

 @param operation The operation.
 */
- (void)httpOperationWillNeedNewBodyStream:(JXHTTPOperation *)operation;

/**
 Called when the underlying `NSURLConnection` receives `willSendRequestForAuthenticationChallenge:`,
 see the `NSURLConnectionDelegate` docs for more information.
 
 The `NSURLAuthenticationChallenge` is available for inspection via the `authenticateChallenge`
 property of the operation. To supply your own `NSURLCredential` in response to the challenge, set
 the `credential` property before this method exits.
 
 In most cases, it's easier to respond to HTTP basic auth challenges via the `username` and `password`
 properties, which can be set before the operation begins instead of using this callback.
 
 Similarly, SSL challenges can be met with the `trustedHosts` or `trustAllHosts` properties.
 
 If this method is implemented and no `credential` is supplied, the operation attempts to proceed
 by calling `continueWithoutCredentialForAuthenticationChallenge:` on the sender.

 @param operation The operation.
 */
- (void)httpOperationWillSendRequestForAuthenticationChallenge:(JXHTTPOperation *)operation;

/**
 Called just after the connection starts. At this point all streams will be open.

 @param operation The operation.
 */
- (void)httpOperationDidStart:(JXHTTPOperation *)operation;

/**
 Called when the connection receives a response (zero or once per operation).

 @param operation The operation.
 */
- (void)httpOperationDidReceiveResponse:(JXHTTPOperation *)operation;

/**
 Called periodically as the connection receives data.

 @param operation The operation.
 */
- (void)httpOperationDidReceiveData:(JXHTTPOperation *)operation;

/**
 Called periodically as the connection sends data.

 @param operation The operation.
 */
- (void)httpOperationDidSendData:(JXHTTPOperation *)operation;

/**
 Called when the connection finishes loading data, but before the operation has completed.

 @param operation The operation.
 */
- (void)httpOperationDidFinishLoading:(JXHTTPOperation *)operation;

/**
 Called when the operation fails (zero or once per operation).

 @param operation The operation.
 */
- (void)httpOperationDidFail:(JXHTTPOperation *)operation;

/**
 Called before the operation caches a response. The response can be modified before storage.

 Returning nil will prevent the request from being cached. See the `NSURLConnectionDataDelegate`
 docs for more information.

 @param operation The operation.
 @param cachedResponse The response to be cached.
 @returns A modified cache response, the original cache response, or nil if no caching should occur.
 */
- (NSCachedURLResponse *)httpOperation:(JXHTTPOperation *)operation willCacheResponse:(NSCachedURLResponse *)cachedResponse;

/**
 Called before the underlying `NSURLConnection` changes URLs in response to a redirection.
 May be called multiple times.
 
 See the `NSURLConnectionDataDelegate` docs for more information.
 
 @param operation The operation.
 @param request The proposed redirect request.
 @param redirectResponse The response that caused the direct (may be nil).
 @returns A new request for redirection, the original request to continue redirection,or nil to prevent redirection.
 */
- (NSURLRequest *)httpOperation:(JXHTTPOperation *)operation willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse;
@end
