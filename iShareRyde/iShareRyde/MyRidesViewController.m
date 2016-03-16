//
//  MyRidesViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 11/09/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import "MyRidesViewController.h"
#import "SWRevealViewController.h"
#import "Logger.h"
#import "ActivityIndicatorView.h"
#import "ToastLabel.h"
#import "GlobalMethods.h"
#import "NotificationsListViewController.h"
#import "MyRidesTableViewCell.h"
#import "RideDetailsViewController.h"
#import "RideDetailsMemberViewController.h"
#import "MyProfileViewController.h"
#import <Google/Analytics.h>

@interface MyRidesViewController () <GlobalMethodsAsyncRequestProtocol, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSString *mobileNumber;

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) NSArray *arrayMyRides, *arrayMyRidesCurrent, *arrayMyRidesHistory;

@property (weak, nonatomic) IBOutlet UITableView *tableViewMyRides;
@property (weak, nonatomic) IBOutlet UIButton *buttonShowHistory;

@property (nonatomic) BOOL isFetchingHistory, showHistoryPressed;

@property (strong, nonatomic) UIAlertView *alertViewProfileImage;

@property (strong, nonatomic) NSMutableDictionary *dictionaryProfileImages;

@end

@implementation MyRidesViewController

- (NSString *)TAG {
    return @"MyRidesViewController";
}

