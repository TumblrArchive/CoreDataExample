/**
 `JXHTTPOperationQueue` is an `NSOperationQueue` subclass and can be used to group
 multiple instances of <JXHTTPOperation> for progress tracking, timing, or cancellation.
 It provides blocks and delegate methods via the <JXHTTPOperationQueueDelegate> protocol.
 
 Any `NSOperation` subclass can be safely added to this queue; classes other than
 <JXHTTPOperation> receive no special treatment.
 
 Progress and byte count properties are reset every time a new operation is added when
 the queue is empty.
 
 ## Example ##
 
     JXHTTPOperationQueue *queue = [[JXHTTPOperationQueue alloc] init];
 
     queue.didFinishBlock = ^(JXHTTPOperationQueue *queue) {
         NSLog(@"queue finished at %@", queue.finishDate);
         NSLog(@"total bytes downloaded: %@", queue.bytesDownloaded);
     };
 
    for (NSUInteger i = 0; i < 10; i++) {
        JXHTTPOperation *op = [JXHTTPOperation withURLString:@"http://jxhttp.com/"];

        op.didFinishLoadingBlock = ^(JXHTTPOperation *op) {
            NSLog(@"operation %d finished loading at %@", i, op.finishDate);
        };
 
        [queue addOperation:op];
    }
 */

#import "JXHTTPOperationQueueDelegate.h"

typedef void (^JXHTTPQueueBlock)(JXHTTPOperationQueue *queue);

@interface JXHTTPOperationQueue : NSOperationQueue

/// @name Core

/**
 The operation's delegate, conforming to <JXHTTPOperationDelegate>.
 
 Safe to access from any thread at any time.
 */
@property (weak) NSObject <JXHTTPOperationQueueDelegate> *delegate;

/**
 A string guaranteed to be unique for the lifetime of the application process.

 Safe to access from any thread at any time.
 */
@property (strong, readonly) NSString *uniqueString;

/// @name Progress

/**
 A number between 0 and 1 representing the percentage of download progress.
 
 Safe to access from any thread at any time.
 */
@property (strong, readonly) NSNumber *downloadProgress;

/**
 A number between 0 and 1 representing the percentage of upload progress.

 Safe to access from any thread at any time.
 */
@property (strong, readonly) NSNumber *uploadProgress;

/**
 The total number of bytes downloaded.

 Safe to access from any thread at any time.
 */
@property (strong, readonly) NSNumber *bytesDownloaded;

/**
 The total number of bytes uploaded.

 Safe to access from any thread at any time.
 */
@property (strong, readonly) NSNumber *bytesUploaded;

/**
 The total number of bytes expected to be downloaded.

 Safe to access from any thread at any time.
 */
@property (strong, readonly) NSNumber *expectedDownloadBytes;

/**
 The total number of bytes expected to be uploaded.

 Safe to access from any thread at any time.
 */
@property (strong, readonly) NSNumber *expectedUploadBytes;

/// @name Timing

/**
 The date the request started.

 Safe to access from any thread at any time.
 */
@property (strong, readonly) NSDate *startDate;

/**
 The date the request finished (or failed).

 Safe to access from any thread at any time.
 */
@property (strong, readonly) NSDate *finishDate;

/**
 The number of seconds elapsed between the <startDate> and the <finishDate> (or the
 current date if the request is still running). `0.0` if the request has not started.

 Safe to access from any thread at any time.
 */
@property (readonly) NSTimeInterval elapsedSeconds;

/// @name Blocks

@property (assign) BOOL performsBlocksOnMainQueue;
@property (copy) JXHTTPQueueBlock willStartBlock;
@property (copy) JXHTTPQueueBlock willFinishBlock;
@property (copy) JXHTTPQueueBlock didStartBlock;
@property (copy) JXHTTPQueueBlock didUploadBlock;
@property (copy) JXHTTPQueueBlock didDownloadBlock;
@property (copy) JXHTTPQueueBlock didMakeProgressBlock;
@property (copy) JXHTTPQueueBlock didFinishBlock;

/**
 A singleton queue with a default `maxConcurrentOperationCount` of `4`.

 @returns The shared HTTP operation queue.
 */
+ (instancetype)sharedQueue;

@end
