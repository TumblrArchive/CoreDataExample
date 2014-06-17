#import "JXHTTPMultipartBody.h"
#import "JXHTTPOperation.h"
#import "JXHTTP.h"

typedef enum {
    JXHTTPMultipartData,
    JXHTTPMultipartFile    
} JXHTTPMultipartPartType;

@interface JXHTTPMultipartPart : NSObject
@property (assign, nonatomic) JXHTTPMultipartPartType multipartType;
@property (strong, nonatomic) NSString *key;
@property (strong, nonatomic) NSData *preData;
@property (strong, nonatomic) NSData *contentData;
@property (strong, nonatomic) NSData *postData;
@end

@implementation JXHTTPMultipartPart

+ (instancetype)withMultipartType:(JXHTTPMultipartPartType)type
                    key:(NSString *)key
                   data:(NSData *)data
            contentType:(NSString *)contentTypeOrNil
               fileName:(NSString *)fileNameOrNil
               boundary:(NSString *)boundaryString
{
    JXHTTPMultipartPart *part = [[JXHTTPMultipartPart alloc] init];
    part.multipartType = type;    
    part.key = key;
    
    NSMutableString *preString = [[NSMutableString alloc] initWithFormat:@"%@\r\n", boundaryString];
    [preString appendFormat:@"Content-Disposition: form-data; name=\"%@\"", key];
    
    if ([fileNameOrNil length])
        [preString appendFormat:@"; filename=\"%@\"", fileNameOrNil];
    
    if ([contentTypeOrNil length]) {
        [preString appendFormat:@"\r\nContent-Type: %@", contentTypeOrNil];
    } else if(part.multipartType == JXHTTPMultipartFile) {
        [preString appendString:@"\r\nContent-Type: application/octet-stream"];
    }
    
    [preString appendString:@"\r\n\r\n"];
    
    part.preData = [preString dataUsingEncoding:NSUTF8StringEncoding];
    part.contentData = data;
    part.postData = [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding];    
    
    return part;
}

- (NSString *)filePath
{
    if (self.multipartType == JXHTTPMultipartFile)
        return [[NSString alloc] initWithData:self.contentData encoding:NSUTF8StringEncoding];
    
    return nil;
}

- (long long)dataLength
{
    long long length = 0LL;
    length += [self.preData length];
    length += [self contentLength];
    length += [self.postData length];
    return length;
}

- (long long)contentLength
{
    long long length = 0LL;
    
    if (self.multipartType == JXHTTPMultipartData) {
        length += [self.contentData length];
    } else if (self.multipartType == JXHTTPMultipartFile) {
        NSError *error = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[self filePath] error:&error];
        JXError(error);
        
        NSNumber *fileSize = [attributes objectForKey:NSFileSize];
        if (fileSize)
            length += [fileSize longLongValue];
    }
    
    return length;
}

- (NSUInteger)loadMutableData:(NSMutableData *)mutableData withDataInRange:(NSRange)searchRange
{
    NSUInteger dataOffset = 0;
    NSUInteger bytesAppended = 0;
    
    for (NSData *data in @[self.preData, self.contentData, self.postData]) {
        NSUInteger dataLength = data == self.contentData ? [self contentLength] : [data length];
        NSRange dataRange = NSMakeRange(dataOffset, dataLength);
        NSRange intersection = NSIntersectionRange(dataRange, searchRange);
        
        if (intersection.length > 0) {
            NSRange rangeInPart = NSMakeRange(intersection.location - dataOffset, intersection.length);
            NSData *dataToAppend = nil;
            
            if (data == self.preData || data == self.postData) {
                dataToAppend = [data subdataWithRange:rangeInPart];
            } else if (data == self.contentData) {
                if (self.multipartType == JXHTTPMultipartData) {
                    dataToAppend = [data subdataWithRange:rangeInPart];
                } else if (self.multipartType == JXHTTPMultipartFile) {
                    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:[self filePath]];
                    if (!fileHandle)
                        return bytesAppended;
                    
                    [fileHandle seekToFileOffset:rangeInPart.location];
                    dataToAppend = [fileHandle readDataOfLength:rangeInPart.length];
                    [fileHandle closeFile];
                }
            }
            
            if (dataToAppend) {
                [mutableData appendData:dataToAppend];
                bytesAppended += [dataToAppend length];
            }
        }
        
        dataOffset += dataLength;
    }
    
    return bytesAppended;
}

@end

#pragma mark - JXHTTPMultiPartBody

@interface JXHTTPMultipartBody ()
@property (strong, nonatomic) NSMutableArray *partsArray;
@property (strong, nonatomic) NSString *boundaryString;
@property (strong, nonatomic) NSData *finalBoundaryData;
@property (strong, nonatomic) NSString *httpContentType;
@property (strong, nonatomic) NSInputStream *httpInputStream;
@property (strong, nonatomic) NSOutputStream *httpOutputStream;
@property (strong, nonatomic) NSMutableData *bodyDataBuffer;
@property (assign, nonatomic) long long httpContentLength;
@property (assign, nonatomic) long long bytesWritten;
@end