- (NSMutableDictionary *)dictionaryProfileImages {
    if (!_dictionaryProfileImages) {
        _dictionaryProfileImages = [NSMutableDictionary dictionary];
    }
    
    return _dictionaryProfileImages;
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
    
    [self setMobileNumber:[[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_MOBILE]];
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" viewDidLoad : %@", [self cabIDFromNotification]]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName
           value:[self TAG]];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_FETCH_UNREAD_NOTIFICATIONS_COUNT
                                                     parameters:[NSString stringWithFormat:@"MobileNumber=%@", [self mobileNumber]]
                                            delegateForProtocol:self];
    
    [self fetchPools];
    
    [self setShowHistoryPressed:NO];
    [self setIsFetchingHistory:NO];
    [[self buttonShowHistory] setHidden:NO];
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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([[segue identifier] isEqualToString:@"NotificationsRidesSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[NotificationsListViewController class]]) {
            
        }
    } else if ([[segue identifier] isEqualToString:@"RideDetailsSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[RideDetailsViewController class]]) {
            [(RideDetailsViewController *)[segue destinationViewController] setDictionaryRideDetails:sender];
            
            NSString *imageName = [sender objectForKey:@"imagename"];
            if (imageName && [imageName length] > 0) {
                UIImage *image = [[self dictionaryProfileImages] objectForKey:imageName];
                if (image) {
                    [(RideDetailsViewController *)[segue destinationViewController] setOwnerImage:image];
                } else {
                    [(RideDetailsViewController *)[segue destinationViewController] setOwnerImage:nil];
                }
                
            } else {
                [(RideDetailsViewController *)[segue destinationViewController] setOwnerImage:nil];
            }
        }
    } else if ([[segue identifier] isEqualToString:@"RideDetailsMemberSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[RideDetailsMemberViewController class]]) {
            [(RideDetailsMemberViewController *)[segue destinationViewController] setDictionaryRideDetails:sender];
            
            NSString *imageName = [sender objectForKey:@"imagename"];
            if (imageName && [imageName length] > 0) {
                UIImage *image = [[self dictionaryProfileImages] objectForKey:imageName];
                if (image) {
                    [(RideDetailsMemberViewController *)[segue destinationViewController] setOwnerImage:image];
                } else {
                    [(RideDetailsMemberViewController *)[segue destinationViewController] setOwnerImage:nil];
                }
                
            } else {
                [(RideDetailsMemberViewController *)[segue destinationViewController] setOwnerImage:nil];
            }
        }
    } else if ([[segue identifier] isEqualToString:@"RidesProfileSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[MyProfileViewController class]]) {
            [(MyProfileViewController *)[segue destinationViewController] setChangeProfilePicture:YES];
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
            } else if ([endPoint isEqualToString:ENDPOINT_FETCH_MY_POOLS]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                if ((response && [response caseInsensitiveCompare:@"No Pool Created Yet!!"] == NSOrderedSame) || [response length] <= 0 || [response isEqualToString:@"[]"]) {
                    [self makeToastWithMessage:@"No active rides!"];
                    
                    [self setArrayMyRides:[NSArray array]];
                    [[self tableViewMyRides] reloadData];
                } else {
                    NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                    NSError *error = nil;
                    NSArray *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                          options:NSJSONReadingMutableContainers
                                                                            error:&error];
                    if (!error) {
                        [self setArrayMyRidesCurrent:parsedJson];
                        [self setArrayMyRides:[self arrayMyRidesCurrent]];
                        
                        [[self tableViewMyRides] reloadData];
                        
                        NSMutableArray *array = [NSMutableArray array];
                        for (NSDictionary *dictionary in parsedJson) {
                            [array addObject:[dictionary objectForKey:@"CabId"]];
                        }
                        
                        if (array && [array count] > 0) {
                            [self clearBookedOrCarPreferenceForRides:array];
                        }
                    } else {
                        [Logger logError:[self TAG]
                                 message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                        [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                    }
                }
                
                if ([self nidFromNotifications] && [[self nidFromNotifications] length] > 0) {
                    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
                    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                                       endPoint:ENDPOINT_UPDATE_NOTIFICATION_STATUS_READ
                                                                     parameters:[NSString stringWithFormat:@"rnum=&nid=%@", [self nidFromNotifications]]
                                                            delegateForProtocol:self];
                }
                
                if ([self cabIDFromNotification] && [[self cabIDFromNotification] length] > 0) {
                    for (NSDictionary *dict in [self arrayMyRides]) {
                        if ([[dict objectForKey:@"CabId"] isEqualToString:[self cabIDFromNotification]]) {
                            
                            if ([[dict objectForKey:@"MobileNumber"] isEqualToString:[self mobileNumber]]) {
                                [self performSegueWithIdentifier:@"RideDetailsSegue"
                                                          sender:dict];
                            } else {
                                [self performSegueWithIdentifier:@"RideDetailsMemberSegue"
                                                          sender:dict];
                            }
                            
                            [self setCabIDFromNotification:nil];
                            
                            break;
                        }
                    }
                }
            } else if ([endPoint isEqualToString:ENDPOINT_FETCH_MY_POOL_HISTORY]) {
                
                [[self buttonShowHistory] setHidden:YES];
                
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                if ((response && [response caseInsensitiveCompare:@"No Pool Created Yet!!"] == NSOrderedSame) || [response length] <= 0 || [response isEqualToString:@"[]"]) {
                    [self makeToastWithMessage:@"No More history"];
                    
                    [self setIsFetchingHistory:YES];    //to stop loading more history after everything is fetched
                } else {
                    NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                    NSError *error = nil;
                    NSArray *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                          options:NSJSONReadingMutableContainers
                                                                            error:&error];
                    if (!error) {
                        if (![self arrayMyRidesHistory] || [[self arrayMyRidesHistory] count] <= 0) {
                            [self setArrayMyRidesHistory:parsedJson];
                        } else {
                            [self setArrayMyRidesHistory:[[self arrayMyRidesHistory] arrayByAddingObjectsFromArray:parsedJson]];
                        }
                        
                        if (![self arrayMyRidesCurrent] || [[self arrayMyRidesCurrent] count] <= 0) {
                            [self setArrayMyRides:[self arrayMyRidesHistory]];
                        } else {
                            [self setArrayMyRides:[[self arrayMyRidesCurrent] arrayByAddingObjectsFromArray:[self arrayMyRidesHistory]]];
                        }
                        
                        [[self tableViewMyRides] reloadData];
                        
                        [self setIsFetchingHistory:NO];
                    } else {
                        [Logger logError:[self TAG]
                                 message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                        [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                    }
                }
            } else if ([endPoint isEqualToString:ENDPOINT_UPDATE_NOTIFICATION_STATUS_READ]) {
                
            }
        }
    });
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self arrayMyRides] count];
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
    return frameTableView.size.height / 50.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MyRidesTableViewCell *cell;
    
    static NSString *reuseIdentifier = @"MyRidesTableViewCell";
    cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (!cell) {
        cell = [[MyRidesTableViewCell alloc] init];
    }
    
    NSDictionary *dictionaryRide = [[self arrayMyRides] objectAtIndex:indexPath.section];
    [[cell labelOwnerName] setText:[dictionaryRide objectForKey:@"OwnerName"]];
    [[cell labelFromTo] setText:[NSString stringWithFormat:@"    %@ > %@", [dictionaryRide objectForKey:@"FromShortName"], [dictionaryRide objectForKey:@"ToShortName"]]];
    [[cell labelDate] setText:[dictionaryRide objectForKey:@"TravelDate"]];
    [[cell labelTime] setText:[dictionaryRide objectForKey:@"TravelTime"]];
    
    NSString *seatStatus = [dictionaryRide objectForKey:@"Seat_Status"];
    NSArray *array = [seatStatus componentsSeparatedByString:@"/"];
    [[cell labelTotalSeats] setText:[NSString stringWithFormat:@"Total seats : %d", ([[array lastObject] intValue] + 1)]];
    [[cell labelAvailableSeats] setText:[NSString stringWithFormat:@"Available : %d", ([[array lastObject] intValue] - [[array firstObject] intValue])]];
    
    NSString *imageName = [dictionaryRide objectForKey:@"imagename"];
    if (!imageName || [imageName length] <= 0) {
        [[cell imageViewOwnerImage] setImage:[UIImage imageNamed:@"contact_appicon.png"]];
    } else {
        if ([[self dictionaryProfileImages] objectForKey:imageName]) {
            [[cell imageViewOwnerImage] setImage:[[self dictionaryProfileImages] objectForKey:imageName]];
            CGRect frame = [[cell imageViewOwnerImage] frame];
            [[[cell imageViewOwnerImage] layer] setCornerRadius:(frame.size.width / 2.0f)];
            [[cell imageViewOwnerImage] setClipsToBounds:YES];
        } else {
            [[cell imageViewOwnerImage] setImage:[UIImage imageNamed:@"contact_appicon.png"]];
            
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/ProfileImages/%@", SERVER_ADDRESS, imageName]];
            NSURLSessionTask *sessionTask = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                            if (data) {
                                                                                UIImage *image = [UIImage imageWithData:data];
                                                                                if (image) {
                                                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                                                        MyRidesTableViewCell *imageCell = [[self tableViewMyRides] cellForRowAtIndexPath:indexPath];
                                                                                        if (imageCell) {
                                                                                            CGRect frame = [[imageCell imageViewOwnerImage] frame];
                                                                                            UIImage *scaledImage = [self scaleImage:image
                                                                                                                             toSize:CGSizeMake(frame.size.width, frame.size.height)];
                                                                                            
                                                                                            [[imageCell imageViewOwnerImage] setImage:scaledImage];
                                                                                            [[self dictionaryProfileImages] setObject:scaledImage
                                                                                                                               forKey:imageName];
                                                                                            
//                                                                                            CGRect frame = [[imageCell imageViewOwnerImage] frame];
                                                                                            [[[imageCell imageViewOwnerImage] layer] setCornerRadius:(frame.size.width / 2.0f)];
                                                                                            [[imageCell imageViewOwnerImage] setClipsToBounds:YES];
                                                                                            
                                                                                        }
                                                                                    });
                                                                                }
                                                                            }
                                                                        }];
            [sessionTask resume];
        }
    }
    
    if ([self isLastRideVisible]) {
        [self fetchPoolsHistoryWithLastCabID:[[[self arrayMyRides] lastObject] objectForKey:@"CabId"]];
    }
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGRect frameTableView = [tableView frame];
    return frameTableView.size.height / 3.0;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:NO];
    
    if ([[[[self arrayMyRides] objectAtIndex:indexPath.section] objectForKey:@"MobileNumber"] isEqualToString:[self mobileNumber]]) {
        [self performSegueWithIdentifier:@"RideDetailsSegue"
                                  sender:[[self arrayMyRides] objectAtIndex:indexPath.section]];
    } else {
        [self performSegueWithIdentifier:@"RideDetailsMemberSegue"
                                  sender:[[self arrayMyRides] objectAtIndex:indexPath.section]];
    }
}

