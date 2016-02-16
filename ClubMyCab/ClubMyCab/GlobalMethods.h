//
//  GlobalMethods.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 26/08/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>

@class GlobalMethods;

@protocol GlobalMethodsAsyncRequestProtocol <NSObject>

@required

- (void)asyncRequestComplete:(GlobalMethods *)sender
                        data:(NSDictionary *)data;

@end

@interface GlobalMethods : NSObject

@property (weak, nonatomic) id <GlobalMethodsAsyncRequestProtocol> delegateGlobalMethodsAsyncRequest;

- (void)makeURLConnectionAsynchronousRequestToServer:(NSString *)serverAddress
                                                  endPoint:(NSString *)endPoint
                                                parameters:(NSString *)postParam
                                 delegateForProtocol:(id)delegate;

- (void)makeMobikwikURLConnectionAsynchronousRequestToServer:(NSString *)serverAddress
                                            endPoint:(NSString *)endPoint
                                          parameters:(NSString *)postParam
                                 delegateForProtocol:(id)delegate;

- (BOOL)checkMobikwikResponseCheckSum:(NSString *)response
                          andResponse:(NSString *)response;

- (UIBarButtonItem *)getNotificationsBarButtonItemWithTarget:(id)target
                                    unreadNotificationsCount:(int)count;

- (UIBarButtonItem *)getProfileImageBarButtonItemWithTarget:(id)target;

- (NSString *)getShortNameForGMSAddress:(GMSAddress *)address;

@end
