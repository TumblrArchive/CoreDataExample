#import "JXHTTPFormEncodedBody.h"
#import "JXURLEncoding.h"

@interface JXHTTPFormEncodedBody ()
@property (strong, nonatomic) NSMutableDictionary *dictionary;
@end

@implementation JXHTTPFormEncodedBody

#pragma mark - Initialization

- (instancetype)init
{
    if (self = [super init]) {
        self.dictionary = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [self init]) {
        self.dictionary = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
    }
    return self;
}

+ (instancetype)withDictionary:(NSDictionary *)dictionary
{
    return [[self alloc] initWithDictionary:dictionary];
}

#pragma mark - Private Methods

- (NSData *)requestData
{
    return [[JXURLEncoding formEncodedDictionary:self.dictionary] dataUsingEncoding:NSUTF8StringEncoding];
}

#pragma mark - <JXHTTPRequestBody>

- (NSInputStream *)httpInputStream
{
    return [[NSInputStream alloc] initWithData:[self requestData]];
}

- (NSString *)httpContentType
{
    return @"application/x-www-form-urlencoded; charset=utf-8";
}

- (long long)httpContentLength
{
    return [[self requestData] length];
}

@end
