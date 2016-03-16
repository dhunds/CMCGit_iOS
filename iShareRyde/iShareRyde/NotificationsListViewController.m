//
//  NotificationsListViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 25/09/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import "NotificationsListViewController.h"
#import "GlobalMethods.h"
#import "ActivityIndicatorView.h"
#import "ToastLabel.h"
#import "Logger.h"
#import "NotificationsTableViewCell.h"
#import "RideDetailsViewController.h"
#import "RideDetailsMemberViewController.h"
#import "MyClubsViewController.h"
#import "CabRatingViewController.h"
#import "ShowLocationViewController.h"
#import <Google/Analytics.h>

@interface NotificationsListViewController () <GlobalMethodsAsyncRequestProtocol, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIAlertViewDelegate, CabRatingViewControllerProtocol>

@property (weak, nonatomic) IBOutlet UITableView *tableViewNotifications;

@property (strong, nonatomic) NSString *mobileNumber;

@property (strong, nonatomic) NSArray *notificationsDataArray;

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) UIAlertView *alertViewClearAllNotifications, *alertViewRideRefer, *alertViewClubRefer;

@end

@implementation NotificationsListViewController

- (NSString *)TAG {
    return @"NotificationsListViewController";
}

#pragma mark - View Controller Life Cycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [self setMobileNumber:[userDefaults objectForKey:KEY_USER_DEFAULT_MOBILE]];
    
    UIButton *button =  [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"clear_all_notifications"]
            forState:UIControlStateNormal];
    [button addTarget:self
               action:@selector(clearAllPressed)
     forControlEvents:UIControlEventTouchUpInside];
    
    [button setFrame:CGRectMake(0, 0, 30, 30)];
    
    UIBarButtonItem *barButtonClear = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    button =  [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"mark_all_notifications"]
            forState:UIControlStateNormal];
    [button addTarget:self
               action:@selector(markAllPressed)
     forControlEvents:UIControlEventTouchUpInside];
    
    [button setFrame:CGRectMake(0, 0, 30, 30)];
    
    UIBarButtonItem *barButtonMark = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    [[self navigationItem] setRightBarButtonItems:[NSArray arrayWithObjects: barButtonMark, barButtonClear, nil]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self fetchNotifications];
    
//    CGRect frame = [[self tableViewNotifications] frame];
//    [Logger logDebug:[self TAG]
//             message:[NSString stringWithFormat:@" viewDidAppear : (%1.4f, %1.4f)", frame.size.width, frame.size.height]];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName
           value:[self TAG]];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
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
    
    if ([[segue identifier] isEqualToString:@"NotifToRideSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[RideDetailsViewController class]]) {
            [(RideDetailsViewController *)[segue destinationViewController] setDictionaryRideDetails:sender];
        }
    } else if ([[segue identifier] isEqualToString:@"NotifToRideMemberSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[RideDetailsMemberViewController class]]) {
            [(RideDetailsMemberViewController *)[segue destinationViewController] setDictionaryRideDetails:sender];
        }
    } else if ([[segue identifier] isEqualToString:@"NotifToClubsSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[MyClubsViewController class]]) {
            
        }
    } else if ([[segue identifier] isEqualToString:@"CabRatingSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[CabRatingViewController class]]) {
            
            NSString *cabAndNotifID = sender;
            NSArray *array = [cabAndNotifID componentsSeparatedByString:@"-"];
            
            [(CabRatingViewController *)[segue destinationViewController] setCabID:[array firstObject]];
            [(CabRatingViewController *)[segue destinationViewController] setNid:[array lastObject]];
            [(CabRatingViewController *)[segue destinationViewController] setDelegateCabRatingVCProtocol:self];
        }
    } else if ([[segue identifier] isEqualToString:@"ShareLocationSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[ShowLocationViewController class]]) {
            [(ShowLocationViewController *)[segue destinationViewController] setDictionaryNotification:sender];
        }
    }
}

#pragma mark - IBAction methods

- (IBAction)clearAllPressed {
    
    if ([[self notificationsDataArray] count] > 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Clear all"
                                                            message:@"Are you sure you want to clear all notifications? To remove individual notification, swipe them"
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Yes", @"No", nil];
        [self setAlertViewClearAllNotifications:alertView];
        [alertView show];
    } else {
        [self makeToastWithMessage:@"No notifications to clear!"];
    }
    
}

