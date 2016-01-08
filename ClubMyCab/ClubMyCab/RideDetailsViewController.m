//
//  RideDetailsViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 04/12/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import "RideDetailsViewController.h"
#import <GoogleMaps/GoogleMaps.h>
#import "Logger.h"
#import "ActivityIndicatorView.h"
#import "ToastLabel.h"
#import "GlobalMethods.h"
#import "AddressModel.h"
#import "BookACabViewController.h"
#import "GenericContactsViewController.h"

@interface RideDetailsViewController () <GMSMapViewDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, GenericContactsVCProtocol>

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (weak, nonatomic) IBOutlet UIView *viewButtons;
@property (weak, nonatomic) IBOutlet GMSMapView *mapViewRideDetails;
@property (weak, nonatomic) IBOutlet UIView *viewRideInfo;
@property (weak, nonatomic) IBOutlet UIView *viewRideInfoParent;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewInfoUserImage;
@property (weak, nonatomic) IBOutlet UILabel *labelInfoUsername;
@property (weak, nonatomic) IBOutlet UILabel *labelInfoFromTo;
@property (weak, nonatomic) IBOutlet UILabel *labelInfoDate;
@property (weak, nonatomic) IBOutlet UILabel *labelInfoTime;
@property (weak, nonatomic) IBOutlet UILabel *labelInfoTotalSeats;
@property (weak, nonatomic) IBOutlet UILabel *labelInfoAvailableSeats;
@property (weak, nonatomic) IBOutlet UITableView *tableViewInfoMembers;
@property (weak, nonatomic) IBOutlet UILabel *labelInfoMembers;
@property (weak, nonatomic) IBOutlet UILabel *labelInfoPerSeatCharge;
@property (weak, nonatomic) IBOutlet UIButton *buttonCabInfo;

@property (strong, nonatomic) NSArray *arrayMembers;

@property (strong, nonatomic) UIAlertView *alertViewCancelRide;
@property (strong, nonatomic) UIAlertView *alertViewCabBooking;
@property (strong, nonatomic) UIAlertView *alertViewTripStart;
@property (strong, nonatomic) UIAlertView *alertViewRideComplete;
@property (strong, nonatomic) UIAlertView *alertViewFareSplitAmount;
@property (strong, nonatomic) UIAlertView *alertViewFareSplitSendToMembers;
@property (strong, nonatomic) UIAlertView *alertViewCabInfo;
@property (strong, nonatomic) UIAlertView *alertViewCabInfoCancelBooking;

@property (strong, nonatomic) NSString *membersFareString, *totalFareString;

@property (nonatomic) BOOL shouldShowTripStartDialog;

@property (strong, nonatomic) NSArray *fareSplitMobileNumbers, *fareSplitPickUpLocation, *fareSplitDropLocation, *fareSplitRouteDistance, *fareSplitRouteLocation;

@property (strong, nonatomic) AddressModel *addressFrom, *addressTo;

@end

@implementation RideDetailsViewController

#define CHAT_STATUS_ONLINE              @"online"
#define CHAT_STATUS_OFFLINE             @"offline"

- (NSString *)TAG {
    return @"RideDetailsViewController";
}

#pragma mark - View Controller Life Cycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[self mapViewRideDetails] setDelegate:self];
    [[self mapViewRideDetails] setMyLocationEnabled:YES];
    [[[self mapViewRideDetails] settings] setMyLocationButton:YES];
    
    if (![[[self dictionaryRideDetails] objectForKey:@"CabStatus"] isEqualToString:@"A"]) {
        [[self viewButtons] setHidden:YES];
    }
    
    if ([[self dictionaryRideDetails] objectForKey:@"BookingRefNo"] && ![[[self dictionaryRideDetails] objectForKey:@"BookingRefNo"] isEqual:[NSNull null]] && [[[self dictionaryRideDetails] objectForKey:@"BookingRefNo"] length] > 0 && [[[[self dictionaryRideDetails] objectForKey:@"BookingRefNo"] lowercaseString] rangeOfString:@"null"].location == NSNotFound) {
        [[self buttonCabInfo] setHidden:NO];
    } else {
        [[self buttonCabInfo] setHidden:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self changeChatStatus:CHAT_STATUS_ONLINE];
    [self getMembersForMap];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self changeChatStatus:CHAT_STATUS_OFFLINE];
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
    
    if ([[segue identifier] isEqualToString:@"BookACabRideSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[BookACabViewController class]]) {
            [(BookACabViewController *)[segue destinationViewController] setAddressModelFrom:[self addressFrom]];
            [(BookACabViewController *)[segue destinationViewController] setAddressModelTo:[self addressTo]];
            [(BookACabViewController *)[segue destinationViewController] setDictionaryBookCabFromRide:[self dictionaryRideDetails]];
        }
    } else if ([[segue identifier] isEqualToString:@"OwnerInviteContactsSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[GenericContactsViewController class]]) {
            [(GenericContactsViewController *)[segue destinationViewController] setSegueType:SEGUE_FROM_OWNER_RIDE_INVITATION];
            [(GenericContactsViewController *)[segue destinationViewController] setDelegateGenericContactsVC:self];
        }
    }
}

#pragma mark - GenericContactsVCProtocol methods

- (void)contactsToInviteFrom:(GenericContactsViewController *)sender
                 withNumbers:(NSString *)numbers
                    andNames:(NSString *)names {
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" GenericContactsVCProtocol numbers : %@ names : %@", numbers, names]];
    
    [self showActivityIndicatorView];
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_OWNER_INVITE_FRIENDS
                                                     parameters:[NSString stringWithFormat:@"CabId=%@&MembersNumber=%@&MembersName=%@&OwnerName=%@&OwnerNumber=%@", [[self dictionaryRideDetails] objectForKey:@"CabId"], numbers, names, [[self dictionaryRideDetails] objectForKey:@"OwnerName"], [[self dictionaryRideDetails] objectForKey:@"MobileNumber"]]
                                            delegateForProtocol:self];
    
}

#pragma mark - IBAction methods

- (IBAction)chatPressed:(UIButton *)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Coming soon!"
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (IBAction)invitePressed:(UIButton *)sender {
    if ([[[self dictionaryRideDetails] objectForKey:@"RemainingSeats"] intValue] <= 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Ride full"
                                                            message:@"The ride is already full"
                                                           delegate:self
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
        [alertView show];
    } else {
        [self performSegueWithIdentifier:@"OwnerInviteContactsSegue"
                                  sender:self];
    }
}

- (IBAction)bookCabPressed:(UIButton *)sender {
    
    if ([[[self dictionaryRideDetails] objectForKey:@"rideType"] isEqualToString:@"1"]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                            message:@"This is a car pool ride, you can book a cab from home page"
                                                           delegate:self
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
        [alertView show];
    } else {
        [self openBookCabPage];
    }
}

- (IBAction)cancelRidePressed:(UIButton *)sender {
    [self cancelTrip];
}

- (IBAction)infoButtonPressed:(UIButton *)sender {
    [self showRideInfoDialog];
}

