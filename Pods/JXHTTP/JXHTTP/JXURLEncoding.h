/**
 `JXURLEncoding` is an abstract class providing methods for encoding strings according
 to [RFC 3986]( http://www.ietf.org/rfc/rfc3986.txt ) (aka "percent escaping").
 */

@interface JXURLEncoding : NSObject

/**
 Encodes a string according to RFC 3986.

 @param string A string to encode.
 @returns An encoded string.
 */
+ (NSString *)encodedString:(NSString *)string;

/**
 Encodes a string according to RFC 3986, but with `+` replacing spaces instead of `%20`.
 Commonly used by web browsers to submit forms. When in doubt, use <encodedString:>.

 @param string A string to encode.
 @returns An encoded string.
 */
+ (NSString *)formEncodedString:(NSString *)string;

/**
 Encodes a dictionary according to RFC 3986, with keys sorted alphabetically and flattened
 into a query string. Dictionary values must be one of `NSString`, `NSArray`, or `NSDictionary`.
 
 ### Example ###
 
    NSDictionary *params = @{
        @"make": @"Ferrari",
        @"model": @"458 Italia",
        @"options": @[ @"heated seats", @"cup holders" ]
    };
 
    NSString *escaped = [JXURLEncoding encodedDictionary:params];
    // make=Ferrari&model=458%20Italia&options[0]=heated%20seats&options[1]=cup&20holders

 @param dictionary A dictionary to encode.
 @returns An encoded string.
 */
+ (NSString *)encodedDictionary:(NSDictionary *)dictionary;

/**
 Encodes a dictionary according to RFC 3986, with keys sorted alphabetically and flattened
 into a query string. Dictionary values must be one of `NSString`, `NSArray`, or `NSDictionary`.
 
 Identical to <encodedDictionary:> but with `+` replacing spaces instead of `%20`.

 ### Example ###

     NSDictionary *params = @{
         @"make": @"Ferrari",
         @"model": @"458 Italia",
         @"options": @[ @"heated seats", @"cup holders" ]
     };

     NSString *escaped = [JXURLEncoding encodedDictionary:params];
     // make=Ferrari&model=458+Italia&options[0]=heated+seats&options[1]=cup+holders

 @param dictionary A dictionary to encode.
 @returns An encoded string.
 */
+ (NSString *)formEncodedDictionary:(NSDictionary *)dictionary;

@end
