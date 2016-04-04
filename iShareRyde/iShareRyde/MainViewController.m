//
//  MainViewController.m
//  iShareRyde
//
//  Created by MacDev2 on 01/04/16.
//  Copyright © 2016 iShareRyde. All rights reserved.
//

#import "MainViewController.h"
#import "SWRevealViewController.h"

#import "GlobalMethods.h"
#import "Logger.h"
#import "ActivityIndicatorView.h"
#import "ToastLabel.h"
#import "NotificationsListViewController.h"
#import "HomePageViewController.h"
#import "MyRidesTableViewCell.h"
#import "RideDetailsViewController.h"
#import "RideDetailsMemberViewController.h"
#import "MyRidesViewController.h"
#import "MyProfileViewController.h"
#import <Google/Analytics.h>

@interface MainViewController () <NKJPagerViewDataSource, NKJPagerViewDelegate, GlobalMethodsAsyncRequestProtocol, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *barButtonItem;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) UIAlertView *alertViewNotifications;
@property (strong, nonatomic) UIAlertView *alertViewProfileImage;

@end

@implementation MainViewController

- (void)viewDidLoad
{   
    self.dataSource = self;
    self.delegate = self;
    self.infiniteSwipe = NO;
    
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationEnteredForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    SWRevealViewController *revealViewController = [self revealViewController];
    if (revealViewController) {
        [[self barButtonItem] setTarget:revealViewController];
        [[self barButtonItem] setAction:@selector(revealToggle:)];
        [[self view] addGestureRecognizer:[[self revealViewController] panGestureRecognizer]];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:KEY_USER_DEFAULT_IS_ENTERING_BACKGROUND]) {
        return;
    }
    
    [self checkNotificationSettings];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
//    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
//    [tracker set:kGAIScreenName
//           value:[self TAG]];
//    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
//    
//    if ([[NSUserDefaults standardUserDefaults] boolForKey:KEY_USER_DEFAULT_IS_ENTERING_BACKGROUND]) {
//        return;
//    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_FETCH_UNREAD_NOTIFICATIONS_COUNT
                                                     parameters:[NSString stringWithFormat:@"MobileNumber=%@", [userDefaults objectForKey:KEY_USER_DEFAULT_MOBILE]]
                                            delegateForProtocol:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:KEY_USER_DEFAULT_IS_ENTERING_BACKGROUND]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO
                                                forKey:KEY_USER_DEFAULT_IS_ENTERING_BACKGROUND];
        return;
    }
    
    NSMutableArray *barButtons = [[[self navigationItem] leftBarButtonItems] mutableCopy];
    if ([barButtons count] < 2) {
        GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
        [barButtons addObject:[globalMethods getProfileImageBarButtonItemWithTarget:self]];
        
        [[self navigationItem] setLeftBarButtonItems:[barButtons copy]];
    }
    
    if ([self nidFromNotification] && [[self nidFromNotification] length] > 0) {
        [self performSegueWithIdentifier:@"NotificationsHomePageSegue"
                                  sender:self];
    } else if ([[NSUserDefaults standardUserDefaults] boolForKey:KEY_USER_DEFAULT_CHECK_OPEN_RIDES]) {
        //[self fetchPools];
    }
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    if ([userDefault boolForKey:KEY_USER_DEFAULT_FIRST_LOGIN_CLUB]) {
        [userDefault setBool:NO
                      forKey:KEY_USER_DEFAULT_FIRST_LOGIN_CLUB];
        
        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main"
                                                             bundle:nil];
        UINavigationController *clubNavigationController = [storyBoard instantiateViewControllerWithIdentifier:@"MyClubsNavigationController"];
        [[self revealViewController] pushFrontViewController:clubNavigationController
                                                    animated:YES];
    }
}


#pragma mark - NKJPagerViewDataSource

- (NSUInteger)numberOfTabView
{
    return 3;
}

- (UIView *)viewPager:(NKJPagerViewController *)viewPager viewForTabAtIndex:(NSUInteger)index
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.f, 0.f, 160.f, 44.f)];
    
    UIColor *color = [UIColor colorWithRed:0 green:0.478 blue:1 alpha:1];
    label.backgroundColor = color;
    
    //label.backgroundColor = [UIColor blueColor];
    
    label.font = [UIFont systemFontOfSize:13.0];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    
    NSString *buttonLabel = nil;
    
    switch (index)
    {
        case 0:
            buttonLabel = @"Rides Available";
            break;
        case 1:
            buttonLabel = @"My Rides";
            break;
        case 2:
            buttonLabel = @"Cabs";
            break;
    }
    
    label.text = buttonLabel;
    return label;
}

- (UIViewController *)viewPager:(NKJPagerViewController *)viewPager contentViewControllerForTabAtIndex:(NSUInteger)index
{
    NSString *tabVC = nil;
    
    switch (index)
    {
        case 0:
            tabVC = @"RidesAvailableVC";
            break;
        case 1:
            tabVC = @"MyRidesVC";
            break;
        case 2:
            tabVC = @"CabsVC";
            break;
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:tabVC];
    
    return vc;
}

- (CGFloat)widthOfTabViewWithIndex:(NSInteger)index
{
    return 107.f;
}

#pragma mark - NKJPagerViewDelegate

- (void)viewPager:(NKJPagerViewController *)viewPager didSwitchAtIndex:(NSInteger)index withTabs:(NSArray *)tabs
{
    [UIView animateWithDuration:0.1f
                     animations:^{
                         for (UIView *view in self.tabs) {
                             if (index == view.tag) {
                                 view.alpha = 1.f;
                             } else {
                                 view.alpha = 0.5f;
                             }
                         }
                     }
                     completion:^(BOOL finished){}];
}

