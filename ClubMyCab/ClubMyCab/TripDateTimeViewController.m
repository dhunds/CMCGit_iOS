//
//  TripDateTimeViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 23/11/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import "TripDateTimeViewController.h"
#import "Logger.h"
#import "ActivityIndicatorView.h"
#import "ToastLabel.h"
#import "GlobalMethods.h"
#import "ClubsInviteViewController.h"
#import "MyClubsViewController.h"
#import "GenericContactsViewController.h"

@interface TripDateTimeViewController () <GlobalMethodsAsyncRequestProtocol, UIAlertViewDelegate, ClubsInviteVCProtocol, GenericContactsVCProtocol>

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) NSString *mobileNumber;

@property (weak, nonatomic) IBOutlet UILabel *labelSelectDateTime;
@property (weak, nonatomic) IBOutlet UILabel *labelCoPassengers;
@property (weak, nonatomic) IBOutlet UILabel *labelHeaderCoPassengers;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBarDatePicker;
@property (weak, nonatomic) IBOutlet UIView *viewCoPassengers;
@property (weak, nonatomic) IBOutlet UIView *viewChargesPerSeat;
@property (weak, nonatomic) IBOutlet UILabel *labelChargesPerSeat;

@property (strong, nonatomic) NSString *tripDateTime;

@property (strong, nonatomic) NSString *cabID;
@property (strong, nonatomic) NSDate *startTime;

@property (strong, nonatomic) UIAlertView *alertViewClubs, *alertViewInvite;

@property (nonatomic) BOOL shouldOfferFree;

@end

@implementation TripDateTimeViewController

- (NSString *)TAG {
    return @"TripDateTimeViewController";
}

#pragma mark - View Controller Life Cycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [self setMobileNumber:[userDefaults objectForKey:KEY_USER_DEFAULT_MOBILE]];
    
    NSDate *date = [[NSDate date] dateByAddingTimeInterval:(30 * 60)];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd/MM/yyyy  hh:mm a"];
    
    [[self labelSelectDateTime] setText:[dateFormatter stringFromDate:date]];
    
    [self setTripDateTime:[dateFormatter stringFromDate:date]];
    
    [[self labelCoPassengers] setText:@"3"];
    if ([[self segueType] isEqualToString:HOME_SEGUE_TYPE_CAR_POOL]) {
        [[self viewChargesPerSeat] setHidden:NO];
        [[self labelChargesPerSeat] setText:@"3"];
        [self setShouldOfferFree:NO];
    } else {
        [[self viewChargesPerSeat] setHidden:YES];
    }
    
    [[self datePicker] setMinimumDate:[NSDate date]];
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" viewDidLoad from : %@ to : %@", [[self addressModelFrom] longName], [[self addressModelTo] longName]]];
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
    
    if ([[segue identifier] isEqualToString:@"InviteClubsSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[ClubsInviteViewController class]]) {
            
            NSArray *parsedJson = sender;
            
            NSMutableArray *mutableMyClubs = [NSMutableArray array];
            NSMutableArray *mutableMemberOfClubs = [NSMutableArray array];
            
            for (int i = 0; i < [parsedJson count]; i++) {
                if ([[[parsedJson objectAtIndex:i] objectForKey:@"IsPoolOwner"] isEqualToString:@"1"]) {
                    [mutableMyClubs addObject:[parsedJson objectAtIndex:i]];
                } else {
                    [mutableMemberOfClubs addObject:[parsedJson objectAtIndex:i]];
                }
            }
            
            [(ClubsInviteViewController *)[segue destinationViewController] setArrayMyClubs:[mutableMyClubs copy]];
            [(ClubsInviteViewController *)[segue destinationViewController] setArrayMemberOfClubs:[mutableMemberOfClubs copy]];
            [(ClubsInviteViewController *)[segue destinationViewController] setDelegateClubsInviteVC:self];
            [(ClubsInviteViewController *)[segue destinationViewController] setNumberOfSeats:[[[self labelCoPassengers] text] intValue]];
        }
    } else if ([[segue identifier] isEqualToString:@"TripClubsSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[MyClubsViewController class]]) {
            
        }
    } else if ([[segue identifier] isEqualToString:@"InviteContactsSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[GenericContactsViewController class]]) {
            [(GenericContactsViewController *)[segue destinationViewController] setSegueType:SEGUE_FROM_RIDE_INVITATION];
            [(GenericContactsViewController *)[segue destinationViewController] setDelegateGenericContactsVC:self];
        }
    }
}

#pragma mark - ClubsInviteVCProtocol methods

