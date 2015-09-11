//
//  GlobalMethods.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 26/08/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import "GlobalMethods.h"
#import "Logger.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation GlobalMethods

- (void)makeURLConnectionAsynchronousRequestToServer:(NSString *)serverAddress
                                                  endPoint:(NSString *)endPoint
                                                parameters:(NSString *)postParam
                                        delegateForProtocol:(id)delegate {
    
    [self setDelegateGlobalMethodsAsyncRequest:delegate];
    
    postParam = [postParam stringByAppendingString:[NSString stringWithFormat:@"&auth=%@", [self calculateCMCAuthStringForString:postParam]]];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", serverAddress, endPoint]];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setTimeoutInterval:TIMEOUT_SECONDS_NETWORK_QUERY];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest addValue:@"application/x-www-form-urlencoded; charset=utf-8"
      forHTTPHeaderField:@"Content-Type"];
    [urlRequest setHTTPBody:[[NSString stringWithFormat:@"%@", postParam] dataUsingEncoding:NSUTF8StringEncoding
                                                                       allowLossyConversion:YES]];
    
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest
                                       queue:operationQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
                               [dictionary setObject:endPoint
                                              forKey:KEY_ENDPOINT_ASYNC_CONNECTION];
                               
                               if(connectionError == nil) {
                                   if(data != nil) {
                                       NSString *returnValue = [[NSString alloc] initWithData:data
                                                                           encoding:NSUTF8StringEncoding];
                                       
                                       [Logger logDebug:@"GlobalMethods"
                                                message:[NSString stringWithFormat:@" %@ params : %@ data : %@", endPoint, postParam, returnValue]];
                                       
                                       if([returnValue rangeOfString:ERROR_UNAUTHORIZED_ACCESS].location != NSNotFound) {
                                           [Logger logError:@"GlobalMethods"
                                                    message:[NSString stringWithFormat:@" %@ %@", endPoint, ERROR_UNAUTHORIZED_ACCESS]];
                                           
                                           [dictionary setObject:ERROR_UNAUTHORIZED_ACCESS
                                                          forKey:KEY_ERROR_ASYNC_REQUEST];
                                           [dictionary setObject:@""
                                                          forKey:KEY_DATA_ASYNC_CONNECTION];
                                           [[self delegateGlobalMethodsAsyncRequest] asyncRequestComplete:self
                                                                                                     data:[dictionary copy]];
                                       } else {
                                           [dictionary setObject:returnValue
                                                          forKey:KEY_DATA_ASYNC_CONNECTION];
                                           [dictionary setObject:@""
                                                          forKey:KEY_ERROR_ASYNC_REQUEST];
                                           [[self delegateGlobalMethodsAsyncRequest] asyncRequestComplete:self
                                                                                                     data:[dictionary copy]];
                                       }
                                   } else {
                                       [Logger logError:@"GlobalMethods"
                                                message:[NSString stringWithFormat:@" %@ data == nil", endPoint]];
                                       
                                       [dictionary setObject:ERROR_DATA_NIL_VALUE
                                                      forKey:KEY_ERROR_ASYNC_REQUEST];
                                       [dictionary setObject:@""
                                                      forKey:KEY_DATA_ASYNC_CONNECTION];
                                       [[self delegateGlobalMethodsAsyncRequest] asyncRequestComplete:self
                                                                                                 data:[dictionary copy]];
                                   }
                               } else {
                                   [Logger logError:@"GlobalMethods"
                                            message:[NSString stringWithFormat:@" %@ connectionError : %@", endPoint, [connectionError localizedDescription]]];
                                   
                                   [dictionary setObject:ERROR_CONNECTION_VALUE
                                                  forKey:KEY_ERROR_ASYNC_REQUEST];
                                   [dictionary setObject:@""
                                                  forKey:KEY_DATA_ASYNC_CONNECTION];
                                   [[self delegateGlobalMethodsAsyncRequest] asyncRequestComplete:self
                                                                                             data:[dictionary copy]];
                               }
                           }];
}

- (NSString *)calculateCMCAuthStringForString:(NSString *)string {
    
    NSArray *ampSeparated = [[string componentsSeparatedByString:@"&"] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    NSString *stringToEncrypt = @"";
    for (NSString *ampSeparatedString in ampSeparated) {
        NSArray *equalsToSeparated = [ampSeparatedString componentsSeparatedByString:@"="];
        if ([[equalsToSeparated lastObject] length] > 0) {
            stringToEncrypt = [stringToEncrypt stringByAppendingString:[equalsToSeparated lastObject]];
        }
    }
    
    NSString *key = CMC_SECRET_KEY;
    
    const char *cStringKey = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cStringToEncrypt = [stringToEncrypt cStringUsingEncoding:NSASCIIStringEncoding];
    
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA256, cStringKey, strlen(cStringKey), cStringToEncrypt, strlen(cStringToEncrypt), cHMAC);
    
    NSData *dataHMAC = [NSData dataWithBytes:cHMAC
                                      length:sizeof(cHMAC)];
    
    const unsigned char *buffer = (const unsigned char *)[dataHMAC bytes];
    
    NSMutableString *stringHMAC = [NSMutableString stringWithCapacity:(dataHMAC.length * 2)];
    
    for (int i = 0; i < dataHMAC.length; ++i){
        [stringHMAC appendFormat:@"%02x", buffer[i]];
    }
    
    [Logger logDebug:@"GlobalMethods"
             message:[NSString stringWithFormat:@" calculateCMCAuthStringForString stringToEncrypt : %@ encrypted : %@", stringToEncrypt, stringHMAC]];
    
    return stringHMAC;
    
//    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
//    NSData *stringData = [stringToEncrypt dataUsingEncoding:NSUTF8StringEncoding];
//    
//    NSMutableData *hash = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
//    
//    CCHmac(kCCHmacAlgSHA256, keyData.bytes, keyData.length, stringData.bytes, stringData.length, hash.mutableBytes);
//    
//    NSString *returnValue = [hash base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
//    
//    return returnValue;
    
}


@end
