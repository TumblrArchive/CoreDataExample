#import "JXHTTPFileBody.h"
#import "JXHTTP.h"

@implementation JXHTTPFileBody

#pragma mark - Initialization

- (instancetype)initWithFilePath:(NSString *)filePath contentType:(NSString *)contentType
{
    if (self = [super init]) {
        self.filePath = filePath;
        self.httpContentType = contentType;
    }
    return self;
}

+ (instancetype)withFilePath:(NSString *)filePath contentType:(NSString *)contentType
{
    return [[self alloc] initWithFilePath:filePath contentType:contentType];
}

+ (instancetype)withFilePath:(NSString *)filePath
{
    return [self withFilePath:filePath contentType:nil];
}

#pragma mark - <JXHTTPRequestBody>

- (NSInputStream *)httpInputStream
{
    return [[NSInputStream alloc] initWithFileAtPath:self.filePath];
}

- (long long)httpContentLength
{
    if (![self.filePath length])
        return NSURLResponseUnknownLength;

    NSError *error = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:&error];
    JXError(error);

    NSNumber *fileSize = [attributes objectForKey:NSFileSize];
    if (fileSize)
        return [fileSize longLongValue];

    return NSURLResponseUnknownLength;
}

@end