- (IBAction)infoViewTapped:(UITapGestureRecognizer *)sender {
    
    CGRect frame = [[self viewRideInfo] frame];
    
    if ([sender locationInView:[self viewRideInfoParent]].x < frame.size.width && [sender locationInView:[self viewRideInfoParent]].y < frame.size.height) {
        
    } else {
        [[self viewRideInfoParent] setHidden:YES];
    }
}

- (IBAction)cabInfoPressed:(UIButton *)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Booking details"
                                                        message:[NSString stringWithFormat:@"Driver : %@\r\nVehicle : %@\r\nBooking reference : %@", [[self dictionaryRideDetails] objectForKey:@"DriverName"], [[self dictionaryRideDetails] objectForKey:@"CarNumber"], [[self dictionaryRideDetails] objectForKey:@"BookingRefNo"]]
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Call Driver", @"Cancel booking", @"Dismiss", nil];
    [self setAlertViewCabInfo:alertView];
    [alertView show];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    
    if (alertView == [self alertViewCancelRide]) {
        if ([buttonTitle isEqualToString:@"Yes"]) {
            [self showActivityIndicatorView];
            
            NSString *message = [NSString stringWithFormat:@"%@ cancelled the ride from %@ to %@", [[self dictionaryRideDetails] objectForKey:@"OwnerName"], [[self dictionaryRideDetails] objectForKey:@"FromShortName"], [[self dictionaryRideDetails] objectForKey:@"ToShortName"]];
            GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
            [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                               endPoint:ENDPOINT_CANCEL_POOL_OWNER
                                                             parameters:[NSString stringWithFormat:@"CabId=%@&OwnerName=%@&OwnerNumber=%@&Message=%@", [[self dictionaryRideDetails] objectForKey:@"CabId"], [[self dictionaryRideDetails] objectForKey:@"OwnerName"], [[self dictionaryRideDetails] objectForKey:@"MobileNumber"], message]
                                                    delegateForProtocol:self];
            
        } else if ([buttonTitle isEqualToString:@"No"]) {
            
        }
    } else if (alertView == [self alertViewCabBooking]) {
        
        if ([buttonTitle isEqualToString:@"Book a cab"]) {
            [self openBookCabPage];
        } else if ([buttonTitle isEqualToString:@"Already booked"] || [buttonTitle isEqualToString:@"Driving my own car"]) {
            [self saveBookedOrCarPreference:[[self dictionaryRideDetails] objectForKey:@"CabId"]];
            if ([self shouldShowTripStartDialog]) {
                [self showTripStartDialog];
            }
        } else if ([buttonTitle isEqualToString:@"Cancel trip"]) {
            [self cancelTrip];
        }
    } else if (alertView == [self alertViewTripStart]) {
        
        if ([buttonTitle isEqualToString:@"Start the ride now"]) {
            [self showActivityIndicatorView];
            
            GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
            [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                               endPoint:ENDPOINT_START_TRIP_NOTIFICATION
                                                             parameters:[NSString stringWithFormat:@"cabId=%@", [[self dictionaryRideDetails] objectForKey:@"CabId"]]
                                                    delegateForProtocol:self];
        }
//        else if ([buttonTitle isEqualToString:@"Start in 5 mins"]) {
//        } else if ([buttonTitle isEqualToString:@"Start in 10 mins"]) {
//        }
    } else if (alertView == [self alertViewRideComplete]) {
        if ([buttonTitle isEqualToString:@"I paid, calculate fare split"]) {
            [self showFareSplitDialog];
        } else if ([buttonTitle isEqualToString:@"Someone else paid"]) {
            [self makeToastWithMessage:@"We will let you know when your friend shares the fare details & the amount you owe"];
            
            [self performSelector:@selector(popVC)
                       withObject:nil
                       afterDelay:5];
        } else if ([buttonTitle isEqualToString:@"Already settled"]) {
            [self showActivityIndicatorView];
            
            GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
            [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                               endPoint:ENDPOINT_TRIP_COMPLETED
                                                             parameters:[NSString stringWithFormat:@"cabId=%@", [[self dictionaryRideDetails] objectForKey:@"CabId"]]
                                                    delegateForProtocol:self];
        }
    } else if (alertView == [self alertViewFareSplitAmount]) {
        NSString *fare = [[alertView textFieldAtIndex:0] text];
        if (!fare || [fare length] <= 0 || [fare doubleValue] <= 0.0) {
            [self makeToastWithMessage:@"Please enter a valid fare"];
            
            [self showFareSplitDialog];
            
            return;
        }
        
        if ([buttonTitle isEqualToString:@"Split by distance"]) {
            
            [Logger logDebug:[self TAG]
                     message:[NSString stringWithFormat:@" fareSplitMobileNumbers : %@ fareSplitPickUpLocation : %@ fareSplitDropLocation : %@ fareSplitRouteDistance : %@ fareSplitRouteLocation : %@", [[self fareSplitMobileNumbers] description], [[self fareSplitPickUpLocation] description], [[self fareSplitDropLocation] description], [[self fareSplitRouteDistance] description], [[self fareSplitRouteLocation] description]]];
            
            NSMutableDictionary *distanceDictionary = [NSMutableDictionary dictionary];
            for (int i = 0; i < [[self fareSplitMobileNumbers] count]; i++) {
                NSString *number = [[self fareSplitMobileNumbers] objectAtIndex:i];
                
                CLLocation *pick = [(AddressModel *)[[self fareSplitPickUpLocation] objectAtIndex:i] location];
                CLLocation *drop = [(AddressModel *)[[self fareSplitDropLocation] objectAtIndex:i] location];
                
                int pickIndex = -1, dropIndex = -1;
                
                for (int j = 0; j < [[self fareSplitRouteLocation] count]; j++) {
                    CLLocation *routePoint = [(AddressModel *)[[self fareSplitRouteLocation] objectAtIndex:j] location];
                    //                                               [Logger logDebug:[self TAG]
                    //                                                        message:[NSString stringWithFormat:@" i : %d j : %d distance pick : %f drop : %f", i, j, [pick distanceFromLocation:routePoint], [drop distanceFromLocation:routePoint]]];
                    if ([pick distanceFromLocation:routePoint] < 500.0) {
                        pickIndex = j;
                    }
                    
                    if ([drop distanceFromLocation:routePoint] < 500.0) {
                        dropIndex = j;
                    }
                }
                
                if (pickIndex != -1 && dropIndex != -1) {
                    double distance = 0.0;
                    for (int j = (pickIndex + 1); j <= dropIndex; j++) {
                        distance += [[[self fareSplitRouteDistance] objectAtIndex:j] doubleValue];
                    }
                    
                    [distanceDictionary setObject:[NSNumber numberWithDouble:distance]
                                           forKey:number];
                }
                
            }
            
            [Logger logDebug:[self TAG]
                     message:[NSString stringWithFormat:@" distanceDictionary : %@", [distanceDictionary description]]];
            double totalDistance = 0.0;
            for (NSString *key in [distanceDictionary allKeys]) {
                totalDistance += [[distanceDictionary objectForKey:key] doubleValue];
            }
            
            NSString *membersFare = @"";
            NSString *message = @"";
            for (int i = 0; i < [[self fareSplitMobileNumbers] count]; i++) {
                
                NSString *fareSplit = [NSString stringWithFormat:@"%1.0f", (([[distanceDictionary objectForKey:[[self fareSplitMobileNumbers] objectAtIndex:i]] doubleValue] / totalDistance) * [fare doubleValue])];
                
                BOOL found = NO;
                for (int k = 0; k < [[self arrayMembers] count]; k++) {
                    if ([[[self fareSplitMobileNumbers] objectAtIndex:i] isEqualToString:[[[self arrayMembers] objectAtIndex:k] objectForKey:@"MemberNumber"]]) {
                        found = YES;
                        
                        message = [message stringByAppendingString:[NSString stringWithFormat:@"%@ : \u20B9%@\r\n", [[[self arrayMembers] objectAtIndex:k] objectForKey:@"MemberName"], fareSplit]];
                        membersFare = [membersFare stringByAppendingString:[NSString stringWithFormat:@"%@~%@,", [[self fareSplitMobileNumbers] objectAtIndex:i], fareSplit]];
                        
                    }
                }
                
                if (!found) {
                    message = [message stringByAppendingString:[NSString stringWithFormat:@"%@ : \u20B9%@\r\n", [[self dictionaryRideDetails] objectForKey:@"OwnerName"], fareSplit]];
                    membersFare = [membersFare stringByAppendingString:[NSString stringWithFormat:@"%@~%@", [[self fareSplitMobileNumbers] objectAtIndex:i], fareSplit]];
                }
            }
            
            [self setMembersFareString:membersFare];
            [self setTotalFareString:fare];
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Fare Split"
                                                                message:message
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"Send to members", nil];
            
            [alertView show];
            
            [self setAlertViewFareSplitSendToMembers:alertView];
            
        } else if ([buttonTitle isEqualToString:@"Split equally"]) {
            NSString *fareSplit = [NSString stringWithFormat:@"%1.0f", ([fare doubleValue] / ([[self arrayMembers] count] + 1))];
            
            NSString *membersFare = @"";
            NSString *message = @"";
            for (int i = 0; i < [[self arrayMembers] count]; i++) {
                message = [message stringByAppendingString:[NSString stringWithFormat:@"%@ : \u20B9%@\r\n", [[[self arrayMembers] objectAtIndex:i] objectForKey:@"MemberName"], fareSplit]];
                membersFare = [membersFare stringByAppendingString:[NSString stringWithFormat:@"%@~%@,", [[[self arrayMembers] objectAtIndex:i] objectForKey:@"MemberNumber"], fareSplit]];
            }
            
            message = [message stringByAppendingString:[NSString stringWithFormat:@"%@ : \u20B9%@", [[self dictionaryRideDetails] objectForKey:@"OwnerName"], fareSplit]];
            membersFare = [membersFare stringByAppendingString:[NSString stringWithFormat:@"%@~%@", [[self dictionaryRideDetails] objectForKey:@"MobileNumber"], fareSplit]];
            
            [self setMembersFareString:membersFare];
            [self setTotalFareString:fare];
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Fare Split"
                                                                message:message
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"Send to members", nil];
            
            [alertView show];
            
            [self setAlertViewFareSplitSendToMembers:alertView];
        }
    } else if (alertView == [self alertViewFareSplitSendToMembers]) {
        if ([buttonTitle isEqualToString:@"Send to members"]) {
            [self showActivityIndicatorView];
            
            GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
            [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                               endPoint:ENDPOINT_SAVE_CALCULATED_FARE
                                                             parameters:[NSString stringWithFormat:@"cabId=%@&totalFare=%@&numberAndFare=%@&paidBy=%@&owner=%@", [[self dictionaryRideDetails] objectForKey:@"CabId"], [self totalFareString], [self membersFareString], [[self dictionaryRideDetails] objectForKey:@"MobileNumber"], [[self dictionaryRideDetails] objectForKey:@"MobileNumber"]]
                                                    delegateForProtocol:self];
        }
    } else if (alertView == [self alertViewCabInfo]) {
        if ([buttonTitle isEqualToString:@"Call Driver"]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", [[self dictionaryRideDetails] objectForKey:@"DriverNumber"]]]];
        } else if ([buttonTitle isEqualToString:@"Cancel booking"]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cancel booking?"
                                                                message:@"Are you sure you want to cancel the booking?"
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"Yes", @"No", nil];
            [self setAlertViewCabInfoCancelBooking:alertView];
            [alertView show];
        } else if ([buttonTitle isEqualToString:@"Dismiss"]) {
            
        }
    } else if (alertView == [self alertViewCabInfoCancelBooking]) {
        if ([buttonTitle isEqualToString:@"Yes"]) {
            NSString *cabName = [[self dictionaryRideDetails] objectForKey:@"CabName"];
            
            GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
            
            if ([cabName caseInsensitiveCompare:@"Uber"] == NSOrderedSame) {
                [self showActivityIndicatorView];
                
                [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                                   endPoint:ENDPOINT_UBER_CANCEL
                                                                 parameters:[NSString stringWithFormat:@"bookingRefNo=%@", [[self dictionaryRideDetails] objectForKey:@"BookingRefNo"]]
                                                        delegateForProtocol:self];
            } else if ([cabName caseInsensitiveCompare:@"Mega"] == NSOrderedSame) {
                [self showActivityIndicatorView];
                
                [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                                   endPoint:ENDPOINT_MEGA_API
                                                                 parameters:[NSString stringWithFormat:@"type=CancelBooking&mobile=%@&bookingNo=%@", [[self dictionaryRideDetails] objectForKey:@"MobileNumber"], [[self dictionaryRideDetails] objectForKey:@"BookingRefNo"]]
                                                        delegateForProtocol:self];
            } else if ([cabName caseInsensitiveCompare:@"TaxiForSure"] == NSOrderedSame) {
                [self showActivityIndicatorView];
                
                [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                                   endPoint:ENDPOINT_TAXI_FOR_SURE_API
                                                                 parameters:[NSString stringWithFormat:@"type=cancellation&booking_id=%@&cancellation_reason=", [[self dictionaryRideDetails] objectForKey:@"BookingRefNo"]]
                                                        delegateForProtocol:self];
            } else if ([cabName caseInsensitiveCompare:@"ola"] == NSOrderedSame) {
                [self showActivityIndicatorView];
                
                [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                                   endPoint:ENDPOINT_OLA_CANCEL
                                                                 parameters:[NSString stringWithFormat:@"type=cancellation&booking_id=%@", [[self dictionaryRideDetails] objectForKey:@"BookingRefNo"]]
                                                        delegateForProtocol:self];
            }
        }
    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self arrayMembers] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    
    static NSString *reuseIdentifier = @"InfoMembersTableViewCell";
    cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] init];
    }
    
    [[cell textLabel] setText:[[[self arrayMembers] objectAtIndex:indexPath.row] objectForKey:@"MemberName"]];
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGRect frameTableView = [tableView frame];
    return frameTableView.size.height / 2.0;
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
    
    if ([self activityIndicatorView] != nil) {
        return;     //location update method being called twice, so 2 activity indicators are being displayed
    }
    
    [self setActivityIndicatorView:[[ActivityIndicatorView alloc] initWithFrame:[[self view] bounds]
                                                               messageToDisplay:PLEASE_WAIT_MESSAGE]];
    [[self view] addSubview:[self activityIndicatorView]];
}