@implementation JXHTTPMultipartBody

#pragma mark - Initialization

- (void)dealloc
{
    self.httpOutputStream.delegate = nil;
    [self.httpOutputStream close];
}

- (instancetype)init
{
    if (self = [super init]) {
        NSString *dateString = [[NSString alloc] initWithFormat:@"%.0f", [[[NSDate alloc] init] timeIntervalSince1970]];
        NSString *plainBoundaryString = [[NSString alloc] initWithFormat:@"JXHTTP-%@-%@", [[NSProcessInfo processInfo] globallyUniqueString], dateString];

        self.boundaryString = [[NSString alloc] initWithFormat:@"--%@", plainBoundaryString];
        self.finalBoundaryData = [[[NSString alloc] initWithFormat:@"--%@--\r\n", plainBoundaryString] dataUsingEncoding:NSUTF8StringEncoding];
        self.httpContentType = [[NSString alloc] initWithFormat:@"multipart/form-data; charset=utf-8; boundary=%@", plainBoundaryString];
        self.partsArray = [[NSMutableArray alloc] init];
        self.streamBufferLength = 0x10000; // 64K
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)stringParameters
{
    if (self = [self init]) {
        for (NSString *key in [stringParameters allKeys]) {
            [self addString:[stringParameters objectForKey:key] forKey:key];
        }
    }
    return self;
}

+ (instancetype)withDictionary:(NSDictionary *)stringParameters
{
    return [[self alloc] initWithDictionary:stringParameters];
}

#pragma mark - <JXHTTPRequestBody>

- (long long)httpContentLength
{
    if (_httpContentLength != NSURLResponseUnknownLength)
        return _httpContentLength;
    
    long long newLength = 0LL;
    
    for (JXHTTPMultipartPart *part in self.partsArray) {
        newLength += [part dataLength];
    }
    
    if (newLength > 0LL)
        newLength += [self.finalBoundaryData length];
    
    self.httpContentLength = newLength;
    
    return _httpContentLength;
}

#pragma mark - <JXHTTPOperationDelegate>

- (void)httpOperationWillNeedNewBodyStream:(JXHTTPOperation *)operation
{
    [self recreateStreams];
}

- (void)httpOperationWillStart:(JXHTTPOperation *)operation
{
    [self recreateStreams];
}

- (void)httpOperationDidFinishLoading:(JXHTTPOperation *)operation
{
    [self.httpOutputStream close];
}

- (void)httpOperationDidFail:(JXHTTPOperation *)operation
{
    [self.httpOutputStream close];
}

#pragma mark - Private Methods

- (void)recreateStreams
{
    self.bodyDataBuffer = [[NSMutableData alloc] initWithCapacity:self.streamBufferLength];
    self.httpContentLength = NSURLResponseUnknownLength;
    self.bytesWritten = 0LL;
    
    self.httpOutputStream.delegate = nil;
    [self.httpOutputStream close];
    
    self.httpInputStream = nil;
    self.httpOutputStream = nil;
    
    CFReadStreamRef readStream = NULL;
    CFWriteStreamRef writeStream = NULL;
    CFStreamCreateBoundPair(kCFAllocatorDefault, &readStream, &writeStream, (CFIndex)self.streamBufferLength);
    
    if (readStream != NULL && writeStream != NULL) {
        self.httpInputStream = (__bridge_transfer NSInputStream *)readStream;
        self.httpOutputStream = (__bridge_transfer NSOutputStream *)writeStream;
        
        self.httpOutputStream.delegate = self;
        [self scheduleOutputStreamOnThread:[JXHTTPOperation sharedThread]];
        [self.httpOutputStream open];

        readStream = NULL;
        writeStream = NULL;
    }
    
    if (readStream != NULL)
        CFRelease(readStream);
    if (writeStream != NULL)
        CFRelease(writeStream);
}

- (void)scheduleOutputStreamOnThread:(NSThread *)thread
{
    if (thread && thread != [NSThread currentThread]) {
        [self performSelector:@selector(scheduleOutputStreamOnThread:) onThread:thread withObject:nil waitUntilDone:YES];
        return;
    }

    self.httpOutputStream.delegate = self;
    [self.httpOutputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.httpOutputStream open];
}


- (void)setPartWithType:(JXHTTPMultipartPartType)type forKey:(NSString *)key contentType:(NSString *)contentTypeOrNil fileName:(NSString *)fileNameOrNil data:(NSData *)data
{
    NSMutableArray *removal = [[NSMutableArray alloc] initWithCapacity:[self.partsArray count]];
    for (JXHTTPMultipartPart *part in self.partsArray) {
        if ([part.key isEqualToString:key])
            [removal addObject:part];
    }
    
    [self.partsArray removeObjectsInArray:removal];
    
    [self addPartWithType:type forKey:key contentType:contentTypeOrNil fileName:fileNameOrNil data:data];
}

- (void)addPartWithType:(JXHTTPMultipartPartType)type forKey:(NSString *)key contentType:(NSString *)contentTypeOrNil fileName:(NSString *)fileNameOrNil data:(NSData *)data
{
    JXHTTPMultipartPart *part = [JXHTTPMultipartPart withMultipartType:type key:key data:data contentType:contentTypeOrNil fileName:fileNameOrNil boundary:self.boundaryString];
    [self.partsArray addObject:part];
    
    self.httpContentLength = NSURLResponseUnknownLength;
}

#pragma mark - <NSStreamDelegate>

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
    if (stream != self.httpOutputStream)
        return;
    
    if (eventCode == NSStreamEventErrorOccurred) {
        JXError(stream.streamError);
        [self.httpOutputStream close];
        return;
    }
    
    if (eventCode != NSStreamEventHasSpaceAvailable)
        return;
    
    if (self.bytesWritten == self.httpContentLength) {
        [self.httpOutputStream close];
        return;
    }
    
    NSUInteger bytesRemaining = self.httpContentLength - self.bytesWritten;
    NSUInteger length = bytesRemaining < self.streamBufferLength ? bytesRemaining : self.streamBufferLength;
    
    NSUInteger bytesLoaded = [self loadMutableData:self.bodyDataBuffer withDataInRange:NSMakeRange(self.bytesWritten, length)];
    NSInteger bytesOutput = bytesLoaded ? [self.httpOutputStream write:[self.bodyDataBuffer bytes] maxLength:bytesLoaded] : 0;
    
    if (bytesOutput > 0) {
        self.bytesWritten += bytesOutput;
    } else {
        [self.httpOutputStream close];
    }
}

