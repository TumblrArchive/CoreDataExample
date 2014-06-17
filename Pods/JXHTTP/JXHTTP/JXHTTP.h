#pragma HC SVNT DRACONES

// Core
#import "JXOperation.h"
#import "JXURLConnectionOperation.h"
#import "JXHTTPOperation.h"
#import "JXHTTPOperationQueue.h"

// Protocol
#import "JXHTTPRequestBody.h"
#import "JXHTTPOperationDelegate.h"
#import "JXHTTPOperationQueueDelegate.h"

// Convenience
#import "JXURLEncoding.h"
#import "JXHTTPOperation+Convenience.h"

// Request Body
#import "JXHTTPDataBody.h"
#import "JXHTTPFileBody.h"
#import "JXHTTPFormEncodedBody.h"
#import "JXHTTPJSONBody.h"
#import "JXHTTPMultipartBody.h"

// Error Logging
#define JXError(error) if (error) { \
                        NSLog(@"%@ (%d) ERROR: %@", \
                        [[NSString stringWithUTF8String:__FILE__] lastPathComponent], \
                        __LINE__, [error localizedDescription]); }