- (void)hideActivityIndicatorView {
    
    if ([self activityIndicatorView] != nil) {
        [[self activityIndicatorView] removeFromSuperview];
    }
}

- (void)popVC {
    [[self navigationController] popViewControllerAnimated:NO];
}

- (void)getMembersForMap {
    [self showActivityIndicatorView];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_SHOW_MEMBERS_ON_MAP
                                                     parameters:[NSString stringWithFormat:@"CabId=%@", [[self dictionaryRideDetails] objectForKey:@"CabId"]]
                                            delegateForProtocol:self];
}

- (void)getPathNoMembersJoined {
    
    NSString *urlString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/directions/json?origin=%@&destination=%@&sensor=false&units=metric&mode=driving&alternatives=true&key=%@", [[[self dictionaryRideDetails] objectForKey:@"FromLocation"] stringByReplacingOccurrencesOfString:@" "
                                                                                                                                                                                                                                                                                              withString:@"%20"], [[[self dictionaryRideDetails] objectForKey:@"ToLocation"] stringByReplacingOccurrencesOfString:@" "
                                                                                                                                                                                                                                                                                                                                                                                                       withString:@"%20"], GOOGLE_MAPS_API_KEY];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setURL:[NSURL URLWithString:urlString]];
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" getPath url : %@", urlString]];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (!connectionError && data) {
                                   //                                   NSString *resp = [[NSString alloc] initWithData:data
                                   //                                                                          encoding:NSUTF8StringEncoding];
                                   //
                                   //                                   [Logger logDebug:[self TAG]
                                   //                                            message:[NSString stringWithFormat:@" getPath response : %@", resp]];
                                   
                                   [self hideActivityIndicatorView];
                                   
                                   NSError *error = nil;
                                   NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:data
                                                                                              options:NSJSONReadingMutableContainers
                                                                                                error:&error];
                                   if (!error) {
                                       NSArray *routes = [parsedJson objectForKey:@"routes"];
                                       
                                       GMSPath *pathForCamera = nil;
                                       for (NSDictionary *dictionaryRoute in routes) {
                                           GMSPath *path = [GMSPath pathFromEncodedPath:[[dictionaryRoute objectForKey:@"overview_polyline"] objectForKey:@"points"]];
                                           GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
                                           CGFloat redComponent = (arc4random_uniform(256) / 255.0f), greenComponent = (arc4random_uniform(256) / 255.0f), blueComponent = (arc4random_uniform(256) / 255.0f);
                                           UIColor *randomColor = [UIColor colorWithRed:redComponent
                                                                                  green:greenComponent
                                                                                   blue:blueComponent
                                                                                  alpha:1.0f];
                                           
                                           [polyline setStrokeColor:randomColor];
                                           [polyline setStrokeWidth:5.0f];
                                           [polyline setMap:[self mapViewRideDetails]];
                                           
                                           pathForCamera = path;
                                       }
                                       
                                       NSDictionary *leg = [[[routes firstObject] objectForKey:@"legs"] firstObject];
                                       NSString *start_address = [leg objectForKey:@"start_address"];
                                       NSString *end_address = [leg objectForKey:@"end_address"];
                                       CLLocationCoordinate2D startLocation = CLLocationCoordinate2DMake([[[leg objectForKey:@"start_location"] objectForKey:@"lat"] doubleValue], [[[leg objectForKey:@"start_location"] objectForKey:@"lng"] doubleValue]);
                                       CLLocationCoordinate2D endLocation = CLLocationCoordinate2DMake([[[leg objectForKey:@"end_location"] objectForKey:@"lat"] doubleValue], [[[leg objectForKey:@"end_location"] objectForKey:@"lng"] doubleValue]);
                                       
                                       GMSMarker *markerStart = [GMSMarker markerWithPosition:startLocation];
                                       [markerStart setTitle:@"Start"];
                                       [markerStart setSnippet:start_address];
                                       [markerStart setIcon:[GMSMarker markerImageWithColor:[UIColor greenColor]]];
                                       [markerStart setMap:[self mapViewRideDetails]];
                                       
                                       GMSMarker *markerEnd = [GMSMarker markerWithPosition:endLocation];
                                       [markerEnd setTitle:@"End"];
                                       [markerEnd setSnippet:end_address];
                                       [markerEnd setIcon:[GMSMarker markerImageWithColor:[UIColor redColor]]];
                                       [markerEnd setMap:[self mapViewRideDetails]];
                                       
                                       GMSCameraPosition *camera = [[self mapViewRideDetails] cameraForBounds:[[GMSCoordinateBounds alloc] initWithPath:pathForCamera]
                                                                           insets:UIEdgeInsetsMake(100.0f, 100.0f, 100.0f, 100.0f)];
                                       [[self mapViewRideDetails] animateToCameraPosition:camera];
                                       
                                       [self checkCabStatusAndShowDialog];
                                       
                                   } else {
                                       [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                                       
                                       [Logger logError:[self TAG]
                                                message:[NSString stringWithFormat:@" getPath parsing error : %@", [error localizedDescription]]];
                                       
                                   }
                               } else {
                                   [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                                   
                                   [Logger logError:[self TAG]
                                            message:[NSString stringWithFormat:@" getPath error : %@", [connectionError localizedDescription]]];
                               }
                           }];
}

