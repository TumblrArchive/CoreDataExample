#import "JXURLConnectionOperation.h"

@interface JXURLConnectionOperation ()
@property (strong) NSURLConnection *connection;
@property (strong) NSMutableURLRequest *request;
@property (strong) NSURLResponse *response;
@property (strong) NSError *error;
@property (assign) long long bytesDownloaded;
@property (assign) long long bytesUploaded;
@end

@implementation JXURLConnectionOperation

#pragma mark - Initialization

- (void)dealloc
{
    [self stopConnection];
}

- (instancetype)init
{
    if (self = [super init]) {
        self.connection = nil;
        self.request = nil;
        self.response = nil;
        self.error = nil;
        self.outputStream = nil;

        self.bytesDownloaded = 0LL;
        self.bytesUploaded = 0LL;
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url
{
    if (self = [self init]) {
        self.request = [[NSMutableURLRequest alloc] initWithURL:url];
    }
    return self;
}

#pragma mark - NSOperation

- (void)main
{
    if ([self isCancelled])
        return;
    
    [self startConnection];
}

- (void)willFinish
{
    [super willFinish];

    [self stopConnection];
}

#pragma mark - Scheduling

- (void)startConnection
{
    if ([NSThread currentThread] != [[self class] sharedThread]) {
        [self performSelector:@selector(startConnection) onThread:[[self class] sharedThread] withObject:nil waitUntilDone:YES];
        return;
    }
    
    if ([self isCancelled])
        return;
    
    if (!self.outputStream)
        self.outputStream = [[NSOutputStream alloc] initToMemory];

    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];

    self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
    [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.connection start];
}

- (void)stopConnection
{
    if ([NSThread currentThread] != [[self class] sharedThread]) {
        [self performSelector:@selector(stopConnection) onThread:[[self class] sharedThread] withObject:nil waitUntilDone:YES];
        return;
    }

    [self.connection unscheduleFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.connection cancel];

    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.outputStream close];
}

+ (NSThread *)sharedThread
{
    static NSThread *thread = nil;
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        thread = [[NSThread alloc] initWithTarget:self selector:@selector(runLoopForever) object:nil];
        [thread start];
    });
    
    return thread;
}

+ (void)runLoopForever
{
    [[NSThread currentThread] setName:@"JXHTTP"];

    while (YES) {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    }
}

#pragma mark - <NSURLConnectionDelegate>

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if ([self isCancelled])
        return;
    
    self.error = error;
    
    [self finish];
}

#pragma mark - <NSURLConnectionDataDelegate>

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)urlResponse
{
    if ([self isCancelled])
        return;

    self.response = urlResponse;
    
    [self.outputStream open];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if ([self isCancelled])
        return;
    
    if ([self.outputStream hasSpaceAvailable]) {
        NSInteger bytesWritten = [self.outputStream write:[data bytes] maxLength:[data length]];
        
        if (bytesWritten != -1)
            self.bytesDownloaded += bytesWritten;
    }
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytes totalBytesWritten:(NSInteger)total totalBytesExpectedToWrite:(NSInteger)expected
{
    if ([self isCancelled])
        return;
    
    self.bytesUploaded += bytes;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if ([self isCancelled])
        return;

    [self finish];
}

@end
