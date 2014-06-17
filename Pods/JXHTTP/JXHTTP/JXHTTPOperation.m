#import "JXHTTPOperation.h"
#import "JXURLEncoding.h"

static NSUInteger JXHTTPOperationCount = 0;
static NSTimer * JXHTTPActivityTimer = nil;
static NSTimeInterval JXHTTPActivityTimerInterval = 0.25;

@interface JXHTTPOperation ()
@property (assign) BOOL didIncrementCount;
@property (strong) NSURLAuthenticationChallenge *authenticationChallenge;
@property (strong) NSNumber *downloadProgress;
@property (strong) NSNumber *uploadProgress;
@property (strong) NSString *uniqueString;
@property (strong) NSDate *startDate;
@property (strong) NSDate *finishDate;
@property (assign) dispatch_once_t incrementCountOnce;
@property (assign) dispatch_once_t decrementCountOnce;
#if OS_OBJECT_USE_OBJC
@property (strong) dispatch_queue_t blockQueue;
#else
@property (assign) dispatch_queue_t blockQueue;
#endif
@end

@implementation JXHTTPOperation

#pragma mark - Initialization

- (void)dealloc
{
    [self decrementOperationCount];

    #if !OS_OBJECT_USE_OBJC
    dispatch_release(_blockQueue);
    _blockQueue = NULL;
    #endif
}

- (instancetype)init
{
    if (self = [super init]) {
        NSString *queueName = [[NSString alloc] initWithFormat:@"%@.%p.blocks", NSStringFromClass([self class]), self];
        self.blockQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);

        self.uniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
        self.downloadProgress = @0.0f;
        self.uploadProgress = @0.0f;
        self.performsBlocksOnMainQueue = NO;
        self.updatesNetworkActivityIndicator = YES;
        self.authenticationChallenge = nil;
        self.responseDataFilePath = nil;
        self.credential = nil;
        self.userObject = nil;
        self.didIncrementCount = NO;
        self.useCredentialStorage = YES;
        self.trustedHosts = nil;
        self.trustAllHosts = NO;
        self.username = nil;
        self.password = nil;
        self.startDate = nil;
        self.finishDate = nil;

        self.willStartBlock = nil;
        self.willNeedNewBodyStreamBlock = nil;
        self.willSendRequestForAuthenticationChallengeBlock = nil;
        self.willSendRequestRedirectBlock = nil;
        self.willCacheResponseBlock = nil;
        self.didStartBlock = nil;
        self.didReceiveResponseBlock = nil;
        self.didReceiveDataBlock = nil;
        self.didSendDataBlock = nil;
        self.didFinishLoadingBlock = nil;
        self.didFailBlock = nil;
    }
    return self;
}

+ (instancetype)withURLString:(NSString *)urlString
{
    return [[self alloc] initWithURL:[[NSURL alloc] initWithString:urlString]];
}

+ (instancetype)withURLString:(NSString *)urlString queryParameters:(NSDictionary *)parameters
{
    NSString *string = urlString;

    if (parameters)
        string = [string stringByAppendingFormat:@"?%@", [JXURLEncoding encodedDictionary:parameters]];

    return [self withURLString:string];
}

#pragma mark - Private Methods

- (void)performDelegateMethod:(SEL)selector
{
    if ([self isCancelled])
        return;
    
    if ([self.delegate respondsToSelector:selector])
        [self.delegate performSelector:selector onThread:[NSThread currentThread] withObject:self waitUntilDone:YES];

    if ([self.requestBody respondsToSelector:selector])
        [self.requestBody performSelector:selector onThread:[NSThread currentThread] withObject:self waitUntilDone:YES];

    JXHTTPBlock block = [self blockForSelector:selector];

    if ([self isCancelled] || !block)
        return;

    dispatch_async(self.performsBlocksOnMainQueue ? dispatch_get_main_queue() : self.blockQueue, ^{
        if (![self isCancelled])
            block(self);
    });
}

- (JXHTTPBlock)blockForSelector:(SEL)selector
{
    if (selector == @selector(httpOperationWillStart:))
        return self.willStartBlock;
    if (selector == @selector(httpOperationWillNeedNewBodyStream:))
        return self.willNeedNewBodyStreamBlock;
    if (selector == @selector(httpOperationWillSendRequestForAuthenticationChallenge:))
        return self.willSendRequestForAuthenticationChallengeBlock;
    if (selector == @selector(httpOperationDidStart:))
        return self.didStartBlock;
    if (selector == @selector(httpOperationDidReceiveResponse:))
        return self.didReceiveResponseBlock;
    if (selector == @selector(httpOperationDidReceiveData:))
        return self.didReceiveDataBlock;
    if (selector == @selector(httpOperationDidSendData:))
        return self.didSendDataBlock;
    if (selector == @selector(httpOperationDidFinishLoading:))
        return self.didFinishLoadingBlock;
    if (selector == @selector(httpOperationDidFail:))
        return self.didFailBlock;
    return nil;
}

