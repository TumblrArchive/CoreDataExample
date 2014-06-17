/**
 `JXHTTPOperationQueueDelegate` is a protocol that allows any object to receive synchronous
 callbacks about the progress of a `JXHTTPOperationQueue`.

 These methods may be called from different threads.
 */

@class JXHTTPOperationQueue;

@protocol JXHTTPOperationQueueDelegate <NSObject>
@optional

/**
 Called when the queue adds an operation from an empty state.
 
 @param queue The queue.
 */
- (void)httpOperationQueueWillStart:(JXHTTPOperationQueue *)queue;

/**
 Called when the queue has completed all operations.
 
 @param queue The queue.
 */
- (void)httpOperationQueueWillFinish:(JXHTTPOperationQueue *)queue;

/**
 Called just after the first operation is added to the queue.
 
 @param queue The queue.
 */
- (void)httpOperationQueueDidStart:(JXHTTPOperationQueue *)queue;

/**
 Called periodically as operations in the queue upload data.

 @param queue The queue.
 */
- (void)httpOperationQueueDidUpload:(JXHTTPOperationQueue *)queue;

/**
 Called periodically as operations in the queue download data.

 @param queue The queue.
 */
- (void)httpOperationQueueDidDownload:(JXHTTPOperationQueue *)queue;

/**
 Called periodically as operations in the queue download or upload data.

 @param queue The queue.
 */
- (void)httpOperationQueueDidMakeProgress:(JXHTTPOperationQueue *)queue;

/**
 Called when the last operation in the queue finishes.

 @param queue The queue.
 */
- (void)httpOperationQueueDidFinish:(JXHTTPOperationQueue *)queue;
@end