- (NSUInteger)loadMutableData:(NSMutableData *)data withDataInRange:(NSRange)searchRange
{
    [data setLength:0];
    
    NSUInteger partOffset = 0;
    NSUInteger bytesLoaded = 0;
    
    for (JXHTTPMultipartPart *part in self.partsArray) {
        NSUInteger partLength = [part dataLength];
        NSRange partRange = NSMakeRange(partOffset, partLength);
        
        NSRange intersection = NSIntersectionRange(partRange, searchRange);
        if (intersection.length > 0) {
            NSRange rangeInPart = NSMakeRange(intersection.location - partOffset, intersection.length);
            bytesLoaded += [part loadMutableData:data withDataInRange:rangeInPart];
        }
        
        partOffset += partLength;
    }
    
    NSRange finalRange = NSMakeRange(partOffset, [self.finalBoundaryData length]);
    NSRange intersection = NSIntersectionRange(finalRange, searchRange);
    
    if (intersection.length > 0) {
        NSRange range = NSMakeRange(intersection.location - partOffset, intersection.length);
        NSData *dataToAppend = [self.finalBoundaryData subdataWithRange:range];
        
        if (dataToAppend) {
            [data appendData:dataToAppend];
            bytesLoaded += [dataToAppend length];
        }
    }
    
    return bytesLoaded;
}

#pragma mark - Public Methods

- (void)addString:(NSString *)string forKey:(NSString *)key
{
    [self addData:[string dataUsingEncoding:NSUTF8StringEncoding] forKey:key contentType:@"text/plain; charset=utf-8" fileName:nil];
}

- (void)setString:(NSString *)string forKey:(NSString *)key
{
    [self setData:[string dataUsingEncoding:NSUTF8StringEncoding] forKey:key contentType:@"text/plain; charset=utf-8" fileName:nil];
}

- (void)addData:(NSData *)data forKey:(NSString *)key contentType:(NSString *)contentTypeOrNil fileName:(NSString *)fileNameOrNil
{
    [self addPartWithType:JXHTTPMultipartData forKey:key contentType:contentTypeOrNil fileName:fileNameOrNil data:data];
}

- (void)setData:(NSData *)data forKey:(NSString *)key contentType:(NSString *)contentTypeOrNil fileName:(NSString *)fileNameOrNil
{
    [self setPartWithType:JXHTTPMultipartData forKey:key contentType:contentTypeOrNil fileName:fileNameOrNil data:data];
}

- (void)addFile:(NSString *)filePath forKey:(NSString *)key contentType:(NSString *)contentTypeOrNil fileName:(NSString *)fileNameOrNil
{
    [self addPartWithType:JXHTTPMultipartFile forKey:key contentType:contentTypeOrNil fileName:fileNameOrNil data:[filePath dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)setFile:(NSString *)filePath forKey:(NSString *)key contentType:(NSString *)contentTypeOrNil fileName:(NSString *)fileNameOrNil
{
    [self setPartWithType:JXHTTPMultipartFile forKey:key contentType:contentTypeOrNil fileName:fileNameOrNil data:[filePath dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