- (IBAction)markAllPressed {
    
    if ([[self notificationsDataArray] count] > 0) {
        [self showActivityIndicatorView];
        
        GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
        [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                           endPoint:ENDPOINT_UPDATE_ALL_NOTIFICATIONS_READ
                                                         parameters:[NSString stringWithFormat:@"MemberNumber=%@", [self mobileNumber]]
                                                delegateForProtocol:self];
    } else {
        [self makeToastWithMessage:@"No notifications to mark!"];
    }
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    
    if (alertView == [self alertViewClearAllNotifications]) {
        if ([buttonTitle isEqualToString:@"Yes"]) {
            [self showActivityIndicatorView];
            
            GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
            [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                               endPoint:ENDPOINT_CLEAR_ALL_NOTIFICATIONS
                                                             parameters:[NSString stringWithFormat:@"MemberNumber=%@", [self mobileNumber]]
                                                    delegateForProtocol:self];
        }
        //    else if ([buttonTitle isEqualToString:@"No"]) {
        //        
        //    }
    } else if (alertView == [self alertViewRideRefer]) {
        
        NSString *acceptReject = @"";
        if ([buttonTitle isEqualToString:@"Yes"]) {
            acceptReject = @"Yes";
        } else if ([buttonTitle isEqualToString:@"No"]) {
            acceptReject = @"No";
        }
        
        [self showActivityIndicatorView];
        
        NSDictionary *dictionary = [[self notificationsDataArray] objectAtIndex:[alertView tag]];
        
        GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
        [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                           endPoint:ENDPOINT_REFER_FRIEND_RIDE_STEP_TWO
                                                         parameters:[NSString stringWithFormat:@"RefId=%@&OwnerName=%@&OwnerNumber=%@&Accepted=%@", [dictionary objectForKey:@"RefId"], [dictionary objectForKey:@"ReceiveMemberName"], [dictionary objectForKey:@"ReceiveMemberNumber"], acceptReject]
                                                delegateForProtocol:self];
    } else if (alertView == [self alertViewClubRefer]) {
        NSString *acceptReject = @"";
        if ([buttonTitle isEqualToString:@"Yes"]) {
            acceptReject = @"Yes";
        } else if ([buttonTitle isEqualToString:@"No"]) {
            acceptReject = @"No";
        }
        
        [self showActivityIndicatorView];
        
        NSDictionary *dictionary = [[self notificationsDataArray] objectAtIndex:[alertView tag]];
        
        GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
        [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                           endPoint:ENDPOINT_REFER_USERS_CLUB_STEP_TWO
                                                         parameters:[NSString stringWithFormat:@"RefId=%@&OwnerName=%@&OwnerNumber=%@&Accepted=%@", [dictionary objectForKey:@"RefId"], [dictionary objectForKey:@"ReceiveMemberName"], [dictionary objectForKey:@"ReceiveMemberNumber"], acceptReject]
                                                delegateForProtocol:self];
    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self notificationsDataArray] count];
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    
    UIView *footerView = [[UIView alloc] init];
    [footerView setBackgroundColor:[UIColor clearColor]];
    
    return footerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    CGRect frameTableView = [[self tableViewNotifications] frame];
    return frameTableView.size.height / 50.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NotificationsTableViewCell *cell;
    static NSString *reuseIdentifier = @"NotificationsTableViewCell";
    cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (!cell) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
//                                      reuseIdentifier:reuseIdentifier];
        cell = [[NotificationsTableViewCell alloc] init];
    }
    
