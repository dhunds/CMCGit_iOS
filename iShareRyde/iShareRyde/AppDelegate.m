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
#import "HomeCarPoolViewController.h"
#import <Google/Analytics.h>

@import GoogleMaps;

@interface AppDelegate () <GlobalMethodsAsyncRequestProtocol>

@property (strong, nonatomic) NSString *deviceTokenAPN;

@property (strong, nonatomic) NSDictionary *dictionaryNotification;
@property (nonatomic) BOOL isNotificationAlertViewShowing;
@property (strong, nonatomic) UIAlertView *alertViewLocalNotification, *alertViewRemoteNotification;

@property (nonatomic) BOOL updateSent;

@property (strong, nonatomic) NSString *sharingType, *recipientNames, *recipientNumbers, *cabID;
@property (nonatomic) int shareForDuration;
@property (strong, nonatomic) CLLocation *shareTillLocation;
@property (strong, nonatomic) NSDate *startedSharing;

@end

@implementation AppDelegate

#pragma mark - AppDelegate methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [Logger logDebug:@"AppDelegate"
             message:@" didFinishLaunchingWithOptions"];
    
    [GMSServices provideAPIKey:GOOGLE_MAPS_API_KEY];
    
    NSError *configureError;
    [[GGLContext sharedInstance] configureWithError:&configureError];
    NSAssert(!configureError, @"Error configuring Google services: %@", configureError);
    
    // Optional: configure GAI options.
    GAI *gai = [GAI sharedInstance];
    gai.trackUncaughtExceptions = YES;  // report uncaught exceptions
//    gai.logger.logLevel = kGAILogLevelVerbose;  // remove before app release
    
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
    
    [[NSUserDefaults standardUserDefaults] setBool:YES
                                            forKey:KEY_USER_DEFAULT_CHECK_OPEN_RIDES];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    [Logger logDebug:@"AppDelegate"
             message:@" applicationWillResignActive"];
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    [Logger logDebug:@"AppDelegate"
             message:@" applicationDidEnterBackground"];
    
    //to reopen the app on home page always
    UIViewController *navigationController = [[self window] rootViewController];
    if ([navigationController presentedViewController] && [[navigationController presentedViewController] isKindOfClass:[SWRevealViewController class]]) {
        
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:KEY_USER_DEFAULT_IS_ENTERING_BACKGROUND];
        
        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main"
                                                             bundle:nil];
        SWRevealViewController *revealViewController = (SWRevealViewController *)[navigationController presentedViewController];
        
        UINavigationController *poolNavigationController = [storyBoard instantiateViewControllerWithIdentifier:@"CarPoolNavigationController"];
        [revealViewController pushFrontViewController:poolNavigationController
                                             animated:YES];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    [Logger logDebug:@"AppDelegate"
             message:@" applicationWillEnterForeground"];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [Logger logDebug:@"AppDelegate"
             message:@" applicationDidBecomeActive"];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [Logger logDebug:@"AppDelegate"
             message:@" applicationWillTerminate"];
}

#pragma mark - Location sharing methods

#define DISTANCE_THRESHOLD                  100
#define MAX_HOURS_LOC_SHARING               4

- (void)startUpdatingLocation {
//    NSLog(@"startUpdatingLocation background time: %f", [UIApplication sharedApplication].backgroundTimeRemaining);
    
    [Logger logDebug:@"startUpdatingLocation"
             message:@""];
    
    if (![self locationManager]) {
        [self setLocationManager:[[CLLocationManager alloc] init]];
        [[self locationManager] setDelegate:self];
        [[self locationManager] setAllowsBackgroundLocationUpdates:YES];
        [[self locationManager] setDesiredAccuracy:kCLLocationAccuracyBest];
        [[self locationManager] setDistanceFilter:kCLDistanceFilterNone];
        [[self locationManager] setPausesLocationUpdatesAutomatically:NO];
        [[self locationManager] setActivityType:CLActivityTypeAutomotiveNavigation];
    }
    
    [self setUpdateSent:NO];
    [[self locationManager] startUpdatingLocation];
}