- (void)membersToInviteFrom:(ClubsInviteViewController *)sender
                withNumbers:(NSString *)numbers
                   andNames:(NSString *)names {
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" ClubsInviteVCProtocol numbers : %@ names : %@", numbers, names]];
    
    [self invitePeopleForRideWithNumbers:numbers
                                andNames:names];
}

#pragma mark - GenericContactsVCProtocol methods

- (void)contactsToInviteFrom:(GenericContactsViewController *)sender
                 withNumbers:(NSString *)numbers
                    andNames:(NSString *)names {
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" GenericContactsVCProtocol numbers : %@ names : %@", numbers, names]];
    
    [self invitePeopleForRideWithNumbers:numbers
                                andNames:names];
}

#pragma mark - Private methods

- (void)hideDatePicker {
    [[self datePicker] setHidden:YES];
    [[self toolBarDatePicker] setHidden:YES];
    
//    [[self labelHeaderCoPassengers] setHidden:NO];
//    [[self labelCoPassengers] setHidden:NO];
    [[self viewCoPassengers] setHidden:NO];
    [[self viewChargesPerSeat] setHidden:([[self segueType] isEqualToString:HOME_SEGUE_TYPE_CAR_POOL] ? NO : YES)];
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

- (void)popVC {
    [[self navigationController] popViewControllerAnimated:NO];
}

- (void)invitePeopleForRideWithNumbers:(NSString *)numbers
                              andNames:(NSString *)names {
    [self showActivityIndicatorView];
    
    NSString *urlString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/directions/json?origin=%@&destination=%@&sensor=false&units=metric&mode=driving&alternatives=true&key=%@", [[[self addressModelFrom] longName] stringByReplacingOccurrencesOfString:@" "
                                                                                                                                                                                                                                                                     withString:@"%20"], [[[self addressModelTo] longName] stringByReplacingOccurrencesOfString:@" "
                                                                                                                                                                                                                                                                                                                                                     withString:@"%20"], GOOGLE_MAPS_API_KEY];
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setURL:[NSURL URLWithString:urlString]];
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" googleapis directions url : %@", urlString]];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (!connectionError && data) {
                                   //                                   NSString *resp = [[NSString alloc] initWithData:data
                                   //                                                                          encoding:NSUTF8StringEncoding];
                                   //
                                   //                                   [Logger logDebug:[self TAG]
                                   //                                            message:[NSString stringWithFormat:@" googleapis directions response : %@", resp]];
                                   
                                   NSError *error = nil;
                                   NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:data
                                                                                              options:NSJSONReadingMutableContainers
                                                                                                error:&error];
                                   if (!error) {
                                       NSString *distancevalue = @"", *distancetext = @"", *durationvalue = @"", *durationtext = @"";
                                       NSArray *routes = [parsedJson objectForKey:@"routes"];
                                       for (int i = 0; i < [routes count]; i++) {
                                           NSArray *legs = [[routes objectAtIndex:i] objectForKey:@"legs"];
                                           for (int j = 0; j < [legs count]; j++) {
                                               NSDictionary *distance = [[legs objectAtIndex:j] objectForKey:@"distance"];
                                               NSDictionary *duration = [[legs objectAtIndex:j] objectForKey:@"duration"];
                                               
                                               distancevalue = [distance objectForKey:@"value"];
                                               distancetext = [distance objectForKey:@"text"];
                                               durationvalue = [duration objectForKey:@"value"];
                                               durationtext = [duration objectForKey:@"text"];
                                           }
                                       }
                                       
                                       NSString *cabID = [NSString stringWithFormat:@"%@%1.0f", [self mobileNumber], ([[NSDate date] timeIntervalSince1970] * 1000)];
                                       [self setCabID:cabID];
                                       NSArray *array = [[self tripDateTime] componentsSeparatedByString:@"  "];
                                       NSString *date = [array firstObject];
                                       NSString *time = [array lastObject];
                                       
                                       NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                                       [dateFormatter setDateFormat:@"dd/MM/yyyy  hh:mm a"];
                                       NSDate *starttime = [dateFormatter dateFromString:[NSString stringWithFormat:@"%@ %@", date, time]];
                                       [self setStartTime:starttime];
                                       
                                       NSString *seats = [[self labelCoPassengers] text];
                                       NSString *ownerName = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_NAME];
                                       
                                       NSString *message = @"";
                                       NSString *rideType = @"";
                                       NSString *perKm = @"";
                                       
                                       if ([[self segueType] isEqualToString:HOME_SEGUE_TYPE_CAR_POOL]) {
                                           perKm = [[self labelChargesPerSeat] text];
                                           message = [NSString stringWithFormat:@"%@ invited you to join a car pool from %@ to %@ at Rs.%@ per Km", ownerName, [[self addressModelFrom] shortName], [[self addressModelTo] shortName], perKm];
                                           rideType = @"1";
                                       } else {
                                           perKm = @"0";
                                           message = [NSString stringWithFormat:@"%@ invited you to share a cab from %@ to %@", ownerName, [[self addressModelFrom] shortName], [[self addressModelTo] shortName]];
                                           rideType = @"2";
                                       }
                                       
                                       NSString *parameters = [NSString stringWithFormat:@"CabId=%@&MobileNumber=%@&OwnerName=%@&FromLocation=%@&ToLocation=%@&FromShortName=%@&ToShortName=%@&TravelDate=%@&TravelTime=%@&Seats=%@&RemainingSeats=%@&Distance=%@&ExpTripDuration=%@&MembersNumber=%@&MembersName=%@&Message=%@&rideType=%@&perKmCharge=%@", cabID, [self mobileNumber], ownerName, [[self addressModelFrom] longName], [[self addressModelTo] longName], [[self addressModelFrom] shortName], [[self addressModelTo] shortName], date, time, seats, seats, distancetext, durationvalue, numbers, names, message, rideType, perKm];
                                       
                                       [Logger logDebug:[self TAG]
                                                message:[NSString stringWithFormat:@" googleapis directions parameters : %@", parameters]];
                                       
                                       
                                       GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
                                       [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                                                          endPoint:ENDPOINT_OPEN_A_CAB
                                                                                        parameters:parameters
                                                                               delegateForProtocol:self];
                                       
                                   } else {
                                       [Logger logError:[self TAG]
                                                message:[NSString stringWithFormat:@" googleapis directions parsing error : %@", [error localizedDescription]]];
                                   }
                               } else {
                                   [Logger logError:[self TAG]
                                            message:[NSString stringWithFormat:@" googleapis directions error : %@", [connectionError localizedDescription]]];
                               }
                           }];
}

