/**
 `JXOperation` is an abstract `NSOperation` subclass that implements all the
 methods necessary for what Apple calls "concurrent" operations. See the sections
 titled _Subclassing Notes_ and _Multicore Considerations_ in the `NSOperation`
 class reference, this class does all of it for you.
 
 The main advantage of concurrent operations is that they allow for the use of
 asynchronous APIs. Normally, when the `main` method of an `NSOperation` exits,
 the operation marks itself as finished and deallocation is imminent. In a
 concurrent operation, nothing happens when `main` exits and it's up to you to
 manually report that the operation has finished (via KVO). In the meantime you
 can wait for delegate callbacks or any other asynchronous event.
 
 Unfortunately, `NSOperation` has some quirks and ensuring thread safety as
 the operation changes state can be tricky. `JXOperation` makes it easier by
 providing a simple <finish> method that can be called at any time from any
 thread, without worrying about the operation's current state.
 
 Heavily inspired by Dave Dribin, and building on his work detailed here:

 <http://dribin.org/dave/blog/archives/2009/05/05/concurrent_operations>

 <http://dribin.org/dave/blog/archives/2009/09/13/snowy_concurrent_operations>
 */

@interface JXOperation : NSOperation

/// @name Operation State

/**
 `YES` while the operation is executing, otherwise `NO`.
 
 Safe to access from any thread at any time.
 */
@property (assign, readonly) BOOL isExecuting;

/**
 `YES` if the operation has finished, otherwise `NO`.
 
  Safe to access from any thread at any time.
 */
@property (assign, readonly) BOOL isFinished;

/**
 Upon being set to `YES`, retrieves a `UIBackgroundTaskIdentifier` to allow the
 operation to continue running when the application enters the background.
 
 Safe to access from any thread at any time.
 
 @warning Changing this property to `YES` after the operation has started will
 have no effect. Changing it to `NO` will discontinue background execution.
 */
@property (assign) BOOL continuesInAppBackground;

/// @name Initialization

/**
 Creates a new operation.
 
 @returns An operation.
 */
+ (instancetype)operation;

/// @name Starting & Finishing

/**
 Starts the operation and blocks the calling thread until it has finished.
 */
- (void)startAndWaitUntilFinished;

/**
 Called just before the operation finishes on the same thread (including as a result of
 being cancelled). Guaranteed to be called only once. Subclasses should override this
 method (and call `super`) instead of overriding <finish>.
 
 @warning Do not call this method yourself.
 */
- (void)willFinish;

/**
 Ends the operation and marks it for removal from its queue (if applicable).
 Subclasses must eventually call this method to cause the operation to finish,
 typically after the work performed in `main` is complete.
 
 This method is safe to call multiple times from any thread at any time, including
 before the operation has started.
 
 @warning To ensure thread saftey, do not override this method (use <willFinish>
 instead). After the operation has finished do not attempt to access any of its
 properties as it may have been released by a queue or other retaining object from a
 different thread.
 */
- (void)finish;

@end
