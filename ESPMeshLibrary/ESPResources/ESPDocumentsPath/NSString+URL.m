//
//  NSString+URL.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/3/18.
//  Copyright © 2019年 zhaobing. All rights reserved.
//

#import "NSString+URL.h"

@implementation NSString (URL)
/**
 *  URLEncode
 */
- (NSString *)URLEncodedString
{
    
    NSString *unencodedString = self;
//    NSString *encodedString = (NSString *)
//    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
//                                                              (CFStringRef)unencodedString,
//                                                              NULL,
//                                                              (CFStringRef)@"!*'();:@&=+$,/?%#[]",
//                                                              kCFStringEncodingUTF8));
    NSString *encodedString = (NSString *)CFBridgingRelease((__bridge CFTypeRef _Nullable)([[unencodedString description] stringByAddingPercentEncodingWithAllowedCharacters:[[NSCharacterSet characterSetWithCharactersInString:@"!*'();:@&=+$,/?%#[]"] invertedSet]]));
    
    return encodedString;
}

/**
 *  URLDecode
 */
-(NSString *)URLDecodedString
{
    NSString *encodedString = self;
//    NSString *decodedString  = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
//                                                                                                                     (__bridge CFStringRef)encodedString,
//                                                                                                                     CFSTR(""),
//                                                                                                                     CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    NSString *decodedString  = (NSString *)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, (CFStringRef)encodedString, CFSTR("")));
    return decodedString;
}
@end
