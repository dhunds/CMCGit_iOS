//
//  AppDelegate.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 19/08/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;

@property (strong, nonatomic) NSTimer *timer;

@property (strong, nonatomic) CLLocationManager *locationManager;

- (void)initiateLocationSharingForType:(NSString *)type
                              forDuration:(int)duration
                          tillLocation:(CLLocation *)location
                       recipientsNames:(NSString *)names
                     recipientsNumbers:(NSString *)numbers
                                 cabID:(NSString *)cabID;

- (void)stopLocationSharing;



@end