#pragma mark - GlobalMethodsAsyncRequestProtocol methods

#define NO_CLUBS_CREATE                 @"Yes, Create group"
#define NO_CLUBS_CONTACTS               @"No, Invite contacts"
#define I_AM_DONE                       @"I'm done here"
#define START_OVER                      @"Start over again"

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
            } else if ([endPoint isEqualToString:ENDPOINT_FETCH_CLUBS]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                if (response && [response caseInsensitiveCompare:@"No Users of your Club"] == NSOrderedSame) {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No Groups"
                                                                        message:@"You are not a member of any group yet. Would you like to create one now?"
                                                                       delegate:self
                                                              cancelButtonTitle:nil
                                                              otherButtonTitles:NO_CLUBS_CREATE, NO_CLUBS_CONTACTS, nil];
                    [alertView show];
                    
                    [self setAlertViewClubs:alertView];
                } else {
                    NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                    NSError *error = nil;
                    NSArray *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                          options:NSJSONReadingMutableContainers
                                                                            error:&error];
                    if (!error) {
                        [self performSegueWithIdentifier:@"InviteClubsSegue"
                                                  sender:parsedJson];
                    } else {
                        [Logger logError:[self TAG]
                                 message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                        [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                    }
                }
                
            } else if ([endPoint isEqualToString:ENDPOINT_OPEN_A_CAB]) {
                
                UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                [localNotification setFireDate:[[self startTime] dateByAddingTimeInterval:(-1 * 60 * UPCOMING_TRIP_NOTIFICATION_TIME)]];
                [localNotification setAlertBody:[NSString stringWithFormat:@"You have an upcoming trip from %@ to %@. Click here to book a cab", [[self addressModelFrom] shortName], [[self addressModelTo] shortName]]];
                [localNotification setSoundName:UILocalNotificationDefaultSoundName];
                [localNotification setUserInfo:[NSDictionary dictionaryWithObject:[self cabID]
                                                                           forKey:@"CabID"]];
                [localNotification setTimeZone:[NSTimeZone defaultTimeZone]];
                [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                
                localNotification = [[UILocalNotification alloc] init];
                [localNotification setFireDate:[[self startTime] dateByAddingTimeInterval:(-1 * 60 * START_TRIP_NOTIFICATION_TIME)]];
                [localNotification setAlertBody:[NSString stringWithFormat:@"Your trip from %@ to %@ is about to start", [[self addressModelFrom] shortName], [[self addressModelTo] shortName]]];
                [localNotification setSoundName:UILocalNotificationDefaultSoundName];
                [localNotification setUserInfo:[NSDictionary dictionaryWithObject:[self cabID]
                                                                           forKey:@"CabID"]];
                [localNotification setTimeZone:[NSTimeZone defaultTimeZone]];
                [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                    message:@"Your friend(s) have been informed about the ride! We will let you know when they join. Sit back & relax!"
                                                                   delegate:self
                                                          cancelButtonTitle:@"Ok"
                                                          otherButtonTitles:nil];
                [alertView show];
                
                [self setAlertViewInvite:alertView];
            }
        }
    });
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    
    if (alertView == [self alertViewClubs]) {
        if ([buttonTitle isEqualToString:NO_CLUBS_CREATE]) {
            [self performSegueWithIdentifier:@"TripClubsSegue"
                                      sender:self];
        } else if ([buttonTitle isEqualToString:NO_CLUBS_CONTACTS]) {
            [self performSegueWithIdentifier:@"InviteContactsSegue"
                                      sender:self];
        }
    } else if (alertView == [self alertViewInvite]) {
        
//        [Logger logDebug:[self TAG]
//                 message:[NSString stringWithFormat:@" alertViewInvite : %@", [[[self navigationController] viewControllers] description]]];
        
        [[self navigationController] popToRootViewControllerAnimated:YES];
        
//        if ([buttonTitle isEqualToString:I_AM_DONE]) {
//            //handle exit with an alert view, abrupt quit not apple approved way
//            exit(0);
//        } else if ([buttonTitle isEqualToString:START_OVER]) {
//            [self popVC];
//        }
    }
}