#pragma mark - Operation Count

- (void)incrementOperationCount
{
    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_2_0
    
    dispatch_once(&_incrementCountOnce, ^{
        if (!self.updatesNetworkActivityIndicator)
            return;

        dispatch_async(dispatch_get_main_queue(), ^{
            ++JXHTTPOperationCount;
            [JXHTTPActivityTimer invalidate];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        });

        self.didIncrementCount = YES;
    });
    
    #endif
}

- (void)decrementOperationCount
{
    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_2_0
    
    if (!self.didIncrementCount)
        return;
    
    dispatch_once(&_decrementCountOnce, ^{
        if (!self.updatesNetworkActivityIndicator)
            return;

        dispatch_async(dispatch_get_main_queue(), ^{
            if (--JXHTTPOperationCount < 1)
                [JXHTTPOperation restartActivityTimer];
        });
    });

    #endif
}

+ (void)restartActivityTimer
{
    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_2_0
    
    JXHTTPActivityTimer = [NSTimer timerWithTimeInterval:JXHTTPActivityTimerInterval
                                                  target:self
                                                selector:@selector(networkActivityTimerDidFire:)
                                                userInfo:nil
                                                 repeats:NO];
    
    [[NSRunLoop mainRunLoop] addTimer:JXHTTPActivityTimer forMode:NSRunLoopCommonModes];

    #endif
}

+ (void)networkActivityTimerDidFire:(NSTimer *)timer
{
    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_2_0

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    #endif
}

#pragma mark - Accessors

- (void)setResponseDataFilePath:(NSString *)filePath
{
    if ([self isCancelled] || self.isExecuting || self.isFinished)
        return;

    _responseDataFilePath = [filePath copy];

    if ([self.responseDataFilePath length]) {
        self.outputStream = [NSOutputStream outputStreamToFileAtPath:self.responseDataFilePath append:NO];
    } else {
        self.outputStream = nil;
    }
}

- (NSTimeInterval)elapsedSeconds
{
    if (self.startDate) {
        NSDate *endDate = self.finishDate ? self.finishDate : [[NSDate alloc] init];
        return [endDate timeIntervalSinceDate:self.startDate];
    } else {
        return 0.0;
    }
}

#pragma mark - JXOperation

- (void)main
{
    if ([self isCancelled])
        return;

    [self performDelegateMethod:@selector(httpOperationWillStart:)];

    [self incrementOperationCount];

    if (self.requestBody) {
        NSInputStream *inputStream = [self.requestBody httpInputStream];
        if (inputStream)
            self.request.HTTPBodyStream = inputStream;

        if ([[[self.request HTTPMethod] uppercaseString] isEqualToString:@"GET"])
            [self.request setHTTPMethod:@"POST"];

        NSString *contentType = [self.requestBody httpContentType];
        if (![contentType length])
            contentType = @"application/octet-stream";

        if (![self.request valueForHTTPHeaderField:@"Content-Type"])
            [self.request setValue:contentType forHTTPHeaderField:@"Content-Type"];

        if (![self.request valueForHTTPHeaderField:@"User-Agent"])
            [self.request setValue:@"JXHTTP" forHTTPHeaderField:@"User-Agent"];

        long long expectedLength = [self.requestBody httpContentLength];
        if (expectedLength > 0LL && expectedLength != NSURLResponseUnknownLength)
            [self.request setValue:[[NSString alloc] initWithFormat:@"%lld", expectedLength] forHTTPHeaderField:@"Content-Length"];
    }

    self.startDate = [[NSDate alloc] init];

    [super main];
    
    [self performDelegateMethod:@selector(httpOperationDidStart:)];
}

- (void)willFinish
{
    [super willFinish];

    [self decrementOperationCount];
}

#pragma mark - <NSURLConnectionDelegate>

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [super connection:connection didFailWithError:error];

    if ([self isCancelled])
        return;

    self.finishDate = [[NSDate alloc] init];

    [self performDelegateMethod:@selector(httpOperationDidFail:)];
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    return self.useCredentialStorage;
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([self isCancelled]) {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
        return;
    }

    self.authenticationChallenge = challenge;

    [self performDelegateMethod:@selector(httpOperationWillSendRequestForAuthenticationChallenge:)];

    if (!self.credential && self.authenticationChallenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
        BOOL trusted = NO;

        if (self.trustAllHosts) {
            trusted = YES;
        } else if (self.trustedHosts) {
            for (NSString *host in self.trustedHosts) {
                if ([host isEqualToString:self.authenticationChallenge.protectionSpace.host]) {
                    trusted = YES;
                    break;
                }
            }
        }

        if (trusted)
            self.credential = [NSURLCredential credentialForTrust:self.authenticationChallenge.protectionSpace.serverTrust];
    }

    if (!self.credential && self.username && self.password)
        self.credential = [NSURLCredential credentialWithUser:self.username password:self.password persistence:NSURLCredentialPersistenceForSession];

    if (self.credential) {
        [[self.authenticationChallenge sender] useCredential:self.credential forAuthenticationChallenge:self.authenticationChallenge];
        return;
    }

    [[self.authenticationChallenge sender] continueWithoutCredentialForAuthenticationChallenge:self.authenticationChallenge];
}