#pragma mark - IBAction methods

- (IBAction)notificationsBarButtonItemPressed {
    
    [self performSegueWithIdentifier:@"NotificationsRidesSegue"
                              sender:self];
}

- (IBAction)showHistoryPressed:(UIButton *)sender {
    
    [self setShowHistoryPressed:YES];
    
    [self fetchPoolsHistoryWithLastCabID:@""];
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
    if (alertView == [self alertViewProfileImage]) {
        if ([buttonTitle isEqualToString:@"Yes"]) {
            [self performSegueWithIdentifier:@"RidesProfileSegue"
                                      sender:self];
        }
    }
}

#pragma mark - Private methods

- (void)fetchPools {
    [self showActivityIndicatorView];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_FETCH_MY_POOLS
                                                     parameters:[NSString stringWithFormat:@"MobileNumber=%@", [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_MOBILE]]
                                            delegateForProtocol:self];
}

- (void)fetchPoolsHistoryWithLastCabID:(NSString *)cabID {
    
    if ([self showHistoryPressed]) {
        if ([self isFetchingHistory]) {
            return;
        } else {
            [self setIsFetchingHistory:YES];
        }
        
        [self showActivityIndicatorView];
        
        GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
        [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                           endPoint:ENDPOINT_FETCH_MY_POOL_HISTORY
                                                         parameters:[NSString stringWithFormat:@"MobileNumber=%@&LastCabId=%@", [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_MOBILE], cabID]
                                                delegateForProtocol:self];
    }
}

- (BOOL)isLastRideVisible {
    for (NSIndexPath *indexPath in [[self tableViewMyRides] indexPathsForVisibleRows]) {
        if (indexPath.section == ([[self arrayMyRides] count] - 1)) {
            return YES;
            break;
        }
    }
    
    return NO;
}

- (void)clearBookedOrCarPreferenceForRides:(NSArray *)rides {
    NSArray *array = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_BOOKED_OR_CAR_PREFERENCE];
    
    NSMutableArray *arrayMutable = [NSMutableArray array];
    if (array && [array count] > 0) {
        for (NSString *cabID in array) {
            if ([rides containsObject:cabID]) {
                [arrayMutable addObject:cabID];
            }
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[arrayMutable copy]
                                              forKey:KEY_USER_DEFAULT_BOOKED_OR_CAR_PREFERENCE];
}

- (UIImage *)scaleImage:(UIImage *)originalImage
                 toSize:(CGSize)newSize {
    if (CGSizeEqualToSize([originalImage size], newSize)) {
        return originalImage;
    }
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0f);
    [originalImage drawInRect:CGRectMake(0.0f, 0.0f, newSize.width, newSize.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
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