//    [Logger logDebug:[self TAG]
//             message:[NSString stringWithFormat:@" cellForRowAtIndexPath : %@", [indexPath description]]];
    
    [[cell textViewDescription] setText:[[[self notificationsDataArray] objectAtIndex:indexPath.section] objectForKey:@"Message"]];
    [[cell textViewDescription] setTextColor:[UIColor whiteColor]];
    [[cell textViewDescription] setFont:[UIFont systemFontOfSize:15.0]];
    [[cell textViewDescription] setDelegate:self];
    [[cell textViewDescription] setTag:indexPath.section];
    
    NSString *dateTimeString = [[[self notificationsDataArray] objectAtIndex:indexPath.section] objectForKey:@"DateTime"];
    NSArray *dateTimeArray = [dateTimeString componentsSeparatedByString:@" "];
    
    [[cell labelDate] setText:[dateTimeArray firstObject]];
    [[cell labelTime] setText:[dateTimeArray lastObject]];
    
    if ([[[[self notificationsDataArray] objectAtIndex:indexPath.section] objectForKey:@"NotificationType"] isEqualToString:@"Share_LocationUpdate"]) {
        [[cell imageViewNotificationType] setImage:[UIImage imageNamed:@"location_icon_notif"]];
    } else {
        [[cell imageViewNotificationType] setImage:[UIImage imageNamed:@"add_icon_notif"]];
    }
    
    if ([[[[self notificationsDataArray] objectAtIndex:indexPath.section] objectForKey:@"Status"] isEqualToString:@"U"]) {
        [[cell imageViewUnread] setHidden:NO];
    } else {
        [[cell imageViewUnread] setHidden:YES];
    }
    
//    [self configureBasicCell:cell
//                 atIndexPath:indexPath];
    
    return cell;
}

//- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    return 200.0f;
//}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //5s    (304.0000, 540.0000)
    //6s    (356.0000, 634.0000)
    //6s+   (393.3333, 699.3333)
    
    CGRect frameTableView = [[self tableViewNotifications] frame];
    return frameTableView.size.height / 3.5;
//    return 200.0f;
}


//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    return [self heightForBasicCellAtIndexPath:indexPath];
//}
//
//- (CGFloat)heightForBasicCellAtIndexPath:(NSIndexPath *)indexPath {
//    static NotificationsTableViewCell *sizingCell = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        sizingCell = [[self tableViewNotifications] dequeueReusableCellWithIdentifier:@"NotificationsTableViewCell"];
//    });
//    
//    [self configureBasicCell:sizingCell atIndexPath:indexPath];
//    return [self calculateHeightForConfiguredSizingCell:sizingCell];
//}
//
//- (CGFloat)calculateHeightForConfiguredSizingCell:(UITableViewCell *)sizingCell {
//    [sizingCell setNeedsLayout];
//    [sizingCell layoutIfNeeded];
//    
//    CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
//    return size.height + 1.0f; // Add 1.0f for the cell separator height
//}
//
//- (void)configureBasicCell:(NotificationsTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
//    [[cell labelDescription] setText:[[[self notificationsDataArray] objectAtIndex:indexPath.row] objectForKey:@"Message"]];
//}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" didSelectRowAtIndexPath : %lu", (long)indexPath.section]];
    
    [self rowSelectedAtIndex:indexPath.section];
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:NO];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
        [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                           endPoint:ENDPOINT_DELETE_NOTIFICATION
                                                         parameters:[NSString stringWithFormat:@"MemberNumber=%@&NID=%@", [self mobileNumber], [[[self notificationsDataArray] objectAtIndex:indexPath.section] objectForKey:@"NotificationId"]]
                                                delegateForProtocol:self];
        
        NSMutableArray *mutableArray = [[self notificationsDataArray] mutableCopy];
        [mutableArray removeObjectAtIndex:indexPath.section];
        
        [self setNotificationsDataArray:[mutableArray copy]];
        
        [[self tableViewNotifications] reloadData];
    }
}

#pragma mark - UITextViewDelegate methods

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" textViewShouldBeginEditing : %lu", (long)[textView tag]]];
    
    [self rowSelectedAtIndex:[textView tag]];
    
    return NO;
}

#pragma mark - Private methods

- (void)fetchNotifications {
    
    [self showActivityIndicatorView];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_FETCH_ALL_NOTIFICATIONS
                                                     parameters:[NSString stringWithFormat:@"MobileNumber=%@", [self mobileNumber]]
                                            delegateForProtocol:self];
    
}