#pragma mark - <NSURLConnectionDataDelegate>

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)urlResponse
{
    [super connection:connection didReceiveResponse:urlResponse];

    if ([self isCancelled])
        return;

    [self performDelegateMethod:@selector(httpOperationDidReceiveResponse:)];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [super connection:connection didReceiveData:data];

    if ([self isCancelled])
        return;

    long long bytesExpected = [self.response expectedContentLength];
    if (bytesExpected > 0LL && bytesExpected != NSURLResponseUnknownLength)
        self.downloadProgress = @(self.bytesDownloaded / (float)bytesExpected);

    [self performDelegateMethod:@selector(httpOperationDidReceiveData:)];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [super connectionDidFinishLoading:connection];
    
    if ([self isCancelled])
        return;

    if ([self.downloadProgress floatValue] != 1.0f)
        self.downloadProgress = @1.0f;

    if ([self.uploadProgress floatValue] != 1.0f)
        self.uploadProgress = @1.0f;

    self.finishDate = [[NSDate alloc] init];

    [self performDelegateMethod:@selector(httpOperationDidFinishLoading:)];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytes totalBytesWritten:(NSInteger)bytesSent totalBytesExpectedToWrite:(NSInteger)bytesExpected
{
    [super connection:connection didSendBodyData:bytes totalBytesWritten:bytesSent totalBytesExpectedToWrite:bytesExpected];

    if ([self isCancelled])
        return;

    if (bytesExpected > 0LL && bytesExpected != NSURLResponseUnknownLength)
        self.uploadProgress = @(bytesSent / (float)bytesExpected);

    [self performDelegateMethod:@selector(httpOperationDidSendData:)];
}

- (NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request
{
    if ([self isCancelled])
        return nil;

    [self performDelegateMethod:@selector(httpOperationWillNeedNewBodyStream:)];

    return [self.requestBody httpInputStream];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    if ([self isCancelled])
        return nil;

    BOOL delegateResponds = [self.delegate respondsToSelector:@selector(httpOperation:willCacheResponse:)];
    BOOL requestBodyResponds = [self.requestBody respondsToSelector:@selector(httpOperation:willCacheResponse:)];

    if (!delegateResponds && !requestBodyResponds && !self.willCacheResponseBlock)
        return cachedResponse;

    __block NSCachedURLResponse *modifiedReponse = nil;

    if ([self.delegate respondsToSelector:@selector(httpOperation:willCacheResponse:)])
        modifiedReponse = [self.delegate httpOperation:self willCacheResponse:cachedResponse];

    if ([self.requestBody respondsToSelector:@selector(httpOperation:willCacheResponse:)])
        modifiedReponse = [self.requestBody httpOperation:self willCacheResponse:cachedResponse];

    if (self.willCacheResponseBlock) {
        dispatch_sync(self.performsBlocksOnMainQueue ? dispatch_get_main_queue() : self.blockQueue, ^{
            modifiedReponse = self.willCacheResponseBlock(self, cachedResponse);
        });
    }

    return [self isCancelled] ? nil : modifiedReponse;
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
    if ([self isCancelled])
        return nil;

    BOOL delegateResponds = [self.delegate respondsToSelector:@selector(httpOperation:willSendRequest:redirectResponse:)];
    BOOL requestBodyResponds = [self.requestBody respondsToSelector:@selector(httpOperation:willSendRequest:redirectResponse:)];

    if (!delegateResponds && !requestBodyResponds && !self.willSendRequestRedirectBlock)
        return request;

    __block NSURLRequest *modifiedRequest = nil;

    if (delegateResponds)
        modifiedRequest = [self.delegate httpOperation:self willSendRequest:request redirectResponse:redirectResponse];

    if (requestBodyResponds)
        modifiedRequest = [self.requestBody httpOperation:self willSendRequest:request redirectResponse:redirectResponse];

    if (self.willSendRequestRedirectBlock) {
        dispatch_sync(self.performsBlocksOnMainQueue ? dispatch_get_main_queue() : self.blockQueue, ^{
            modifiedRequest = self.willSendRequestRedirectBlock(self, request, redirectResponse);
        });
    }

    if (!modifiedRequest && !redirectResponse)
        [self cancel];

    return [self isCancelled] ? nil : modifiedRequest;
}

@end