- (void)stopLocationSharing {
    [[self locationManager] stopUpdatingLocation];
    [[self timer] invalidate];
    [[NSUserDefaults standardUserDefaults] setBool:NO
                                            forKey:KEY_IS_LOCATION_SHARING_ON];
    [Logger logDebug:@"stopUpdatingLocation"
             message:[NSString stringWithFormat:@""]];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    
    CLLocation *userLocation = nil;
    
    for (CLLocation *loc in locations) {
        [Logger logDebug:@"didUpdateLocations"
                 message:[NSString stringWithFormat:@" loc : %@ accuracy : %f", [loc description], [loc horizontalAccuracy]]];
        
        if ([loc horizontalAccuracy] < DISTANCE_THRESHOLD) {
            userLocation = loc;
            break;
        }
    }
    
    if (userLocation && ![self updateSent]) {
        
        [self setUpdateSent:YES];
        
        if ([[self sharingType] isEqualToString:SHARE_LOCATION_TYPE_FOR_RIDE]) {
            GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
            [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                               endPoint:ENDPOINT_UPDATE_OWNER_LOCATION
                                                             parameters:[NSString stringWithFormat:@"cabId=%@&location=%@", [self cabID], [NSString stringWithFormat:@"%f,%f", [userLocation coordinate].latitude, [userLocation coordinate].longitude]]
                                                    delegateForProtocol:self];
            
            if ([[self shareTillLocation] distanceFromLocation:userLocation] < DISTANCE_THRESHOLD) {
                [self stopLocationSharing];
                
                GlobalMethods *updateCabStatus = [[GlobalMethods alloc] init];
                [updateCabStatus makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                                     endPoint:ENDPOINT_UPDATE_CAB_STATUS
                                                                   parameters:[NSString stringWithFormat:@"cabId=%@", [self cabID]]
                                                          delegateForProtocol:self];
                
            } else if ([[self startedSharing] timeIntervalSinceNow] <= (-1.0f * MAX_HOURS_LOC_SHARING * 60 * 60)) {
                [self stopLocationSharing];
            }
        } else {
            GMSGeocoder *geoCoder = [[GMSGeocoder alloc] init];
            [geoCoder reverseGeocodeCoordinate:[userLocation coordinate]
                             completionHandler:^(GMSReverseGeocodeResponse *response, NSError *error) {
                                 if (!error) {
                                     //                                 [Logger logDebug:@""
                                     //                                          message:[NSString stringWithFormat:@" reverseGeocodeCoordinate : %@", [[response results] description]]];
                                     
                                     NSString *address = @"";
                                     NSArray *addressObject = [(GMSAddress *)[[response results] firstObject] lines];
                                     for (int i = 0; i < [addressObject count]; i++) {
                                         address = [address stringByAppendingString:[NSString stringWithFormat:@"%@%@ ", [addressObject objectAtIndex:i], @","]];
                                     }
                                     address = [address substringToIndex:([address length] - 2)];
                                     
                                     NSString *name = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_NAME];
                                     
                                     GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
                                     [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                                                        endPoint:ENDPOINT_SHARE_LOCATION_MEMBERS
                                                                                      parameters:[NSString stringWithFormat:@"MembersNumber=%@&MembersName=%@&FullName=%@&MobileNumber=%@&Message=%@&latlongstr=%@", [self recipientNumbers], [self recipientNames], name, [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_MOBILE], [NSString stringWithFormat:@"%@ is at - %@", name, address], [NSString stringWithFormat:@"%f,%f", [userLocation coordinate].latitude, [userLocation coordinate].longitude]]
                                                                             delegateForProtocol:self];
                                     
                                     if ([[self sharingType] isEqualToString:SHARE_LOCATION_TYPE_DURATION]) {
                                         [Logger logDebug:@"SHARE_LOCATION_TYPE_DURATION"
                                                  message:[NSString stringWithFormat:@" %f : ", [[self startedSharing] timeIntervalSinceNow]]];
                                         if ([[self startedSharing] timeIntervalSinceNow] <= ([self shareForDuration] * -1.0f)) {
                                             [self stopLocationSharing];
                                         } else if ([[self startedSharing] timeIntervalSinceNow] <= (-1.0f * MAX_HOURS_LOC_SHARING * 60 * 60)) {
                                             [self stopLocationSharing];
                                         }
                                     } else if ([[self sharingType] isEqualToString:SHARE_LOCATION_TYPE_DESTINATION]) {
                                         
                                         [Logger logDebug:@"SHARE_LOCATION_TYPE_DESTINATION"
                                                  message:[NSString stringWithFormat:@" %f : ", [[self shareTillLocation] distanceFromLocation:userLocation]]];
                                         
                                         if ([[self shareTillLocation] distanceFromLocation:userLocation] < DISTANCE_THRESHOLD) {
                                             [self stopLocationSharing];
                                         } else if ([[self startedSharing] timeIntervalSinceNow] <= (-1.0f * MAX_HOURS_LOC_SHARING * 60 * 60)) {
                                             [self stopLocationSharing];
                                         }
                                     }
                                     
                                 } else {
                                     [Logger logError:@""
                                              message:[NSString stringWithFormat:@" reverseGeocodeCoordinate error : %@", [error localizedDescription]]];
                                     [self setUpdateSent:NO];
                                 }
                             }];
        }
    }
    
}

