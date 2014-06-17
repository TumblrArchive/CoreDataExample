/**
 `JXURLConnectionOperation` is a <JXOperation> subclass that encapsulates an
 `NSURLConnection`. It implements a basic set of delegate methods for writing
 response data to an `NSOutputStream` and counting the bytes transferred.
 
 All connections and streams are scheduled on the runloop of a <sharedThread>
 that never exits. This is preferable to using the runloop of a thread provided
 by a queue because GCD manages its threads dynamically and there's no guarantee
 about the lifetime of a GCD thread. There is also evidence that manipulating
 the runloop of a GCD thread confuses the GCD scheduler. For more discussion:
 
 <http://stackoverflow.com/questions/7213845/>
 
 From the _Concurrency Programming Guide_: "Although you can obtain information
 about the underlying thread running a task, it is better to avoid doing so."
 And so we provide our own thread.
 
 ## Example ##
 
 Although `JXURLConnectionOperation` is essentially a building block towards
 <JXHTTPOperation> it can be used effectively (if tediously) on its own:
 
     NSURL *url = [[NSURL alloc] initWithString:@"http://jxhttp.com/"];
     JXURLConnectionOperation *op = [[JXURLConnectionOperation alloc] initWithURL:url];
     [op startAndWaitUntilFinished];
 
     NSData *responseData = [op.outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
     NSString *someHTML = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
     NSLog(@"%@", someHTML);
 */

#import "JXOperation.h"

@interface JXURLConnectionOperation : JXOperation <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

/// @name Connection

/**
 The request used to create the connection when the operation starts.
 
 Safe to access from any thread at any time.
 */
@property (strong, readonly) NSMutableURLRequest *request;

/**
 The connection response if one has been received, otherwise `nil`.
 
 Safe to access from any thread at any time.
 */
@property (strong, readonly) NSURLResponse *response;

/**
 The connection error if one has been received, otherwise `nil`.
 
 Safe to access from any thread at any time.
 */
@property (strong, readonly) NSError *error;

/**
 The stream to which downloaded bytes will be written.
 
 This can be set to any `NSOutputStream` or subclass thereof, providing that
 it is new and unopened. If this property is `nil` when the operation starts
 an `outputStreamToMemory` is created by default.
 
 Safe to access from any thread at any time.
 
 @warning Do not change this property after the operation has started.
 */
@property (strong) NSOutputStream *outputStream;

/// @name Progress

/**
 The number of bytes downloaded.
 
 Safe to access from any thread at any time.
 */
@property (assign, readonly) long long bytesDownloaded;

/**
 The number of bytes uploaded.
 
 Safe to access from any thread at any time.
 */
@property (assign, readonly) long long bytesUploaded;

/// @name Initialization

/**
 A shared thread that never exits. All connections and streams are scheduled
 on this thread's runloop.
 
 Safe to access from any thread at any time.
 
 @returns The shared thread used by all connections and streams.
 */
+ (NSThread *)sharedThread;

/**
 Creates a new operation with a specified URL.
 
 @param url The URL to request.
 @returns An operation.
 */
- (instancetype)initWithURL:(NSURL *)url;

@end