- (void)rowSelectedAtIndex:(NSInteger)index {
    
    [[(NotificationsTableViewCell *)[[self tableViewNotifications] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0
                                                                                                            inSection:index]] imageViewUnread] setHidden:YES];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_UPDATE_NOTIFICATION_STATUS_READ
                                                     parameters:[NSString stringWithFormat:@"rnum=%@&nid=%@", [[[self notificationsDataArray] objectAtIndex:index] objectForKey:@"ReceiveMemberNumber"], [[[self notificationsDataArray] objectAtIndex:index] objectForKey:@"NotificationId"]]
                                            delegateForProtocol:self];
    
    NSDictionary *dictionaryNotification = [[self notificationsDataArray] objectAtIndex:index];
    NSString *notificationType = [dictionaryNotification objectForKey:@"NotificationType"];
    
    if ([notificationType isEqualToString:@"CabId_Invited"] || [notificationType isEqualToString:@"CabId_Joined"] || [notificationType isEqualToString:@"CabId_UpdateLocation"] || [notificationType isEqualToString:@"CabId_Dropped"] || [notificationType isEqualToString:@"CabId_Left"] || [notificationType isEqualToString:@"CabId_CancelRide"] || [notificationType isEqualToString:@"CabId_Approved"] || [notificationType isEqualToString:@"CabId_Rejected"] || [notificationType isEqualToString:@"tripcompleted"]) {
        
        [self showActivityIndicatorView];
        
        GlobalMethods *globalMethodsPool = [[GlobalMethods alloc] init];
        [globalMethodsPool makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                               endPoint:ENDPOINT_GOTO_POOL
                                                             parameters:[NSString stringWithFormat:@"CabId=%@", [[[self notificationsDataArray] objectAtIndex:index] objectForKey:@"CabId"]]
                                                    delegateForProtocol:self];
    } else if ([notificationType isEqualToString:@"CabId_Refered"]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                            message:[NSString stringWithFormat:@"Do you want to invite friend refered by %@ for this ride?", [dictionaryNotification objectForKey:@"SentMemberName"]]
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Yes", @"No", nil];
        [self setAlertViewRideRefer:alertView];
        [alertView show];
    } else if ([notificationType isEqualToString:@"Share_LocationUpdate"]) {
        [self performSegueWithIdentifier:@"ShareLocationSegue"
                                  sender:dictionaryNotification];
    } else if ([notificationType isEqualToString:@"PoolId_Added"] || [notificationType isEqualToString:@"PoolId_Removed"] || [notificationType isEqualToString:@"PoolId_Left"] || [notificationType isEqualToString:@"PoolId_ClubDeleted"] || [notificationType isEqualToString:@"PoolId_Approved"] || [notificationType isEqualToString:@"PoolId_Rejected"]) {
        [self performSegueWithIdentifier:@"NotifToClubsSegue"
                                  sender:self];
    } else if ([notificationType isEqualToString:@"PoolId_Refered"]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                            message:[NSString stringWithFormat:@"Do you want to add friend refered by %@", [dictionaryNotification objectForKey:@"SentMemberName"]]
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Yes", @"No", nil];
        [self setAlertViewClubRefer:alertView];
        [alertView show];
    } else if ([notificationType isEqualToString:@"Cab_Rating"]) {
        [self performSegueWithIdentifier:@"CabRatingSegue"
                                  sender:[NSString stringWithFormat:@"%@-%@", [dictionaryNotification objectForKey:@"CabId"], [dictionaryNotification objectForKey:@"NotificationId"]]];
    }
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Notification Opened"
                                                          action:@"Notification Opened"
                                                           label:@"Notification Opened"
                                                           value:nil] build]];
    
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

#pragma mark - CabRatingViewControllerProtocol methods

