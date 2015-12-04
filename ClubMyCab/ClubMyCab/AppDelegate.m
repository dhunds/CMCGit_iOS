//
//  AppDelegate.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 19/08/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import "AppDelegate.h"
#import "Logger.h"
#import "GlobalMethods.h"

@import GoogleMaps;

@interface AppDelegate () <GlobalMethodsAsyncRequestProtocol>

@property (strong, nonatomic) NSString *deviceTokenAPN;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
//    [Logger logDebug:@"AppDelegate"
//             message:@" didFinishLaunchingWithOptions"];
    
    [GMSServices provideAPIKey:GOOGLE_MAPS_API_KEY];
    
    return YES;
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    [Logger logDebug:@""
             message:[NSString stringWithFormat:@" didRegisterForRemoteNotificationsWithDeviceToken : %@", [deviceToken description]]];
    
    NSString *token = [deviceToken description];
    token = [token stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" "
                                             withString:@""];
    [self setDeviceTokenAPN:token];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_UPDATE_REG_ID
                                                     parameters:[NSString stringWithFormat:@"MobileNumber=%@&DeviceToken=%@", [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_MOBILE], [self deviceTokenAPN]]
                                            delegateForProtocol:self];
    
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    [Logger logError:@""
             message:[NSString stringWithFormat:@" didFailToRegisterForRemoteNotificationsWithError : %@", [error localizedDescription]]];
    
    [self remoteNotificationsRegistrationFailed];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
//    [Logger logDebug:@"AppDelegate"
//             message:@" applicationWillEnterForeground"];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//    [Logger logDebug:@"AppDelegate"
//             message:@" applicationDidBecomeActive"];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Private methods

- (void)remoteNotificationsRegistrationFailed {
    [[NSUserDefaults standardUserDefaults] setObject:@""
                                              forKey:KEY_USER_DEFAULT_APN_DEVICE_TOKEN];
}

#pragma mark - GlobalMethodsAsyncRequestProtocol methods

- (void)asyncRequestComplete:(GlobalMethods *)sender
                        data:(NSDictionary *)data {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString *error = [data valueForKey:KEY_ERROR_ASYNC_REQUEST];
        
        if([error isEqualToString:ERROR_CONNECTION_VALUE]) {
            [self remoteNotificationsRegistrationFailed];
        } else if ([error isEqualToString:ERROR_DATA_NIL_VALUE]) {
            [self remoteNotificationsRegistrationFailed];
        } else if ([error isEqualToString:ERROR_UNAUTHORIZED_ACCESS]) {
            [self remoteNotificationsRegistrationFailed];
        } else {
            NSString *endPoint = [data valueForKey:KEY_ENDPOINT_ASYNC_CONNECTION];
            if ([endPoint isEqualToString:ENDPOINT_UPDATE_REG_ID]) {
                [[NSUserDefaults standardUserDefaults] setObject:[self deviceTokenAPN]
                                                          forKey:KEY_USER_DEFAULT_APN_DEVICE_TOKEN];
            }
        }
    });
}

@end