- (void)applicationEnteredForeground:(NSNotification *)notification {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:KEY_USER_DEFAULT_IS_ENTERING_BACKGROUND]) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
        
        [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                           endPoint:ENDPOINT_FETCH_UNREAD_NOTIFICATIONS_COUNT
                                                         parameters:[NSString stringWithFormat:@"MobileNumber=%@", [userDefaults objectForKey:KEY_USER_DEFAULT_MOBILE]]
                                                delegateForProtocol:self];
        
        //[self fetchPools];
    }
}

- (void)showActivityIndicatorView {
    
    [self setActivityIndicatorView:[[ActivityIndicatorView alloc] initWithFrame:[[self view] bounds]
                                                               messageToDisplay:PLEASE_WAIT_MESSAGE]];
    [[self view] addSubview:[self activityIndicatorView]];
}

- (void)hideActivityIndicatorView {
    
    if ([self activityIndicatorView] != nil) {
        [[self activityIndicatorView] removeFromSuperview];
    }
}

- (void)checkNotificationSettings {
    
    /*[Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" checkNotificationSettings : %lu isRegisteredForRemoteNotifications : %d", (unsigned long)[[[UIApplication sharedApplication] currentUserNotificationSettings] types], [[UIApplication sharedApplication] isRegisteredForRemoteNotifications]]];*/
    
    if (![[UIApplication sharedApplication] isRegisteredForRemoteNotifications]) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:KEY_USER_DEFAULT_APN_REG_CALLED]) {
            [self registerForNotifications];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Access needed"
                                                                message:@"iShareRyde cannot send you push notifications. Please consider enabling them to take advantage of all the features offered. Enable now?"
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"Cancel", @"Settings", nil];
            [alertView show];
            
            [self setAlertViewNotifications:alertView];
        }
    } else {
        NSString *deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_APN_DEVICE_TOKEN];
        
        if (!deviceToken || [deviceToken length] <= 0) {
            [self registerForNotifications];
        }
    }
    
}

- (void)registerForNotifications {
    [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
    
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES
                                            forKey:KEY_USER_DEFAULT_APN_REG_CALLED];
}

/*- (void)fetchPools {
    [self showActivityIndicatorView];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_FETCH_MY_POOLS
                                                     parameters:[NSString stringWithFormat:@"MobileNumber=%@", [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_MOBILE]]
                                            delegateForProtocol:self];
}*/


#pragma mark - GlobalMethodsAsyncRequestProtocol methods

- (void)asyncRequestComplete:(GlobalMethods *)sender
                        data:(NSDictionary *)data {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self hideActivityIndicatorView];
        
        NSString *error = [data valueForKey:KEY_ERROR_ASYNC_REQUEST];
        
        if([error isEqualToString:ERROR_CONNECTION_VALUE]) {
            [self makeToastWithMessage:NO_INTERNET_ERROR_MESSAGE];
        } else if ([error isEqualToString:ERROR_DATA_NIL_VALUE]) {
            [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
        } else if ([error isEqualToString:ERROR_UNAUTHORIZED_ACCESS]) {
            [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
        } else {
            NSString *endPoint = [data valueForKey:KEY_ENDPOINT_ASYNC_CONNECTION];
            if ([endPoint isEqualToString:ENDPOINT_FETCH_UNREAD_NOTIFICATIONS_COUNT]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                [[self navigationItem] setRightBarButtonItem:[[[GlobalMethods alloc] init] getNotificationsBarButtonItemWithTarget:self
                                                                                                          unreadNotificationsCount:[response intValue]]];
            }
        }
    });
}

- (void)makeToastWithMessage:(NSString *)message {
    
    if ([self toastLabel]) {
        [[self toastLabel] removeFromSuperview];
    }
    
    [self setToastLabel:[[ToastLabel alloc] initToastWithFrame:[[self view] bounds]
                                                    andMessage:message]];
    
    [[self view] addSubview:[self toastLabel]];
    
    UIViewAnimationOptions optionsForToast = UIViewAnimationOptionCurveLinear;
    
    [UIView animateWithDuration:(TOAST_DELAY * 2)
                          delay:0.0
                        options:optionsForToast
                     animations:^{
                         [[self toastLabel] setAlpha:1.0f];
                     }
                     completion:^(BOOL finished) {
                         
                         if (finished)
                         {
                             [UIView animateWithDuration:TOAST_DELAY
                                                   delay:0.0
                                                 options:optionsForToast
                                              animations:^{
                                                  [[self toastLabel] setAlpha:0.0f];
                                              }
                                              completion:^(BOOL finished) {
                                                  [[self toastLabel] removeFromSuperview];
                                              }];
                         }
                         
                     }];
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"HomeProfileSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[MyProfileViewController class]]) {
            [(MyProfileViewController *)[segue destinationViewController] setChangeProfilePicture:YES];
        }
    }
}

- (IBAction)notificationsBarButtonItemPressed {
    
    [self performSegueWithIdentifier:@"NotificationsHomePageSegue"
                              sender:self];
}

- (IBAction)profileImageBarButtonItemPressed {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Profile Picture"
                                                        message:@"Do you want to change your profile picture?"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Yes", @"No", nil];
    [self setAlertViewProfileImage:alertView];
    [alertView show];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    
    if (alertView == [self alertViewNotifications]) {
        if ([buttonTitle isEqualToString:@"Cancel"]) {
            
        } else if ([buttonTitle isEqualToString:@"Settings"]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
    } else if (alertView == [self alertViewProfileImage]) {
        if ([buttonTitle isEqualToString:@"Yes"]) {
            [self performSegueWithIdentifier:@"HomeProfileSegue"
                                      sender:self];
        }
    }
}

@end
