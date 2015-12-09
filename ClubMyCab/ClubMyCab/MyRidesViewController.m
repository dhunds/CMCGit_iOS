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

@interface MyRidesViewController () <GlobalMethodsAsyncRequestProtocol, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSString *mobileNumber;

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) NSArray *arrayMyRides, *arrayMyRidesCurrent, *arrayMyRidesHistory;

@property (weak, nonatomic) IBOutlet UITableView *tableViewMyRides;
@property (weak, nonatomic) IBOutlet UIButton *buttonShowHistory;

@property (nonatomic) BOOL isFetchingHistory, showHistoryPressed;

@end

@implementation MyRidesViewController

- (NSString *)TAG {
    return @"MyRidesViewController";
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
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
                    } else {
                        [Logger logError:[self TAG]
                                 message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                        [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
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
    [[cell labelTotalSeats] setText:[NSString stringWithFormat:@"Total seats : %@", [array lastObject]]];
    [[cell labelAvailableSeats] setText:[NSString stringWithFormat:@"Available : %d", ([[array lastObject] intValue] - [[array firstObject] intValue])]];
    
    if ([self isLastRideVisible]) {
        [self fetchPoolsHistoryWithLastCabID:[[[self arrayMyRides] lastObject] objectForKey:@"CabId"]];
    }
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGRect frameTableView = [tableView frame];
    return frameTableView.size.height / 4.0;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:NO];
    
    [self performSegueWithIdentifier:@"RideDetailsSegue"
                              sender:[[self arrayMyRides] objectAtIndex:indexPath.section]];
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


@end