- (void)getPathForMembersJoinedWithWayPoints:(NSString *)wayPoints {
    
    AddressModel *from = [self geocodeToAddressModelFromAddress:[[[self dictionaryRideDetails] objectForKey:@"FromLocation"] stringByReplacingOccurrencesOfString:@" "
                                                                                                                                                       withString:@"%20"]];
    NSString *origin = [NSString stringWithFormat:@"%f,%f", [[from location] coordinate].latitude, [[from location] coordinate].longitude];
    AddressModel *to = [self geocodeToAddressModelFromAddress:[[[self dictionaryRideDetails] objectForKey:@"ToLocation"] stringByReplacingOccurrencesOfString:@" "
                                                                                                                                                   withString:@"%20"]];
    NSString *destination = [NSString stringWithFormat:@"%f,%f", [[to location] coordinate].latitude, [[to location] coordinate].longitude];
    
    NSString *urlString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/directions/json?origin=%@&destination=%@%@&sensor=false&units=metric&mode=driving&alternatives=true&key=%@", origin, destination, wayPoints, GOOGLE_MAPS_API_KEY];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setURL:[NSURL URLWithString:urlString]];
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" getPathForMembersJoinedWithWayPoints url : %@", urlString]];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (!connectionError && data) {
//                                   NSString *resp = [[NSString alloc] initWithData:data
//                                                                          encoding:NSUTF8StringEncoding];
//                                   
//                                   [Logger logDebug:[self TAG]
//                                            message:[NSString stringWithFormat:@" getPathForMembersJoinedWithWayPoints response : %@", resp]];
                                   
                                   [self hideActivityIndicatorView];
                                   
                                   NSError *error = nil;
                                   NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:data
                                                                                              options:NSJSONReadingMutableContainers
                                                                                                error:&error];
                                   if (!error) {
                                       NSArray *routes = [parsedJson objectForKey:@"routes"];
                                       
                                       GMSPath *pathForCamera = nil;
                                       for (NSDictionary *dictionaryRoute in routes) {
                                           GMSPath *path = [GMSPath pathFromEncodedPath:[[dictionaryRoute objectForKey:@"overview_polyline"] objectForKey:@"points"]];
                                           GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
                                           CGFloat redComponent = (arc4random_uniform(256) / 255.0f), greenComponent = (arc4random_uniform(256) / 255.0f), blueComponent = (arc4random_uniform(256) / 255.0f);
                                           UIColor *randomColor = [UIColor colorWithRed:redComponent
                                                                                  green:greenComponent
                                                                                   blue:blueComponent
                                                                                  alpha:1.0f];
                                           
                                           [polyline setStrokeColor:randomColor];
                                           [polyline setStrokeWidth:5.0f];
                                           [polyline setMap:[self mapViewRideDetails]];
                                           
                                           pathForCamera = path;
                                       }
                                       
                                       NSDictionary *legFirst = [[[routes firstObject] objectForKey:@"legs"] firstObject];
                                       NSString *start_address = [legFirst objectForKey:@"start_address"];
                                       CLLocationCoordinate2D startLocation = CLLocationCoordinate2DMake([[[legFirst objectForKey:@"start_location"] objectForKey:@"lat"] doubleValue], [[[legFirst objectForKey:@"start_location"] objectForKey:@"lng"] doubleValue]);
                                       
                                       NSDictionary *legLast = [[[routes firstObject] objectForKey:@"legs"] lastObject];
                                       NSString *end_address = [legLast objectForKey:@"end_address"];
                                       CLLocationCoordinate2D endLocation = CLLocationCoordinate2DMake([[[legLast objectForKey:@"end_location"] objectForKey:@"lat"] doubleValue], [[[legLast objectForKey:@"end_location"] objectForKey:@"lng"] doubleValue]);
                                       
                                       GMSMarker *markerStart = [GMSMarker markerWithPosition:startLocation];
                                       [markerStart setTitle:@"Start"];
                                       [markerStart setSnippet:start_address];
                                       [markerStart setIcon:[GMSMarker markerImageWithColor:[UIColor greenColor]]];
                                       [markerStart setMap:[self mapViewRideDetails]];
                                       
                                       GMSMarker *markerEnd = [GMSMarker markerWithPosition:endLocation];
                                       [markerEnd setTitle:@"End"];
                                       [markerEnd setSnippet:end_address];
                                       [markerEnd setIcon:[GMSMarker markerImageWithColor:[UIColor redColor]]];
                                       [markerEnd setMap:[self mapViewRideDetails]];
                                       
                                       GMSCameraPosition *camera = [[self mapViewRideDetails] cameraForBounds:[[GMSCoordinateBounds alloc] initWithPath:pathForCamera]
                                                                                                       insets:UIEdgeInsetsMake(100.0f, 100.0f, 100.0f, 100.0f)];
                                       [[self mapViewRideDetails] animateToCameraPosition:camera];
                                       
                                       
                                       for (int i = 0; i < [[self arrayMembers] count]; i++) {
                                           NSString *pickLatLng = [[[self arrayMembers] objectAtIndex:i] objectForKey:@"MemberLocationlatlong"];
                                           NSArray *array = [pickLatLng componentsSeparatedByString:@","];
                                           GMSMarker *markerPick = [GMSMarker markerWithPosition:CLLocationCoordinate2DMake([[array firstObject] doubleValue], [[array lastObject] doubleValue])];
                                           [markerPick setTitle:[[[self arrayMembers] objectAtIndex:i] objectForKey:@"MemberName"]];
                                           [markerPick setSnippet:[[[self arrayMembers] objectAtIndex:i] objectForKey:@"MemberLocationAddress"]];
                                           [markerPick setIcon:[GMSMarker markerImageWithColor:[UIColor orangeColor]]];
                                           [markerPick setMap:[self mapViewRideDetails]];
                                           
                                           NSString *dropLatLng = [[[self arrayMembers] objectAtIndex:i] objectForKey:@"MemberEndLocationlatlong"];
                                           array = [dropLatLng componentsSeparatedByString:@","];
                                           GMSMarker *markerDrop = [GMSMarker markerWithPosition:CLLocationCoordinate2DMake([[array firstObject] doubleValue], [[array lastObject] doubleValue])];
                                           [markerDrop setTitle:[[[self arrayMembers] objectAtIndex:i] objectForKey:@"MemberName"]];
                                           [markerDrop setSnippet:[[[self arrayMembers] objectAtIndex:i] objectForKey:@"MemberEndLocationAddress"]];
                                           [markerDrop setIcon:[GMSMarker markerImageWithColor:[UIColor orangeColor]]];
                                           [markerDrop setMap:[self mapViewRideDetails]];
                                       }
                                       
                                       NSMutableArray *numbers = [NSMutableArray array], *pickup = [NSMutableArray array], *drop = [NSMutableArray array], *distance = [NSMutableArray array], *points = [NSMutableArray array];
                                       
                                       [numbers addObject:[[self dictionaryRideDetails] objectForKey:@"MobileNumber"]];
                                       [pickup addObject:from];
                                       [drop addObject:to];
                                       
                                       for (int i = 0; i < [[self arrayMembers] count]; i++) {
                                           [numbers addObject:[[[self arrayMembers] objectAtIndex:i] objectForKey:@"MemberNumber"]];
                                           NSString *pickLatLng = [[[self arrayMembers] objectAtIndex:i] objectForKey:@"MemberLocationlatlong"];
                                           NSArray *array = [pickLatLng componentsSeparatedByString:@","];
                                           AddressModel *address = [[AddressModel alloc] init];
                                           [address setLocation:[[CLLocation alloc] initWithLatitude:[[array firstObject] doubleValue]
                                                                                           longitude:[[array lastObject] doubleValue]]];
                                           [pickup addObject:address];
                                           
                                           NSString *dropLatLng = [[[self arrayMembers] objectAtIndex:i] objectForKey:@"MemberEndLocationlatlong"];
                                           array = [dropLatLng componentsSeparatedByString:@","];
                                           address = [[AddressModel alloc] init];
                                           [address setLocation:[[CLLocation alloc] initWithLatitude:[[array firstObject] doubleValue]
                                                                                           longitude:[[array lastObject] doubleValue]]];
                                           [drop addObject:address];
                                       }
                                       
                                       NSArray *legs = [[[parsedJson objectForKey:@"routes"] firstObject] objectForKey:@"legs"];
                                       for (int i = 0; i < [legs count]; i++) {
                                           NSDictionary *leg = [legs objectAtIndex:i];
                                           if (i == 0) {
                                               [distance addObject:[NSNumber numberWithDouble:0.0]];
                                               AddressModel *address = [[AddressModel alloc] init];
                                               [address setLocation:[[CLLocation alloc] initWithLatitude:[[[leg objectForKey:@"start_location"] objectForKey:@"lat"] doubleValue]
                                                                                               longitude:[[[leg objectForKey:@"start_location"] objectForKey:@"lng"] doubleValue]]];
                                               [points addObject:address];
                                           }
                                           
                                           [distance addObject:[NSNumber numberWithDouble:[[[leg objectForKey:@"distance"] objectForKey:@"value"] doubleValue]]];
                                           AddressModel *address = [[AddressModel alloc] init];
                                           [address setLocation:[[CLLocation alloc] initWithLatitude:[[[leg objectForKey:@"end_location"] objectForKey:@"lat"] doubleValue]
                                                                                           longitude:[[[leg objectForKey:@"end_location"] objectForKey:@"lng"] doubleValue]]];
                                           [points addObject:address];
                                       }
                                       
                                       [self setFareSplitMobileNumbers:[numbers copy]];
                                       [self setFareSplitPickUpLocation:[pickup copy]];
                                       [self setFareSplitDropLocation:[drop copy]];
                                       [self setFareSplitRouteDistance:[distance copy]];
                                       [self setFareSplitRouteLocation:[points copy]];
                                       
                                       [self checkCabStatusAndShowDialog];
                                       
                                   } else {
                                       [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                                       
                                       [Logger logError:[self TAG]
                                                message:[NSString stringWithFormat:@" getPathForMembersJoinedWithWayPoints parsing error : %@", [error localizedDescription]]];
                                       
                                   }
                               } else {
                                   [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                                   
                                   [Logger logError:[self TAG]
                                            message:[NSString stringWithFormat:@" getPathForMembersJoinedWithWayPoints error : %@", [connectionError localizedDescription]]];
                               }
                           }];
}

