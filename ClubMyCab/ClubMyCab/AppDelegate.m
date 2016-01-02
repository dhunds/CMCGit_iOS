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
#import "SWRevealViewController.h"
#import "MyRidesViewController.h"
#import "MyClubsViewController.h"
#import "HomePageViewController.h"

@import GoogleMaps;

@interface AppDelegate () <GlobalMethodsAsyncRequestProtocol>

@property (strong, nonatomic) NSString *deviceTokenAPN;

@property (strong, nonatomic) NSDictionary *dictionaryNotification;
@property (nonatomic) BOOL isNotificationAlertViewShowing;
@property (strong, nonatomic) UIAlertView *alertViewLocalNotification, *alertViewRemoteNotification;

@end

@implementation AppDelegate

#pragma mark - AppDelegate methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [GMSServices provideAPIKey:GOOGLE_MAPS_API_KEY];
    
    UILocalNotification *localNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotification) {
        [Logger logDebug:@"AppDelegate"
                 message:[NSString stringWithFormat:@" didFinishLaunchingWithOptions localNotification : %@ userInfo : %@", [localNotification description], [[localNotification userInfo] description]]];
        
        [self application:application didReceiveLocalNotification:localNotification];
    }
    
    if (launchOptions != nil) {
        // Launched from push notification
        NSDictionary *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];

        [Logger logDebug:@"AppDelegate"
                 message:[NSString stringWithFormat:@" didFinishLaunchingWithOptions remoteNotification : %@", [notification description]]];
        
        [self application:application didReceiveRemoteNotification:(NSDictionary*)notification];
    }
    
    return YES;
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

#pragma mark - Notification methods

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
    [Logger logError:@"AppDelegate"
             message:[NSString stringWithFormat:@" didFailToRegisterForRemoteNotificationsWithError : %@", [error localizedDescription]]];
    
    [self remoteNotificationsRegistrationFailed];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [Logger logDebug:@"AppDelegate"
             message:[NSString stringWithFormat:@" didReceiveLocalNotification notification : %@ userInfo : %@", [notification description], [[notification userInfo] description]]];
    
    if ([application applicationState] == UIApplicationStateInactive || [application applicationState] == UIApplicationStateBackground) {
        [self handleLocalNotification:[notification userInfo]];
    } else {
        if ([self isNotificationAlertViewShowing]) {
            return;
        }
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Reminder"
                                                            message:[notification alertBody]
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Dismiss", @"Check notification", nil];
        [self setDictionaryNotification:[notification userInfo]];
        [self setIsNotificationAlertViewShowing:YES];
        [self setAlertViewLocalNotification:alertView];
        [alertView show];
    }
    
}

- (void)handleLocalNotification:(NSDictionary *)dictionary {
    [self openMyRidesVCForUserInfo:dictionary];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [Logger logError:@"AppDelegate"
             message:[NSString stringWithFormat:@" didReceiveRemoteNotification : %@", [userInfo description]]];
    
    if ([application applicationState] == UIApplicationStateInactive || [application applicationState] == UIApplicationStateBackground) {
        [self handleRemoteNotification:userInfo];
    } else {
        if ([self isNotificationAlertViewShowing]) {
            return;
        }
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Notification received"
                                                            message:[[userInfo objectForKey:@"aps"] objectForKey:@"alert"]
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Dismiss", @"Check notification", nil];
        [self setDictionaryNotification:userInfo];
        [self setIsNotificationAlertViewShowing:YES];
        [self setAlertViewRemoteNotification:alertView];
        [alertView show];
    }
    
    
}

