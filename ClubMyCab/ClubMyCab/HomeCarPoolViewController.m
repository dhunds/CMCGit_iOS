//
//  HomeCarPoolViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 04/01/16.
//  Copyright © 2016 ClubMyCab. All rights reserved.
//

#import "HomeCarPoolViewController.h"
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

@interface HomeCarPoolViewController () <GlobalMethodsAsyncRequestProtocol, UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) UIAlertView *alertViewNotifications;

@property (strong, nonatomic) NSArray *arrayRideInvitations;
@property (weak, nonatomic) IBOutlet UILabel *labelRidesAvailable;
@property (weak, nonatomic) IBOutlet UITableView *tableViewRideInvitations;

@end

@implementation HomeCarPoolViewController

- (NSString *)TAG {
    return @"HomeCarPoolViewController";
}

- (NSArray *)arrayRideInvitations {
    
    if (!_arrayRideInvitations) {
        _arrayRideInvitations = [NSArray array];
    }
    
    return _arrayRideInvitations;
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
    
    [self checkNotificationSettings];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_FETCH_UNREAD_NOTIFICATIONS_COUNT
                                                     parameters:[NSString stringWithFormat:@"MobileNumber=%@", [userDefaults objectForKey:KEY_USER_DEFAULT_MOBILE]]
                                            delegateForProtocol:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([self nidFromNotification] && [[self nidFromNotification] length] > 0) {
        [self performSegueWithIdentifier:@"NotificationsHomePageSegue"
                                  sender:self];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([[segue identifier] isEqualToString:@"NotificationsHomePageSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[NotificationsListViewController class]]) {
            if ([self nidFromNotification] && [[self nidFromNotification] length] > 0) {
                [(NotificationsListViewController *)[segue destinationViewController] setNidFromNotification:[self nidFromNotification]];
                [self setNidFromNotification:nil];
            }
        }
    } else if ([[segue identifier] isEqualToString:@"CarPoolToHomeSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[HomePageViewController class]]) {
            [(HomePageViewController *)[segue destinationViewController] setSegueType:sender];
        }
    } else if ([[segue identifier] isEqualToString:@"RideDetailsInvitationSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[RideDetailsViewController class]]) {
            [(RideDetailsViewController *)[segue destinationViewController] setDictionaryRideDetails:sender];
        }
    } else if ([[segue identifier] isEqualToString:@"RideDetailsInvitationMemberSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[RideDetailsMemberViewController class]]) {
            [(RideDetailsMemberViewController *)[segue destinationViewController] setDictionaryRideDetails:sender];
        }
    }
}

#pragma mark - IBAction methods

- (IBAction)notificationsBarButtonItemPressed {
    
    [self performSegueWithIdentifier:@"NotificationsHomePageSegue"
                              sender:self];
}

- (IBAction)tapGestureCarPool:(UITapGestureRecognizer *)sender {
    [self performSegueWithIdentifier:@"CarPoolToHomeSegue"
                              sender:HOME_SEGUE_TYPE_CAR_POOL];
}

- (IBAction)tapGestureCabShare:(UITapGestureRecognizer *)sender {
    [self performSegueWithIdentifier:@"CarPoolToHomeSegue"
                              sender:HOME_SEGUE_TYPE_SHARE_CAB];
}

- (IBAction)bookCabPressed:(UIButton *)sender {
    [self performSegueWithIdentifier:@"CarPoolToHomeSegue"
                              sender:HOME_SEGUE_TYPE_BOOK_CAB];
}

#pragma mark - Private methods

- (void)makeToastWithMessage:(NSString *)message {
    
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

- (void)checkNotificationSettings {
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" checkNotificationSettings : %lu isRegisteredForRemoteNotifications : %d", (unsigned long)[[[UIApplication sharedApplication] currentUserNotificationSettings] types], [[UIApplication sharedApplication] isRegisteredForRemoteNotifications]]];
    
    if (![[UIApplication sharedApplication] isRegisteredForRemoteNotifications]) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:KEY_USER_DEFAULT_APN_REG_CALLED]) {
            [self registerForNotifications];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Access needed"
                                                                message:@"ClubMyCab cannot send you push notifications. Please consider enabling them to take advantage of all the features offered. Enable now?"
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

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    
    if (alertView == [self alertViewNotifications]) {
        if ([buttonTitle isEqualToString:@"Cancel"]) {
            
        } else if ([buttonTitle isEqualToString:@"Settings"]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
    }
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
                
                GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
                [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                                   endPoint:ENDPOINT_RIDE_INVITATIONS
                                                                 parameters:[NSString stringWithFormat:@"mobileNumber=%@", [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_MOBILE]]
                                                        delegateForProtocol:self];
            } else if ([endPoint isEqualToString:ENDPOINT_RIDE_INVITATIONS]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                      options:NSJSONReadingMutableContainers
                                                                        error:&error];
                if (!error) {
                    if (![[parsedJson objectForKey:@"status"] isEqualToString:@"fail"]) {
                        NSArray *array = [parsedJson objectForKey:@"data"];
                        
                        [self setArrayRideInvitations:array];
                    }
                    
                    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
                    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                                       endPoint:ENDPOINT_RIDE_INVITATIONS_CAR_POOL
                                                                     parameters:[NSString stringWithFormat:@"mobileNumber=%@", [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_MOBILE]]
                                                            delegateForProtocol:self];
                    
                } else {
                    [Logger logError:[self TAG]
                             message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                    [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                }
            } else if ([endPoint isEqualToString:ENDPOINT_RIDE_INVITATIONS_CAR_POOL]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                      options:NSJSONReadingMutableContainers
                                                                        error:&error];
                if (!error) {
                    if (![[parsedJson objectForKey:@"status"] isEqualToString:@"fail"]) {
                        NSArray *array = [parsedJson objectForKey:@"data"];
                        
                        if ([[self arrayRideInvitations] count] > 0) {
                            NSArray *arrayNew = [[self arrayRideInvitations] arrayByAddingObjectsFromArray:array];
                            
                            [self setArrayRideInvitations:arrayNew];
                        } else {
                            [self setArrayRideInvitations:array];
                        }
                    }
                    
                    [Logger logDebug:[self TAG]
                             message:[NSString stringWithFormat:@" arrayRideInvitations : %@", [[self arrayRideInvitations] description]]];
                    
                    if ([[self arrayRideInvitations] count] > 0) {
                        [[self labelRidesAvailable] setHidden:NO];
                        [[self tableViewRideInvitations] setHidden:NO];
                        
                        [[self tableViewRideInvitations] reloadData];
                    } else {
                        [[self labelRidesAvailable] setHidden:YES];
                        [[self tableViewRideInvitations] setHidden:YES];
                    }
                } else {
                    [Logger logError:[self TAG]
                             message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                    [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                }
                
            }
        }
    });
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self arrayRideInvitations] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    
    UIView *footerView = [[UIView alloc] init];
    [footerView setBackgroundColor:[UIColor clearColor]];
    
    return footerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    CGRect frameTableView = [tableView frame];
    return frameTableView.size.height / 30.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MyRidesTableViewCell *cell;
    
    static NSString *reuseIdentifier = @"MyRidesTableViewCell";
    cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (!cell) {
        cell = [[MyRidesTableViewCell alloc] init];
    }
    
    NSDictionary *dictionaryRide = [[self arrayRideInvitations] objectAtIndex:indexPath.section];
    
    [[cell labelFromTo] setText:[NSString stringWithFormat:@"    %@ > %@", [dictionaryRide objectForKey:@"FromShortName"], [dictionaryRide objectForKey:@"ToShortName"]]];
    [[cell labelDate] setText:[dictionaryRide objectForKey:@"TravelDate"]];
    [[cell labelTime] setText:[dictionaryRide objectForKey:@"TravelTime"]];
    
    NSString *seatStatus = [dictionaryRide objectForKey:@"Seat_Status"];
    NSArray *array = [seatStatus componentsSeparatedByString:@"/"];
    [[cell labelTotalSeats] setText:[NSString stringWithFormat:@"Total seats : %@", [array lastObject]]];
    [[cell labelAvailableSeats] setText:[NSString stringWithFormat:@"Available : %d", ([[array lastObject] intValue] - [[array firstObject] intValue])]];
    
    if ([[dictionaryRide objectForKey:@"rideType"] isEqualToString:@"1"]) {
        [[cell labelOwnerName] setText:[NSString stringWithFormat:@"%@ (Car Pool)", [dictionaryRide objectForKey:@"OwnerName"]]];
        [[cell labelPerSeatCharges] setText:[NSString stringWithFormat:@"Per seat charge : \u20B9%@/km", [dictionaryRide objectForKey:@"perKmCharge"]]];
    } else {
        [[cell labelOwnerName] setText:[NSString stringWithFormat:@"%@ (Cab Share)", [dictionaryRide objectForKey:@"OwnerName"]]];
    }
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGRect frameTableView = [tableView frame];
    return frameTableView.size.height / 2.0;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:NO];
    
    if ([[[[self arrayRideInvitations] objectAtIndex:indexPath.section] objectForKey:@"MobileNumber"] isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_MOBILE]]) {
        [self performSegueWithIdentifier:@"RideDetailsInvitationSegue"
                                  sender:[[self arrayRideInvitations] objectAtIndex:indexPath.section]];
    } else {
        [self performSegueWithIdentifier:@"RideDetailsInvitationMemberSegue"
                                  sender:[[self arrayRideInvitations] objectAtIndex:indexPath.section]];
    }
}

@end