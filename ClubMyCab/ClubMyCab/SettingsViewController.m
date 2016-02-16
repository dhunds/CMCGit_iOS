//
//  SettingsViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 11/09/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import "SettingsViewController.h"
#import "SWRevealViewController.h"
#import "NotificationsListViewController.h"
#import "ToastLabel.h"
#import "ActivityIndicatorView.h"
#import "GlobalMethods.h"
#import "Logger.h"
#import "FavoriteLocationsViewController.h"
#import "MyProfileViewController.h"

@interface SettingsViewController () <GlobalMethodsAsyncRequestProtocol>

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) NSString *mobileNumber;

@property (weak, nonatomic) IBOutlet UISwitch *switchNotification;
//@property (weak, nonatomic) IBOutlet UIButton *buttonHereIAm;
//@property (weak, nonatomic) IBOutlet UILabel *labelInterval;
@property (weak, nonatomic) IBOutlet UIButton *buttonFavoriteLocations;

@property (strong, nonatomic) UIAlertView *alertViewProfileImage;

@end

@implementation SettingsViewController

#define NOTIFICATION_STATUS_ON              @"on"
#define NOTIFICATION_STATUS_OFF             @"off"

- (NSString *)TAG {
    return @"SettingsViewController";
}

#pragma mark - View Controller Life Cycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    SWRevealViewController *revealViewController = [self revealViewController];
    if (revealViewController) {
        [[self barButtonItem] setTarget:revealViewController];
        [[self barButtonItem] setAction:@selector(revealToggle:)];
        [[self view] addGestureRecognizer:[[self revealViewController] panGestureRecognizer]];
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [self setMobileNumber:[userDefaults objectForKey:KEY_USER_DEFAULT_MOBILE]];
    
    NSString *notifStatus = [userDefaults objectForKey:KEY_USER_DEFAULT_PUSH_NOTIF_STATUS];
    
    if (notifStatus) {
        if ([notifStatus isEqualToString:NOTIFICATION_STATUS_ON]) {
            [[self switchNotification] setOn:YES];
        } else if ([notifStatus isEqualToString:NOTIFICATION_STATUS_OFF]) {
            [[self switchNotification] setOn:NO];
        }
    } else {
        [userDefaults setObject:NOTIFICATION_STATUS_ON
                         forKey:KEY_USER_DEFAULT_PUSH_NOTIF_STATUS];
        [[self switchNotification] setOn:YES];
    }
    
//    NSString *shareInterval = [userDefaults objectForKey:KEY_USER_DEFAULT_SHARE_LOCATION_INTERVAL];
//    if (shareInterval) {
//        [[self labelInterval] setText:shareInterval];
//    } else {
//        [userDefaults setObject:VALUE_USER_DEFAULT_SHARE_LOCATION_INTERVAL_5
//                         forKey:KEY_USER_DEFAULT_SHARE_LOCATION_INTERVAL];
//        [[self labelInterval] setText:VALUE_USER_DEFAULT_SHARE_LOCATION_INTERVAL_5];
//    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_FETCH_UNREAD_NOTIFICATIONS_COUNT
                                                     parameters:[NSString stringWithFormat:@"MobileNumber=%@", [self mobileNumber]]
                                            delegateForProtocol:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSMutableArray *barButtons = [[[self navigationItem] leftBarButtonItems] mutableCopy];
    if ([barButtons count] < 2) {
        GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
        [barButtons addObject:[globalMethods getProfileImageBarButtonItemWithTarget:self]];
        
        [[self navigationItem] setLeftBarButtonItems:[barButtons copy]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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
            } else if ([endPoint isEqualToString:ENDPOINT_UPDATE_PUSH_NOTIF_STATUS]) {
                
            }
        }
    });
}

#pragma mark - IBAction methods

- (IBAction)notificationsBarButtonItemPressed {
    
    [self performSegueWithIdentifier:@"NotificationsSettingsSegue"
                              sender:self];
}