- (void)handleRemoteNotification:(NSDictionary *)dictionary {
    NSDictionary *aps = [dictionary objectForKey:@"aps"];
    
    NSString *pushFrom = [aps objectForKey:@"pushfrom"];
    NSString *nid = [aps objectForKey:@"notificationId"];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    UIViewController *navigationController = [[self window] rootViewController];
    
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main"
                                                         bundle:nil];
    SWRevealViewController *revealViewController = (SWRevealViewController *)[navigationController presentedViewController];
    
    if (pushFrom && [pushFrom length] > 0) {
        if ([pushFrom caseInsensitiveCompare:@"groupchat"] == NSOrderedSame) {
            //TODO
        } else if ([pushFrom caseInsensitiveCompare:@"upcomingtrip"] == NSOrderedSame) {
            //TODO
        } else if ([pushFrom caseInsensitiveCompare:@"genericnotification"] == NSOrderedSame) {
            //nothing to do here, home screen opens automatically
        } else if ([[pushFrom lowercaseString] rangeOfString:@"genericnotification"].location != NSNotFound) {
            if ([pushFrom caseInsensitiveCompare:@"genericnotificationclub"] == NSOrderedSame) {
                UINavigationController *clubNavigationController = [storyBoard instantiateViewControllerWithIdentifier:@"MyClubsNavigationController"];
                [revealViewController pushFrontViewController:clubNavigationController
                                                     animated:YES];
            } else if ([pushFrom caseInsensitiveCompare:@"genericnotificationrides"] == NSOrderedSame) {
                UINavigationController *ridesNavCont = [storyBoard instantiateViewControllerWithIdentifier:@"MyRidesNavigationController"];
                [(SWRevealViewController *)[navigationController presentedViewController] pushFrontViewController:ridesNavCont
                                                                                                         animated:YES];
            } else if ([pushFrom caseInsensitiveCompare:@"genericnotificationwallet"] == NSOrderedSame) {
                UINavigationController *walletsNavCont = [storyBoard instantiateViewControllerWithIdentifier:@"MyWalletsNavigationController"];
                [(SWRevealViewController *)[navigationController presentedViewController] pushFrontViewController:walletsNavCont
                                                                                                         animated:YES];
            } else if ([pushFrom caseInsensitiveCompare:@"genericnotificationsharelocation"] == NSOrderedSame) {
                UINavigationController *shareLocNavCont = [storyBoard instantiateViewControllerWithIdentifier:@"ShareLocNavigationController"];
                [(SWRevealViewController *)[navigationController presentedViewController] pushFrontViewController:shareLocNavCont
                                                                                                         animated:YES];
            } else if ([pushFrom caseInsensitiveCompare:@"genericnotificationprofile"] == NSOrderedSame) {
                UINavigationController *profileNavCont = [storyBoard instantiateViewControllerWithIdentifier:@"MyProfileNavigationController"];
                [(SWRevealViewController *)[navigationController presentedViewController] pushFrontViewController:profileNavCont
                                                                                                         animated:YES];
            } else if ([pushFrom caseInsensitiveCompare:@"genericnotificationsettings"] == NSOrderedSame) {
                UINavigationController *settingsNavCont = [storyBoard instantiateViewControllerWithIdentifier:@"SettingsNavigationController"];
                [(SWRevealViewController *)[navigationController presentedViewController] pushFrontViewController:settingsNavCont
                                                                                                         animated:YES];
            } else if ([pushFrom caseInsensitiveCompare:@"genericnotificationoffers"] == NSOrderedSame) {
                UINavigationController *offersNavCont = [storyBoard instantiateViewControllerWithIdentifier:@"OffersNavigationController"];
                [(SWRevealViewController *)[navigationController presentedViewController] pushFrontViewController:offersNavCont
                                                                                                         animated:YES];
            }
        } else if ([pushFrom caseInsensitiveCompare:@"TripStart"] == NSOrderedSame || [pushFrom caseInsensitiveCompare:@"ownerTripCompleted"] == NSOrderedSame || [pushFrom caseInsensitiveCompare:@"tripcompleted"] == NSOrderedSame) {
            UINavigationController *ridesNavCont = [storyBoard instantiateViewControllerWithIdentifier:@"MyRidesNavigationController"];
            [(MyRidesViewController *)[[ridesNavCont viewControllers] firstObject] setCabIDFromNotification:[aps objectForKey:@"CabId"]];
            [(MyRidesViewController *)[[ridesNavCont viewControllers] firstObject] setNidFromNotifications:nid];
            [(SWRevealViewController *)[navigationController presentedViewController] pushFrontViewController:ridesNavCont
                                                                                                     animated:YES];
        } else if ([pushFrom caseInsensitiveCompare:@"CabId_"] == NSOrderedSame) {
            UINavigationController *homePageNavigationController = [storyBoard instantiateViewControllerWithIdentifier:@"HomePageNavigationController"];
            [(HomePageViewController *)[[homePageNavigationController viewControllers] firstObject] setNidFromNotification:nid];
            [revealViewController pushFrontViewController:homePageNavigationController
                                                 animated:YES];
        } else if ([pushFrom caseInsensitiveCompare:@"Share_LocationUpdate"] == NSOrderedSame) {
            UINavigationController *homePageNavigationController = [storyBoard instantiateViewControllerWithIdentifier:@"HomePageNavigationController"];
            [(HomePageViewController *)[[homePageNavigationController viewControllers] firstObject] setNidFromNotification:nid];
            [revealViewController pushFrontViewController:homePageNavigationController
                                                 animated:YES];
        } else if ([pushFrom caseInsensitiveCompare:@"PoolId_"] == NSOrderedSame) {
            UINavigationController *clubNavigationController = [storyBoard instantiateViewControllerWithIdentifier:@"MyClubsNavigationController"];
            [(MyClubsViewController *)[[clubNavigationController viewControllers] firstObject] setNidFromNotification:nid];
            [revealViewController pushFrontViewController:clubNavigationController
                                                 animated:YES];
        } else if ([pushFrom caseInsensitiveCompare:@"Cab_Rating"] == NSOrderedSame) {
            UINavigationController *homePageNavigationController = [storyBoard instantiateViewControllerWithIdentifier:@"HomePageNavigationController"];
            [(HomePageViewController *)[[homePageNavigationController viewControllers] firstObject] setNidFromNotification:nid];
            [revealViewController pushFrontViewController:homePageNavigationController
                                                 animated:YES];
        } else {
            UINavigationController *homePageNavigationController = [storyBoard instantiateViewControllerWithIdentifier:@"HomePageNavigationController"];
            [(HomePageViewController *)[[homePageNavigationController viewControllers] firstObject] setNidFromNotification:nid];
            [revealViewController pushFrontViewController:homePageNavigationController
                                                 animated:YES];
        }
    } else {
        UINavigationController *homePageNavigationController = [storyBoard instantiateViewControllerWithIdentifier:@"HomePageNavigationController"];
        [(HomePageViewController *)[[homePageNavigationController viewControllers] firstObject] setNidFromNotification:nid];
        [revealViewController pushFrontViewController:homePageNavigationController
                                             animated:YES];
    }
}

