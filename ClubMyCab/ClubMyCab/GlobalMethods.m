//
//  GlobalMethods.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 26/08/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import "GlobalMethods.h"
#include "Logger.h"

@implementation GlobalMethods

- (void)makeURLConnectionAsynchronousRequestToServer:(NSString *)serverAddress
                                                  endPoint:(NSString *)endPoint
                                                parameters:(NSString *)postParam
                                        delegateForProtocol:(id)delegate {
    
    [self setDelegateGlobalMethodsAsyncRequest:delegate];
    
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
                                       
                                       [Logger logError:@"GlobalMethods"
                                                message:[NSString stringWithFormat:@" %@ data : %@", endPoint, returnValue]];
                                       
                                       [dictionary setObject:returnValue
                                                      forKey:KEY_DATA_ASYNC_CONNECTION];
                                       [dictionary setObject:@""
                                                      forKey:KEY_ERROR_ASYNC_REQUEST];
                                       [[self delegateGlobalMethodsAsyncRequest] asyncRequestComplete:self
                                                                                                 data:[dictionary copy]];
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


@end