- (void)initiateLocationSharingForType:(NSString *)type
                           forDuration:(int)duration
                          tillLocation:(CLLocation *)location
                       recipientsNames:(NSString *)names
                     recipientsNumbers:(NSString *)numbers
                                 cabID:(NSString *)cabID {
    
    [self setSharingType:type];
    [self setShareForDuration:duration];
    [self setShareTillLocation:location];
    [self setRecipientNames:names];
    [self setRecipientNumbers:numbers];
    [self setCabID:cabID];
    
    int repeatInterval;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *shareInterval = [userDefaults objectForKey:KEY_USER_DEFAULT_SHARE_LOCATION_INTERVAL];
    if (shareInterval) {
        repeatInterval = [[shareInterval stringByReplacingOccurrencesOfString:@" minutes"
                                                                    withString:@""] intValue];
    } else {
        [userDefaults setObject:VALUE_USER_DEFAULT_SHARE_LOCATION_INTERVAL_5
                         forKey:KEY_USER_DEFAULT_SHARE_LOCATION_INTERVAL];
        shareInterval = VALUE_USER_DEFAULT_SHARE_LOCATION_INTERVAL_5;
        
        repeatInterval = [[shareInterval stringByReplacingOccurrencesOfString:@" minutes"
                                                                   withString:@""] intValue];
    }
    
    [self setBackgroundTask:[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        NSLog(@"ending background task");
        [[UIApplication sharedApplication] endBackgroundTask:[self backgroundTask]];
        [self setBackgroundTask:UIBackgroundTaskInvalid];
        [[self timer] invalidate];
    }]];
    
    
    
    [self setTimer:[NSTimer scheduledTimerWithTimeInterval:(repeatInterval * 60)
                                                    target:self
                                                  selector:@selector(startUpdatingLocation)
                                                  userInfo:nil
                                                   repeats:YES]];
    //initiating the first share without timer else it starts at repeatInterval
    [self startUpdatingLocation];
    [self setStartedSharing:[NSDate date]];
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
            UINavigationController *CarPoolNavigationController = [storyBoard instantiateViewControllerWithIdentifier:@"CarPoolNavigationController"];
            [(HomeCarPoolViewController *)[[CarPoolNavigationController viewControllers] firstObject] setNidFromNotification:nid];
            [revealViewController pushFrontViewController:CarPoolNavigationController
                                                 animated:YES];
        } else if ([pushFrom caseInsensitiveCompare:@"Share_LocationUpdate"] == NSOrderedSame) {
            UINavigationController *CarPoolNavigationController = [storyBoard instantiateViewControllerWithIdentifier:@"CarPoolNavigationController"];
            [(HomeCarPoolViewController *)[[CarPoolNavigationController viewControllers] firstObject] setNidFromNotification:nid];
            [revealViewController pushFrontViewController:CarPoolNavigationController
                                                 animated:YES];
        } else if ([pushFrom caseInsensitiveCompare:@"PoolId_"] == NSOrderedSame) {
            UINavigationController *clubNavigationController = [storyBoard instantiateViewControllerWithIdentifier:@"MyClubsNavigationController"];
            [(MyClubsViewController *)[[clubNavigationController viewControllers] firstObject] setNidFromNotification:nid];
            [revealViewController pushFrontViewController:clubNavigationController
                                                 animated:YES];
        } else if ([pushFrom caseInsensitiveCompare:@"Cab_Rating"] == NSOrderedSame) {
            UINavigationController *CarPoolNavigationController = [storyBoard instantiateViewControllerWithIdentifier:@"CarPoolNavigationController"];
            [(HomeCarPoolViewController *)[[CarPoolNavigationController viewControllers] firstObject] setNidFromNotification:nid];
            [revealViewController pushFrontViewController:CarPoolNavigationController
                                                 animated:YES];
        } else {
            UINavigationController *CarPoolNavigationController = [storyBoard instantiateViewControllerWithIdentifier:@"CarPoolNavigationController"];
            [(HomeCarPoolViewController *)[[CarPoolNavigationController viewControllers] firstObject] setNidFromNotification:nid];
            [revealViewController pushFrontViewController:CarPoolNavigationController
                                                 animated:YES];
        }
    } else {
        UINavigationController *CarPoolNavigationController = [storyBoard instantiateViewControllerWithIdentifier:@"CarPoolNavigationController"];
        [(HomeCarPoolViewController *)[[CarPoolNavigationController viewControllers] firstObject] setNidFromNotification:nid];
        [revealViewController pushFrontViewController:CarPoolNavigationController
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
