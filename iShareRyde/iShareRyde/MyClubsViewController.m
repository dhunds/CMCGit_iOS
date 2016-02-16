//
//  MyClubsViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 11/09/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import "MyClubsViewController.h"
#import "SWRevealViewController.h"
#import "GlobalMethods.h"
#import "Logger.h"
#import "ActivityIndicatorView.h"
#import "ToastLabel.h"
#import "NotificationsListViewController.h"
#import "MyClubsTableViewCell.h"
#import "MemberOfClubsTableViewCell.h"
#import "GenericContactsViewController.h"
#import "ClubDetailsViewController.h"
#import "MyProfileViewController.h"

@interface MyClubsViewController () <GlobalMethodsAsyncRequestProtocol, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableViewMyClubs;
@property (weak, nonatomic) IBOutlet UITableView *tableViewMemberOfClubs;

@property (strong, nonatomic) NSString *mobileNumber;

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) NSArray *arrayMyClubs, *arrayMemberOfClubs;

@property (strong, nonatomic) UIAlertView *alertViewDeleteClub, *alertViewLeaveClub;
@property (strong, nonatomic) UIAlertView *alertViewProfileImage;

@property (strong, nonatomic) NSString *clubsSegueType;

@end

@implementation MyClubsViewController

- (NSString *)TAG {
    return @"MyClubsViewController";
}

#pragma mark - View Controller Life Cycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [self setMobileNumber:[userDefaults objectForKey:KEY_USER_DEFAULT_MOBILE]];
    
    SWRevealViewController *revealViewController = [self revealViewController];
    if (revealViewController) {
        [[self barButtonItem] setTarget:revealViewController];
        [[self barButtonItem] setAction:@selector(revealToggle:)];
        [[self view] addGestureRecognizer:[[self revealViewController] panGestureRecognizer]];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_FETCH_UNREAD_NOTIFICATIONS_COUNT
                                                     parameters:[NSString stringWithFormat:@"MobileNumber=%@", [self mobileNumber]]
                                            delegateForProtocol:self];
    
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
                
                [self fetchClubs];
            } else if ([endPoint isEqualToString:ENDPOINT_FETCH_CLUBS]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                if (response && [response caseInsensitiveCompare:@"No Users of your Club"] == NSOrderedSame) {
                    [self makeToastWithMessage:@"No groups created yet!!"];
                } else {
                    NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                    NSError *error = nil;
                    NSArray *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                          options:NSJSONReadingMutableContainers
                                                                            error:&error];
                    if (!error) {
//                        [Logger logDebug:[self TAG]
//                                 message:[NSString stringWithFormat:@" parsedJson : %@", parsedJson]];
                        
                        NSMutableArray *mutableMyClubs = [NSMutableArray array];
                        NSMutableArray *mutableMemberOfClubs = [NSMutableArray array];
                        
                        for (int i = 0; i < [parsedJson count]; i++) {
                            if ([[[parsedJson objectAtIndex:i] objectForKey:@"IsPoolOwner"] isEqualToString:@"1"]) {
                                
                                [mutableMyClubs addObject:[parsedJson objectAtIndex:i]];
//                                [Logger logDebug:[self TAG]
//                                         message:[NSString stringWithFormat:@" IsPoolOwner : %@", [[parsedJson objectAtIndex:i] objectForKey:@"NoofMembers"]]];
                            } else {
                                [mutableMemberOfClubs addObject:[parsedJson objectAtIndex:i]];
//                                [Logger logDebug:[self TAG]
//                                         message:[NSString stringWithFormat:@" IsNotPoolOwner : %@", [[parsedJson objectAtIndex:i] objectForKey:@"NoofMembers"]]];
                            }
                        }
                        
                        [self setArrayMyClubs:[mutableMyClubs copy]];
                        [self setArrayMemberOfClubs:[mutableMemberOfClubs copy]];
                        
                        [[self tableViewMyClubs] reloadData];
                        [[self tableViewMemberOfClubs] reloadData];
                        
                    } else {
                        [Logger logError:[self TAG]
                                 message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                        [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                    }
                }
                
                if ([self nidFromNotification] && [[self nidFromNotification] length] > 0) {
                    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
                    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                                       endPoint:ENDPOINT_UPDATE_NOTIFICATION_STATUS_READ
                                                                     parameters:[NSString stringWithFormat:@"rnum=&nid=%@", [self nidFromNotification]]
                                                            delegateForProtocol:self];
                }
                
            } else if ([endPoint isEqualToString:ENDPOINT_DELETE_CLUB] || [endPoint isEqualToString:ENDPOINT_LEAVE_CLUB]) {
                [self fetchClubs];
            } else if ([endPoint isEqualToString:ENDPOINT_UPDATE_NOTIFICATION_STATUS_READ]) {
                
            }
        }
    });
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([[segue identifier] isEqualToString:@"NotificationsClubsSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[NotificationsListViewController class]]) {
            
        }
    } else if ([[segue identifier] isEqualToString:@"ClubsContactsSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[GenericContactsViewController class]]) {
            [(GenericContactsViewController *)[segue destinationViewController] setSegueType:SEGUE_FROM_CREATE_CLUB];
        }
    } else if ([[segue identifier] isEqualToString:@"ClubDetailsSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[ClubDetailsViewController class]]) {
            [(ClubDetailsViewController *)[segue destinationViewController] setDictionaryClubDetails:(NSDictionary *)sender];
            [(ClubDetailsViewController *)[segue destinationViewController] setSegueType:[self clubsSegueType]];
        }
    } else if ([[segue identifier] isEqualToString:@"ClubsProfileSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[MyProfileViewController class]]) {
            [(MyProfileViewController *)[segue destinationViewController] setChangeProfilePicture:YES];
        }
    }
}