- (void)showRideInfoDialog {
    
    if ([[self viewRideInfoParent] isHidden]) {
        [[self labelInfoUsername] setText:[[self dictionaryRideDetails] objectForKey:@"OwnerName"]];
        [[self labelInfoFromTo] setText:[NSString stringWithFormat:@"    %@ > %@", [[self dictionaryRideDetails] objectForKey:@"FromShortName"], [[self dictionaryRideDetails] objectForKey:@"ToShortName"]]];
        [[self labelInfoDate] setText:[[self dictionaryRideDetails] objectForKey:@"TravelDate"]];
        [[self labelInfoTime] setText:[[self dictionaryRideDetails] objectForKey:@"TravelTime"]];
        
        NSString *seatStatus = [[self dictionaryRideDetails] objectForKey:@"Seat_Status"];
        NSArray *array = [seatStatus componentsSeparatedByString:@"/"];
        [[self labelInfoTotalSeats] setText:[NSString stringWithFormat:@"Total seats : %@", [array lastObject]]];
        [[self labelInfoAvailableSeats] setText:[NSString stringWithFormat:@"Available : %d", ([[array lastObject] intValue] - [[array firstObject] intValue])]];
        
        if ([[self arrayMembers] count] > 0) {
            [[self tableViewInfoMembers] reloadData];
            [[self labelInfoMembers] setHidden:NO];
            [[self tableViewInfoMembers] setHidden:NO];
        } else {
            [[self labelInfoMembers] setHidden:YES];
            [[self tableViewInfoMembers] setHidden:YES];
        }
        
        if ([[[self dictionaryRideDetails] objectForKey:@"rideType"] isEqualToString:@"1"]) {
            [[self labelInfoPerSeatCharge] setHidden:NO];
            [[self labelInfoPerSeatCharge] setText:[NSString stringWithFormat:@"Per seat charge : \u20B9%@/km", [[self dictionaryRideDetails] objectForKey:@"perKmCharge"]]];
        } else {
            [[self labelInfoPerSeatCharge] setHidden:YES];
        }
        
        [[self viewRideInfoParent] setHidden:NO];
    } else {
        [[self viewRideInfoParent] setHidden:YES];
    }
}