#pragma mark - Private methods

- (void)remoteNotificationsRegistrationFailed {
    [[NSUserDefaults standardUserDefaults] setObject:@""
                                              forKey:KEY_USER_DEFAULT_APN_DEVICE_TOKEN];
}

- (void)openMyRidesVCForUserInfo:(NSDictionary *)uInfo {
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    UIViewController *navigationController = [[self window] rootViewController];
    
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main"
                                                         bundle:nil];
    UINavigationController *ridesNavCont = [storyBoard instantiateViewControllerWithIdentifier:@"MyRidesNavigationController"];
    [(MyRidesViewController *)[[ridesNavCont viewControllers] firstObject] setCabIDFromNotification:[uInfo objectForKey:@"CabID"]];
    
    [Logger logDebug:@"AppDelegate"
             message:[NSString stringWithFormat:@" didReceiveLocalNotification ridesNavCont : %@", [[ridesNavCont viewControllers] description]]];
    
    [(SWRevealViewController *)[navigationController presentedViewController] pushFrontViewController:ridesNavCont
                                                                                             animated:YES];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    [self setIsNotificationAlertViewShowing:NO];
    
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:@"Check notification"]) {
        if (alertView == [self alertViewRemoteNotification]) {
            [self handleRemoteNotification:[self dictionaryNotification]];
        } else if (alertView == [self alertViewLocalNotification]) {
            [self handleLocalNotification:[self dictionaryNotification]];
        }
    }
    //    else if ([buttonTitle isEqualToString:@"Dismiss"]) {
    //
    //    }
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