#pragma mark - IBAction methods

- (IBAction)notificationsBarButtonItemPressed {
    
    [self performSegueWithIdentifier:@"NotificationsClubsSegue"
                              sender:self];
}

- (IBAction)createNewClubPressed:(UIButton *)sender {
    [self performSegueWithIdentifier:@"ClubsContactsSegue"
                              sender:self];
}

- (IBAction)deleteClubPressed:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Delete Group"
                                                        message:@"Are you sure you want to delete this group?"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Yes", @"No", nil];
    [alertView setTag:[sender tag]];
    [self setAlertViewDeleteClub:alertView];
    [alertView show];
}

- (IBAction)leaveClubPressed:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Leave Group"
                                                        message:@"Are you sure you want to leave this group?"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Yes", @"No", nil];
    [alertView setTag:[sender tag]];
    [self setAlertViewLeaveClub:alertView];
    [alertView show];
}

- (void)lowMembershipWarning {
    
    [[self toastLabel] removeFromSuperview];
    
    [self makeToastWithMessage:@"Low group membership - add/refer more members to improve chances of sharing"];
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
        [self showActivityIndicatorView];
        
        GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
        if (alertView == [self alertViewDeleteClub]) {
            [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                               endPoint:ENDPOINT_DELETE_CLUB
                                                             parameters:[NSString stringWithFormat:@"poolid=%@", [[[self arrayMyClubs] objectAtIndex:[alertView tag]] objectForKey:@"PoolId"]]
                                                    delegateForProtocol:self];
        } else if (alertView == [self alertViewLeaveClub]) {
            [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                               endPoint:ENDPOINT_LEAVE_CLUB
                                                             parameters:[NSString stringWithFormat:@"poolid=%@&MemberNumber=%@", [[[self arrayMemberOfClubs] objectAtIndex:[alertView tag]] objectForKey:@"PoolId"], [self mobileNumber]]
                                                    delegateForProtocol:self];
        } else if (alertView == [self alertViewProfileImage]) {
            [self performSegueWithIdentifier:@"ClubsProfileSegue"
                                      sender:self];
        }
    }
    //    else if ([buttonTitle isEqualToString:@"No"]) {
    //
    //    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (tableView == [self tableViewMyClubs]) {
        return [[self arrayMyClubs] count];
    } else if (tableView == [self tableViewMemberOfClubs]) {
        return [[self arrayMemberOfClubs] count];
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tableView == [self tableViewMyClubs]) {
        
        MyClubsTableViewCell *cell;
        
        static NSString *reuseIdentifier = @"MyClubsTableViewCell";
        cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
        
        if (!cell) {
            cell = [[MyClubsTableViewCell alloc] init];
        }
        
        if ([[[[self arrayMyClubs] objectAtIndex:indexPath.row] objectForKey:@"NoofMembers"] intValue] <= 10) {
            [[cell buttonLowMembership] setHidden:NO];
            [[cell buttonLowMembership] addTarget:self
                                           action:@selector(lowMembershipWarning)
                                 forControlEvents:UIControlEventTouchUpInside];
        } else {
            [[cell buttonLowMembership] setHidden:YES];
        }
        
        [[cell labelClubNameAndMembers] setText:[NSString stringWithFormat:@"%@    (%@)", [[[self arrayMyClubs] objectAtIndex:indexPath.row] objectForKey:@"PoolName"], [[[self arrayMyClubs] objectAtIndex:indexPath.row] objectForKey:@"NoofMembers"]]];
        
        [[cell buttonDeleteClub] setTag:indexPath.row];
        [[cell buttonDeleteClub] addTarget:self
                                    action:@selector(deleteClubPressed:)
                          forControlEvents:UIControlEventTouchUpInside];
        
        return cell;
    } else if (tableView == [self tableViewMemberOfClubs]) {
        
        MemberOfClubsTableViewCell *cell;
        
        static NSString *reuseIdentifier = @"MemberOfClubsTableViewCell";
        cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
        
        if (!cell) {
            cell = [[MemberOfClubsTableViewCell alloc] init];
        }
        
        if ([[[[self arrayMemberOfClubs] objectAtIndex:indexPath.row] objectForKey:@"NoofMembers"] intValue] <= 10) {
            [[cell buttonLowMembership] setHidden:NO];
            [[cell buttonLowMembership] addTarget:self
                                           action:@selector(lowMembershipWarning)
                                 forControlEvents:UIControlEventTouchUpInside];
        } else {
            [[cell buttonLowMembership] setHidden:YES];
        }
        
        [[cell labelClubNameAndMembers] setText:[NSString stringWithFormat:@"%@    (%@)", [[[self arrayMemberOfClubs] objectAtIndex:indexPath.row] objectForKey:@"PoolName"], [[[self arrayMemberOfClubs] objectAtIndex:indexPath.row] objectForKey:@"NoofMembers"]]];
        [[cell labelOwnerName] setText:[NSString stringWithFormat:@"(%@)", [[[self arrayMemberOfClubs] objectAtIndex:indexPath.row] objectForKey:@"OwnerName"]]];
        
        [[cell buttonDeleteClub] setTag:indexPath.row];
        [[cell buttonDeleteClub] addTarget:self
                                    action:@selector(leaveClubPressed:)
                          forControlEvents:UIControlEventTouchUpInside];
        
        return cell;
    }
    
    return nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGRect frameTableView = [tableView frame];
    return frameTableView.size.height / 3.5;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:NO];
    
    if (tableView == [self tableViewMyClubs]) {
        [self setClubsSegueType:MY_CLUBS_SEGUE];
        [self performSegueWithIdentifier:@"ClubDetailsSegue"
                                  sender:[[self arrayMyClubs] objectAtIndex:indexPath.row]];
    } else if (tableView == [self tableViewMemberOfClubs]) {
        [self setClubsSegueType:MEMBER_OF_CLUBS_SEGUE];
        [self performSegueWithIdentifier:@"ClubDetailsSegue"
                                  sender:[[self arrayMemberOfClubs] objectAtIndex:indexPath.row]];
    }
}

#pragma mark - Private methods

- (void)fetchClubs {
    [self showActivityIndicatorView];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_FETCH_CLUBS
                                                     parameters:[NSString stringWithFormat:@"OwnerNumber=%@", [self mobileNumber]]
                                            delegateForProtocol:self];
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

@end
