#import "JXOperation.h"

@interface JXOperation ()

@property (assign) BOOL isExecuting;
@property (assign) BOOL isFinished;

#if OS_OBJECT_USE_OBJC
@property (strong) dispatch_queue_t stateQueue;
#else
@property (assign) dispatch_queue_t stateQueue;
#endif

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_0
@property (assign) UIBackgroundTaskIdentifier backgroundTaskID;
#endif

@end

@implementation JXOperation

#pragma mark - Initialization

- (void)dealloc
{
    [self endAppBackgroundTask];
    
    #if !OS_OBJECT_USE_OBJC
    dispatch_release(_stateQueue);
    _stateQueue = NULL;
    #endif
}

- (instancetype)init
{
    if (self = [super init]) {
        NSString *queueName = [[NSString alloc] initWithFormat:@"%@.%p.state", NSStringFromClass([self class]), self];
        self.stateQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);

        self.isExecuting = NO;
        self.isFinished = NO;
        self.continuesInAppBackground = NO;
        
        #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_0
        self.backgroundTaskID = UIBackgroundTaskInvalid;
        #endif
    }
    return self;
}

+ (instancetype)operation
{
    return [[self alloc] init];
}

#pragma mark - NSOperation

- (void)start
{
    __block BOOL shouldStart = YES;
    
    dispatch_sync(self.stateQueue, ^{
        if (![self isReady] || [self isCancelled] || self.isExecuting || self.isFinished) {
            shouldStart = NO;
        } else {
            [self willChangeValueForKey:@"isExecuting"];
            self.isExecuting = YES;
            [self didChangeValueForKey:@"isExecuting"];
            
            if (self.continuesInAppBackground)
                [self startAppBackgroundTask];
        }
    });
    
    if (!shouldStart || [self isCancelled])
        return;

    @autoreleasepool {
        [self main];
    }
}

- (void)main
{
    NSAssert(NO, @"subclasses must implement and eventually call finish", nil);
}

#pragma mark - Public Methods

- (BOOL)isConcurrent
{
    return YES;
}

- (void)cancel
{
    [super cancel];

    [self finish];
}

- (void)willFinish
{
    [self endAppBackgroundTask];
}

- (void)finish
{
    dispatch_sync(self.stateQueue, ^{
        if (self.isFinished)
            return;

        [self willFinish];

        if (self.isExecuting) {
            [self willChangeValueForKey:@"isExecuting"];
            [self willChangeValueForKey:@"isFinished"];
            self.isExecuting = NO;
            self.isFinished = YES;
            [self didChangeValueForKey:@"isExecuting"];
            [self didChangeValueForKey:@"isFinished"];
        } else if (!self.isFinished) {
            self.isExecuting = NO;
            self.isFinished = YES;
        }
    });
}

- (void)startAndWaitUntilFinished
{
    NSOperationQueue *tempQueue = [[NSOperationQueue alloc] init];
    [tempQueue addOperation:self];
    [tempQueue waitUntilAllOperationsAreFinished];
}

#pragma mark - Private Methods

- (void)startAppBackgroundTask
{
    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_0
    
    if (self.backgroundTaskID != UIBackgroundTaskInvalid || [self isCancelled])
        return;
    
    __weak __typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        __typeof(weakSelf) strongSelf = weakSelf;

        if (!strongSelf || [strongSelf isCancelled] || strongSelf.isFinished)
            return;

        UIBackgroundTaskIdentifier taskID = UIBackgroundTaskInvalid;
        taskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:taskID];
        }];

        strongSelf.backgroundTaskID = taskID;
    });

    #endif
}

- (void)endAppBackgroundTask
{
    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_0
    
    UIBackgroundTaskIdentifier taskID = self.backgroundTaskID;
    if (taskID == UIBackgroundTaskInvalid)
        return;
    
    self.backgroundTaskID = UIBackgroundTaskInvalid;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] endBackgroundTask:taskID];
    });

    #endif
}

@end
