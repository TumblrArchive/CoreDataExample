# JXHTTP #

JXHTTP is a networking library for iOS and OS X. It leverages operation queues and GCD to provide a powerful wrapper for Cocoa's built-in `NSURLConnection` object, adding many useful features like block response objects and progress tracking across multiple requests. It strives to be as lightweight and readable as possible, making it easy to use or customize for advanced behavior.

To get started, simply [download the latest tag](https://github.com/jstn/JXHTTP/tags) and drop the `JXHTTP` folder into your Xcode project. There are zero external dependencies or special compiler flags, just `#import "JXHTTP.h"` somewhere convenient. A complete docset is included for use in Xcode or [Dash](http://kapeli.com/dash/), and available online at [jxhttp.com](http://jxhttp.com/docs/html/). JXHTTP is also available as a [CocoaPod](http://cocoapods.org/?q=name%3AJXHTTP).

JXHTTP requires iOS 5.0 or OS X 10.7 or newer.

## Advantages ##

[JXHTTPOperation](JXHTTP/JXHTTPOperation.h) offers a number of advantages over using vanilla `NSURLConnection` without an operation wrapper:

- requests can be easily grouped, prioritized, cancelled, and executed concurrently
- data can be streamed to and from disk for excellent memory efficiency
- requests can optionally continue executing when the app is sent to the background
- progress is easily tracked via delegate methods, response blocks, KVO, or all three
- requests run entirely on background threads, away from the main thread and UI
- particular attention has been paid to thread safety and is well-documented throughout

JXHTTP is production-ready and currently powers the [Tumblr iOS SDK](http://tumblr.com/mobile); thousands of successful requests were performed while you read this paragraph!

## Examples ##

See the included [example project](example/) for a real-world use case in iOS.

### Asynchronous ###

```objective-c
JXHTTPOperation *op = [JXHTTPOperation withURLString:@"https://encrypted.google.com/"];
op.didFinishLoadingBlock = ^(JXHTTPOperation *op) {
    NSLog(@"%@", op.responseString);
};

[[JXHTTPOperationQueue sharedQueue] addOperation:op];
```

### Synchronous ###

```objective-c
JXHTTPOperation *op = [JXHTTPOperation withURLString:@"https://encrypted.google.com/"];
[op startAndWaitUntilFinished];

NSLog(@"%@", op.responseString);
```

### Complex ###

```objective-c
NSURL *postURL = [NSURL URLWithString:@"https://web.site/api/POST"];
NSDictionary *postParams = @{ @"make": @"Ferrari", @"model": @"458 Italia" };

JXHTTPOperation *op = [[JXHTTPOperation alloc] initWithURL:postURL];
op.requestBody = [[JXHTTPFormEncodedBody alloc] initWithDictionary:postParams];
op.requestCachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
op.responseDataFilePath = @"/tmp/downloaded_data";
op.trustedHosts = @[ postURL.host ];
op.performsBlocksOnMainQueue = YES;

op.didSendDataBlock = ^(JXHTTPOperation *op) {
    NSLog(@"%lld bytes uploaded so far", op.bytesUploaded);
};

[[JXHTTPOperationQueue sharedQueue] addOperation:op];
```

## Contact ##

JXHTTP was created by [Justin Ouellette](http://justinouellette.com/).

Email [jstn@jxhttp.com](mailto:jstn@jxhttp.com) with questions.