- (IBAction)hereIAmPressed:(UIButton *)sender {
//    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@""
//                                                                             message:@"Please select an interval"
//                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
//    
//    [alertController addAction:[UIAlertAction actionWithTitle:VALUE_USER_DEFAULT_SHARE_LOCATION_INTERVAL_2
//                                                        style:UIAlertActionStyleDefault
//                                                      handler:^(UIAlertAction *action) {
//                                                          [[self labelInterval] setText:VALUE_USER_DEFAULT_SHARE_LOCATION_INTERVAL_2];
//                                                          NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//                                                          [userDefaults setObject:VALUE_USER_DEFAULT_SHARE_LOCATION_INTERVAL_2
//                                                                           forKey:KEY_USER_DEFAULT_SHARE_LOCATION_INTERVAL];
//                                                      }]];
//    
//    [alertController addAction:[UIAlertAction actionWithTitle:VALUE_USER_DEFAULT_SHARE_LOCATION_INTERVAL_5
//                                                        style:UIAlertActionStyleDefault
//                                                      handler:^(UIAlertAction *action) {
//                                                          [[self labelInterval] setText:VALUE_USER_DEFAULT_SHARE_LOCATION_INTERVAL_5];
//                                                          NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//                                                          [userDefaults setObject:VALUE_USER_DEFAULT_SHARE_LOCATION_INTERVAL_5
//                                                                           forKey:KEY_USER_DEFAULT_SHARE_LOCATION_INTERVAL];
//                                                      }]];
//    
//    [alertController addAction:[UIAlertAction actionWithTitle:VALUE_USER_DEFAULT_SHARE_LOCATION_INTERVAL_10
//                                                        style:UIAlertActionStyleDefault
//                                                      handler:^(UIAlertAction *action) {
//                                                          [[self labelInterval] setText:VALUE_USER_DEFAULT_SHARE_LOCATION_INTERVAL_10];
//                                                          NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//                                                          [userDefaults setObject:VALUE_USER_DEFAULT_SHARE_LOCATION_INTERVAL_10
//                                                                           forKey:KEY_USER_DEFAULT_SHARE_LOCATION_INTERVAL];
//                                                      }]];
//    
//    [self presentViewController:alertController
//                       animated:YES
//                     completion:^{}];
}

- (IBAction)notificationsSwitchValueChanged:(UISwitch *)sender {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    
    if ([sender isOn]) {
        [userDefaults setObject:NOTIFICATION_STATUS_ON
                         forKey:KEY_USER_DEFAULT_PUSH_NOTIF_STATUS];
        
        [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                           endPoint:ENDPOINT_UPDATE_PUSH_NOTIF_STATUS
                                                         parameters:[NSString stringWithFormat:@"MobileNumber=%@&PushStatus=%@", [self mobileNumber], NOTIFICATION_STATUS_ON]
                                                delegateForProtocol:self];
    } else {
        [userDefaults setObject:NOTIFICATION_STATUS_OFF
                         forKey:KEY_USER_DEFAULT_PUSH_NOTIF_STATUS];
        
        [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                           endPoint:ENDPOINT_UPDATE_PUSH_NOTIF_STATUS
                                                         parameters:[NSString stringWithFormat:@"MobileNumber=%@&PushStatus=%@", [self mobileNumber], NOTIFICATION_STATUS_OFF]
                                                delegateForProtocol:self];
    }
}

- (IBAction)favoriteLocationsPressed:(UIButton *)sender {
    [self performSegueWithIdentifier:@"FavLocSettingsSegue"
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
    if ([buttonTitle isEqualToString:@"Yes"]) {
        [self performSegueWithIdentifier:@"SettingsProfileSegue"
                                  sender:self];
    }
}

#pragma mark - Private methods

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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"NotificationsClubsSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[NotificationsListViewController class]]) {
            
        }
    } else if ([[segue identifier] isEqualToString:@"FavLocSettingsSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[FavoriteLocationsViewController class]]) {
            
        }
    } else if ([[segue identifier] isEqualToString:@"SettingsProfileSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[MyProfileViewController class]]) {
            [(MyProfileViewController *)[segue destinationViewController] setChangeProfilePicture:YES];
        }
    }
}

@end