#pragma mark - IBAction methods

- (IBAction)nextPressed:(UIButton *)sender {
    [self showActivityIndicatorView];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_FETCH_CLUBS
                                                     parameters:[NSString stringWithFormat:@"OwnerNumber=%@", [self mobileNumber]]
                                            delegateForProtocol:self];
}

- (IBAction)labelSelectDateTimePressed:(UITapGestureRecognizer *)sender {
    
    [[self datePicker] setHidden:NO];
    [[self toolBarDatePicker] setHidden:NO];
    
//    [[self labelHeaderCoPassengers] setHidden:YES];
//    [[self labelCoPassengers] setHidden:YES];
    [[self viewCoPassengers] setHidden:YES];
    [[self viewChargesPerSeat] setHidden:YES];
}

- (IBAction)selectDateTimePressed:(UIButton *)sender {
    [self labelSelectDateTimePressed:nil];
}

- (IBAction)labelCoPassengersPressed:(UITapGestureRecognizer *)sender {
    [self hideDatePicker];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@""
                                                                             message:@"Select number of seats"
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (int i = 1; i <= 6; i++) {
        [alertController addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%d", i]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              [[self labelCoPassengers] setText:[action title]];
                                                          }]];
    }
    
    [self presentViewController:alertController
                       animated:YES
                     completion:^{}];
}

- (IBAction)coPassengersPressed:(UIButton *)sender {
    [self labelCoPassengersPressed:nil];
}

- (IBAction)datePickerValueChanged:(UIDatePicker *)sender {
    NSDate *date = [sender date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd/MM/yyyy  hh:mm a"];
    
    [[self labelSelectDateTime] setText:[dateFormatter stringFromDate:date]];
    
    [self setTripDateTime:[dateFormatter stringFromDate:date]];
}

- (IBAction)datePickerDonePressed:(UIBarButtonItem *)sender {
    [self hideDatePicker];
    
    NSDate *date = [[self datePicker] date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd/MM/yyyy  hh:mm a"];
    
    [[self labelSelectDateTime] setText:[dateFormatter stringFromDate:date]];
    
    [self setTripDateTime:[dateFormatter stringFromDate:date]];
}

- (IBAction)offerForFreePressed:(UIButton *)sender {
    if ([self shouldOfferFree]) {
        [self setShouldOfferFree:NO];
        [sender setImage:[UIImage imageNamed:@"checkbox_unchecked.png"]
                forState:UIControlStateNormal];
        [[self labelChargesPerSeat] setText:@"3"];
    } else {
        [self setShouldOfferFree:YES];
        [sender setImage:[UIImage imageNamed:@"checkbox_checked.png"]
                forState:UIControlStateNormal];
        [[self labelChargesPerSeat] setText:@"0"];
    }
}

- (IBAction)labelChargesPerSeatPressed:(UITapGestureRecognizer *)sender {
    
    if ([self shouldOfferFree]) {
        return;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@""
                                                                             message:@"Select charges per seat"
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (int i = 1; i <= 5; i++) {
        [alertController addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%d", i]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              [[self labelChargesPerSeat] setText:[action title]];
                                                          }]];
    }
    
    [self presentViewController:alertController
                       animated:YES
                     completion:^{}];
}

- (IBAction)chargesPerSeatPressed:(UIButton *)sender {
    [self labelChargesPerSeatPressed:nil];
}

@end