- (void)cabRatingSubmittedForSender:(CabRatingViewController *)sender
                  andNotificationID:(NSString *)nid {
    
    int index = -1;
    for (int i = 0; i < [[self notificationsDataArray] count]; i++) {
        if ([[[[self notificationsDataArray] objectAtIndex:i] objectForKey:@"NotificationId"] isEqualToString:nid]) {
            index = i;
            break;
        }
    }
    
    if (index != -1) {
        GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
        [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                           endPoint:ENDPOINT_DELETE_NOTIFICATION
                                                         parameters:[NSString stringWithFormat:@"MemberNumber=%@&NID=%@", [self mobileNumber], [[[self notificationsDataArray] objectAtIndex:index] objectForKey:@"NotificationId"]]
                                                delegateForProtocol:self];
        
        NSMutableArray *mutableArray = [[self notificationsDataArray] mutableCopy];
        [mutableArray removeObjectAtIndex:index];
        
        [self setNotificationsDataArray:[mutableArray copy]];
        
        [[self tableViewNotifications] reloadData];
        
        [self makeToastWithMessage:@"Thank you for the feedback!"];
    } else {
        [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
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
            if ([endPoint isEqualToString:ENDPOINT_FETCH_ALL_NOTIFICATIONS]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                if([response isEqualToString:@"No Notification !!"]) {
                    [self setNotificationsDataArray:[NSArray array]];
                    [[self tableViewNotifications] reloadData];
                    
                    [self makeToastWithMessage:response];
                } else {
                    NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                    NSError *error = nil;
                    NSArray *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                          options:NSJSONReadingMutableContainers
                                                                            error:&error];
                    
                    if(!error) {
                        
                        //                        [Logger logDebug:[self TAG]
                        //                                 message:[NSString stringWithFormat:@" %@ parsedJson : %@", endPoint, [[parsedJson objectAtIndex:1] objectForKey:@"Message"]]];
                        
                        [self setNotificationsDataArray:parsedJson];
                        
                        [[self tableViewNotifications] reloadData];
                        
                        if ([self nidFromNotification] && [[self nidFromNotification] length] > 0) {
                            NSUInteger index = -1;
                            for (int i = 0; i < [[self notificationsDataArray] count]; i++) {
                                if ([[[[self notificationsDataArray] objectAtIndex:i] objectForKey:@"NotificationId"] isEqualToString:[self nidFromNotification]]) {
                                    index = i;
                                    break;
                                }
                            }
                            
                            if (index != -1) {
                                [self rowSelectedAtIndex:index];
                                [self setNidFromNotification:nil];
                            }
                        }
                        
                    } else {
                        [Logger logError:[self TAG]
                                 message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                        [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                    }
                }
            } else if ([endPoint isEqualToString:ENDPOINT_UPDATE_NOTIFICATION_STATUS_READ]) {
                
            } else if ([endPoint isEqualToString:ENDPOINT_UPDATE_ALL_NOTIFICATIONS_READ]) {
                [self fetchNotifications];
            } else if ([endPoint isEqualToString:ENDPOINT_CLEAR_ALL_NOTIFICATIONS]) {
                [self fetchNotifications];
            } else if ([endPoint isEqualToString:ENDPOINT_DELETE_NOTIFICATION]) {
                
            } else if ([endPoint isEqualToString:ENDPOINT_GOTO_POOL]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                if([response isEqualToString:@"This Ride no longer exist"]) {
                    [self makeToastWithMessage:@"This ride no longer exists!"];
                } else {
                    NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                    NSError *error = nil;
                    NSArray *parsedJsonArray = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                          options:NSJSONReadingMutableContainers
                                                                            error:&error];
                    
                    NSDictionary *parsedJson = [parsedJsonArray firstObject];
                    
                    if(!error) {
                        
                        //                        [Logger logDebug:[self TAG]
                        //                                 message:[NSString stringWithFormat:@" %@ parsedJson : %@", endPoint, [[parsedJson objectAtIndex:1] objectForKey:@"Message"]]];
                        if ([[parsedJson objectForKey:@"MobileNumber"] isEqualToString:[self mobileNumber]]) {
                            [self performSegueWithIdentifier:@"NotifToRideSegue"
                                                      sender:parsedJson];
                        } else {
                            [self performSegueWithIdentifier:@"NotifToRideMemberSegue"
                                                      sender:parsedJson];
                        }
                    } else {
                        [Logger logError:[self TAG]
                                 message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                        [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                    }
                }
            } else if ([endPoint isEqualToString:ENDPOINT_REFER_FRIEND_RIDE_STEP_TWO]) {
                [self fetchNotifications];
            } else if ([endPoint isEqualToString:ENDPOINT_REFER_USERS_CLUB_STEP_TWO]) {
                [self fetchNotifications];
            }
        }
    });
}

@end