- (void)cancelTrip {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cancel Ride"
                                                        message:@"Are you sure you want to cancel the ride?"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Yes", @"No", nil];
    [alertView show];
    
    [self setAlertViewCancelRide:alertView];
}

- (void)openBookCabPage {
    NSString *bookingRef = [[self dictionaryRideDetails] objectForKey:@"BookingRefNo"];
    if (bookingRef && [bookingRef isKindOfClass:[NSString class]] && [bookingRef length] > 0 && ![bookingRef isEqualToString:@"null"]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Book a cab"
                                                            message:@"A cab has already been booked for the ride"
                                                           delegate:self
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
        [alertView show];
    } else {
        
        AddressModel *from = [self geocodeToAddressModelFromAddress:[[[self dictionaryRideDetails] objectForKey:@"FromLocation"] stringByReplacingOccurrencesOfString:@" "
                                                                                                                                                           withString:@"%20"]];
        AddressModel *to = [self geocodeToAddressModelFromAddress:[[[self dictionaryRideDetails] objectForKey:@"ToLocation"] stringByReplacingOccurrencesOfString:@" "
                                                                                                                                                       withString:@"%20"]];
        
        if (from && to) {
            [self setAddressFrom:from];
            [self setAddressTo:to];
            [self performSegueWithIdentifier:@"BookACabRideSegue"
                                      sender:self];
        } else {
            [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
        }
    }
}

- (void)checkCabStatusAndShowDialog {
    
    [self setShouldShowTripStartDialog:NO];
    
    NSString *cabStatus = [[self dictionaryRideDetails] objectForKey:@"CabStatus"];
    NSString *status = [[self dictionaryRideDetails] objectForKey:@"status"];
    
    NSArray *bookedCarPref = [self readBookedOrCarPreference];
    
    NSString *bookingRef = [[self dictionaryRideDetails] objectForKey:@"BookingRefNo"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd/MM/yyyy hh:mm a"];
    NSDate *startTime = [dateFormatter dateFromString:[NSString stringWithFormat:@"%@ %@", [[self dictionaryRideDetails] objectForKey:@"TravelDate"], [[self dictionaryRideDetails] objectForKey:@"TravelTime"]]];
    NSDate *currentTime = [NSDate date];
    
    if (cabStatus && status && [cabStatus isEqualToString:@"A"] && [status isEqualToString:@"0"]) {
        
        if (([startTime timeIntervalSinceDate:currentTime] / 60.0f) <= START_TRIP_NOTIFICATION_TIME) {
            
            if (bookingRef && [bookingRef isKindOfClass:[NSString class]] && [bookingRef length] > 0 && ![bookingRef isEqualToString:@"null"]) {
                [self showTripStartDialog];
            } else {
                if (bookedCarPref && [bookedCarPref count] > 0) {
                    if ([bookedCarPref containsObject:[[self dictionaryRideDetails] objectForKey:@"CabId"]]) {
                        [self showTripStartDialog];
                    } else {
                        [self setShouldShowTripStartDialog:YES];
                        [self showCabBookingDialog];
                    }
                } else {
                    [self setShouldShowTripStartDialog:YES];
                    [self showCabBookingDialog];
                }
            }
        } else if (([startTime timeIntervalSinceDate:currentTime] / 60.0f) <= UPCOMING_TRIP_NOTIFICATION_TIME) {
            if (bookingRef && [bookingRef isKindOfClass:[NSString class]] && [bookingRef length] > 0 && ![bookingRef isEqualToString:@"null"]) {
                //do nothing
            } else {
                if (bookedCarPref && [bookedCarPref count] > 0) {
                    if ([bookedCarPref containsObject:[[self dictionaryRideDetails] objectForKey:@"CabId"]]) {
                        //do nothing
                    } else {
                        [self setShouldShowTripStartDialog:NO];
                        [self showCabBookingDialog];
                    }
                } else {
                    [self setShouldShowTripStartDialog:NO];
                    [self showCabBookingDialog];
                }
            }
        }
    } else if (cabStatus && status && [cabStatus isEqualToString:@"A"] && [status isEqualToString:@"2"]) {
        [self showRideCompleteDialog];
    } else if (cabStatus && status && [cabStatus isEqualToString:@"A"] && [status isEqualToString:@"3"]) {
        //TODO show payment
    } else if (cabStatus && status && [cabStatus isEqualToString:@"A"]) {
        [Logger logDebug:[self TAG]
                 message:[NSString stringWithFormat:@" cabStatus startTime : %f ExpTripDuration : %ld", [currentTime timeIntervalSinceDate:startTime], [[[self dictionaryRideDetails] objectForKey:@"ExpTripDuration"] integerValue]]];
        if ([currentTime timeIntervalSinceDate:startTime] >= [[[self dictionaryRideDetails] objectForKey:@"ExpTripDuration"] integerValue]) {
            
            [self showActivityIndicatorView];
            
            GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
            [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                               endPoint:ENDPOINT_UPDATE_CAB_STATUS
                                                             parameters:[NSString stringWithFormat:@"cabId=%@", [[self dictionaryRideDetails] objectForKey:@"CabId"]]
                                                    delegateForProtocol:self];
        }
    }
}

- (void)showTripStartDialog {
    
    if ([[self arrayMembers] count] <= 0) {
        return;
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Upcoming trip"
                                                        message:@"Member(s) of your trip will receive your location updates once you start the ride"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Start the ride now", nil];
    [alertView show];
    
    [self setAlertViewTripStart:alertView];
}

- (void)showCabBookingDialog {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Upcoming trip"
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Book a cab", @"Already booked", @"Driving my own car", @"Cancel trip", nil];
    [alertView show];
    
    [self setAlertViewCabBooking:alertView];
}

- (void)showRideCompleteDialog {
    
    if ([[self arrayMembers] count] <= 0) {
        return;
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Your trip is completed, tell us if you paid the fare"
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"I paid, calculate fare split", @"Someone else paid", @"Already settled", nil];
    [alertView show];
    
    [self setAlertViewRideComplete:alertView];
}

- (void)showFareSplitDialog {
    
    if ([[self arrayMembers] count] <= 0) {
        return;
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Fare Split"
                                                        message:@"Please enter fare to split :"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Split by distance", @"Split equally", nil];
    [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[alertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
    
    [alertView show];
    
    [self setAlertViewFareSplitAmount:alertView];
}

- (void)showPaymentsDialog {
    
}

- (void)saveBookedOrCarPreference:(NSString *)cabID {
    NSArray *array = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_BOOKED_OR_CAR_PREFERENCE];
    NSMutableArray *arrayMutable;
    if (array && [array count] > 0) {
        arrayMutable = [array mutableCopy];
    } else {
        arrayMutable = [NSMutableArray array];
    }
    
    [arrayMutable addObject:cabID];
    
    [[NSUserDefaults standardUserDefaults] setObject:[arrayMutable copy]
                                              forKey:KEY_USER_DEFAULT_BOOKED_OR_CAR_PREFERENCE];
}

- (NSArray *)readBookedOrCarPreference {
    return [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_BOOKED_OR_CAR_PREFERENCE];
}

- (AddressModel *)geocodeToAddressModelFromAddress:(NSString *)address {
    
    AddressModel *model = nil;
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/geocode/json?address=%@&key=%@", address, GOOGLE_MAPS_API_KEY]]];
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest
                                         returningResponse:&response
                                                     error:&error];
    
    if (!error) {
        //        NSString *resp = [[NSString alloc] initWithData:data
        //                                               encoding:NSUTF8StringEncoding];
        //        [Logger logDebug:[self TAG]
        //                 message:[NSString stringWithFormat:@" PLACES_API_BASE response : %@", resp]];
        
        NSError *errorParse = nil;
        NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingMutableContainers
                                                                     error:&errorParse];
        if (!errorParse) {
            if ([[parsedJson objectForKey:@"status"] isEqualToString:@"OK"]) {
                
                NSDictionary *resultDictionary = [[parsedJson objectForKey:@"results"] firstObject];
                
                model = [[AddressModel alloc] init];
                CLLocation *location = [[CLLocation alloc] initWithLatitude:[[[[resultDictionary objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lat"] doubleValue]
                                                                  longitude:[[[[resultDictionary objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lng"] doubleValue]];
                [model setLocation:location];
                [model setLongName:[resultDictionary objectForKey:@"formatted_address"]];
                
                NSArray *addressComponents = [resultDictionary objectForKey:@"address_components"];
                
                NSString *subLocality = @"", *locality = @"";
                for (NSDictionary *dict in addressComponents) {
                    if ([[[dict objectForKey:@"types"] description] rangeOfString:@"sublocality"].location != NSNotFound) {
                        subLocality = [dict objectForKey:@"long_name"];
                    }
                    if ([[[dict objectForKey:@"types"] description] rangeOfString:@"locality"].location != NSNotFound) {
                        locality = [dict objectForKey:@"long_name"];
                    }
                }
                
                if ([subLocality length] > 0) {
                    [model setShortName:[NSString stringWithFormat:@"%@, %@", subLocality, locality]];
                } else {
                    [model setShortName:locality];
                }
            } else {
                [Logger logError:[self TAG]
                         message:[NSString stringWithFormat:@" geocodeToAddressModelFromAddress API status error : %@", [parsedJson objectForKey:@"status"]]];
            }
        } else {
            [Logger logError:[self TAG]
                     message:[NSString stringWithFormat:@" geocodeToAddressModelFromAddress parsing error : %@", [errorParse localizedDescription]]];
        }
    } else {
        [Logger logError:[self TAG]
                 message:[NSString stringWithFormat:@" geocodeToAddressModelFromAddress error : %@", [error localizedDescription]]];
    }
    
    return model;
}

- (void)changeChatStatus:(NSString *)status {
    
}

#pragma mark - GlobalMethodsAsyncRequestProtocol methods

- (void)asyncRequestComplete:(GlobalMethods *)sender
                        data:(NSDictionary *)data {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString *error = [data valueForKey:KEY_ERROR_ASYNC_REQUEST];
        
        if([error isEqualToString:ERROR_CONNECTION_VALUE]) {
            [self makeToastWithMessage:NO_INTERNET_ERROR_MESSAGE];
        } else if ([error isEqualToString:ERROR_DATA_NIL_VALUE]) {
            [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
        } else if ([error isEqualToString:ERROR_UNAUTHORIZED_ACCESS]) {
            [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
        } else {
            NSString *endPoint = [data valueForKey:KEY_ENDPOINT_ASYNC_CONNECTION];
            if ([endPoint isEqualToString:ENDPOINT_SHOW_MEMBERS_ON_MAP]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                if (response && [response caseInsensitiveCompare:@"No Members joined yet"] == NSOrderedSame) {
                    [self getPathNoMembersJoined];
                } else {
                    NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                    NSError *error = nil;
                    NSArray *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                          options:NSJSONReadingMutableContainers
                                                                            error:&error];
                    if (!error) {
                        //                        [Logger logDebug:[self TAG]
                        //                                 message:[NSString stringWithFormat:@" parsedJson : %@", parsedJson]];
                        
                        [self setArrayMembers:parsedJson];
                        
                        NSString *wayPoint = @"&waypoints=optimize:true";
                        for (int i = 0; i < [[self arrayMembers] count]; i++) {
                            NSString *pickLatLng = [[[self arrayMembers] objectAtIndex:i] objectForKey:@"MemberLocationlatlong"];
                            NSArray *array = [pickLatLng componentsSeparatedByString:@","];
                            wayPoint = [wayPoint stringByAppendingString:@"%7C"];
                            wayPoint = [wayPoint stringByAppendingString:[NSString stringWithFormat:@"%@,%@", [array firstObject], [array lastObject]]];
                            
                            NSString *dropLatLng = [[[self arrayMembers] objectAtIndex:i] objectForKey:@"MemberEndLocationlatlong"];
                            array = [dropLatLng componentsSeparatedByString:@","];
                            wayPoint = [wayPoint stringByAppendingString:@"%7C"];
                            wayPoint = [wayPoint stringByAppendingString:[NSString stringWithFormat:@"%@,%@", [array firstObject], [array lastObject]]];
                        }
                        
                        [self getPathForMembersJoinedWithWayPoints:wayPoint];
                    } else {
                        [Logger logError:[self TAG]
                                 message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                        [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                    }
                }
                
            } else if ([endPoint isEqualToString:ENDPOINT_CANCEL_POOL_OWNER]) {
                
                [[UIApplication sharedApplication] cancelAllLocalNotifications];
                
                [self hideActivityIndicatorView];
                [self popVC];
            } else if ([endPoint isEqualToString:ENDPOINT_OWNER_INVITE_FRIENDS]) {
                [self hideActivityIndicatorView];
                [self makeToastWithMessage:@"Invitation sent!"];
            } else if ([endPoint isEqualToString:ENDPOINT_UPDATE_CAB_STATUS]) {
                [self hideActivityIndicatorView];
            } else if ([endPoint isEqualToString:ENDPOINT_START_TRIP_NOTIFICATION]) {
                [self hideActivityIndicatorView];
            } else if ([endPoint isEqualToString:ENDPOINT_TRIP_COMPLETED]) {
                [self hideActivityIndicatorView];
                [self popVC];
            } else if ([endPoint isEqualToString:ENDPOINT_SAVE_CALCULATED_FARE]) {
                [self hideActivityIndicatorView];
                
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                      options:NSJSONReadingMutableContainers
                                                                        error:&error];
                if (!error) {
                    //                        [Logger logDebug:[self TAG]
                    //                                 message:[NSString stringWithFormat:@" parsedJson : %@", parsedJson]];
                    if ([[parsedJson objectForKey:@"status"] isEqualToString:@"fail"]) {
                        [self makeToastWithMessage:[parsedJson objectForKey:@"message"]];
                    }
                    
                } else {
                    [Logger logError:[self TAG]
                             message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                    [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                }
            } else if ([endPoint isEqualToString:ENDPOINT_UBER_CANCEL]) {
                [self hideActivityIndicatorView];
                
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                           options:NSJSONReadingMutableContainers
                                                                             error:&error];
                if (!error) {
                    //                        [Logger logDebug:[self TAG]
                    //                                 message:[NSString stringWithFormat:@" parsedJson : %@", parsedJson]];
                    if ([[parsedJson objectForKey:@"status"] caseInsensitiveCompare:@"SUCCESS"] == NSOrderedSame) {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                            message:@"Booking cancelled!"
                                                                           delegate:self
                                                                  cancelButtonTitle:@"Ok"
                                                                  otherButtonTitles:nil];
                        [alertView show];
                    } else {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cab could not be cancelled"
                                                                            message:[parsedJson objectForKey:@"message"]
                                                                           delegate:self
                                                                  cancelButtonTitle:@"Ok"
                                                                  otherButtonTitles:nil];
                        [alertView show];
                    }
                    
                } else {
                    [Logger logError:[self TAG]
                             message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                    [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                }
            } else if ([endPoint isEqualToString:ENDPOINT_MEGA_API]) {
                [self hideActivityIndicatorView];
                
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                           options:NSJSONReadingMutableContainers
                                                                             error:&error];
                if (!error) {
                    //                        [Logger logDebug:[self TAG]
                    //                                 message:[NSString stringWithFormat:@" parsedJson : %@", parsedJson]];
                    if ([[parsedJson objectForKey:@"status"] caseInsensitiveCompare:@"SUCCESS"] == NSOrderedSame) {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                            message:@"Booking cancelled!"
                                                                           delegate:self
                                                                  cancelButtonTitle:@"Ok"
                                                                  otherButtonTitles:nil];
                        [alertView show];
                    } else {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cab could not be cancelled"
                                                                            message:[parsedJson objectForKey:@"data"]
                                                                           delegate:self
                                                                  cancelButtonTitle:@"Ok"
                                                                  otherButtonTitles:nil];
                        [alertView show];
                    }
                    
                } else {
                    [Logger logError:[self TAG]
                             message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                    [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                }
            } else if ([endPoint isEqualToString:ENDPOINT_TAXI_FOR_SURE_API]) {
                [self hideActivityIndicatorView];
                
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                           options:NSJSONReadingMutableContainers
                                                                             error:&error];
                if (!error) {
                    //                        [Logger logDebug:[self TAG]
                    //                                 message:[NSString stringWithFormat:@" parsedJson : %@", parsedJson]];
                    if ([[parsedJson objectForKey:@"status"] caseInsensitiveCompare:@"SUCCESS"] == NSOrderedSame) {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                            message:@"Booking cancelled!"
                                                                           delegate:self
                                                                  cancelButtonTitle:@"Ok"
                                                                  otherButtonTitles:nil];
                        [alertView show];
                    } else {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cab could not be cancelled"
                                                                            message:[parsedJson objectForKey:@"error_desc"]
                                                                           delegate:self
                                                                  cancelButtonTitle:@"Ok"
                                                                  otherButtonTitles:nil];
                        [alertView show];
                    }
                    
                } else {
                    [Logger logError:[self TAG]
                             message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                    [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                }
            } else if ([endPoint isEqualToString:ENDPOINT_OLA_CANCEL]) {
                [self hideActivityIndicatorView];
                
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                           options:NSJSONReadingMutableContainers
                                                                             error:&error];
                if (!error) {
                    //                        [Logger logDebug:[self TAG]
                    //                                 message:[NSString stringWithFormat:@" parsedJson : %@", parsedJson]];
                    if ([[parsedJson objectForKey:@"status"] caseInsensitiveCompare:@"SUCCESS"] == NSOrderedSame) {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                            message:@"Booking cancelled!"
                                                                           delegate:self
                                                                  cancelButtonTitle:@"Ok"
                                                                  otherButtonTitles:nil];
                        [alertView show];
                    } else {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cab could not be cancelled"
                                                                            message:[parsedJson objectForKey:@"reason"]
                                                                           delegate:self
                                                                  cancelButtonTitle:@"Ok"
                                                                  otherButtonTitles:nil];
                        [alertView show];
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

@end
