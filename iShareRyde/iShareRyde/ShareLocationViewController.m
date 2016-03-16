//
//  ShareLocationViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 11/09/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import "ShareLocationViewController.h"
#import "SWRevealViewController.h"
#import "Logger.h"
#import "ActivityIndicatorView.h"
#import "ToastLabel.h"
#import "GlobalMethods.h"
#import "AppDelegate.h"
#import "GenericLocationPickerViewController.h"
#import "PlacesAutoCompleteViewController.h"
#import <Google/Analytics.h>
#import "ClubsInviteViewController.h"
#import "GenericContactsViewController.h"

@interface ShareLocationViewController () <CLLocationManagerDelegate, UITextFieldDelegate, PlacesAutoCompleteVCProtocol, GenericLocationPickerVCProtocol, ClubsInviteVCProtocol, ClubsInviteVCShareLocationProtocol, GenericContactsVCProtocol>

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) NSString *sharingType, *currentDuration, *recipientNames, *recipientNumbers, *recipientClubs;

@property (strong, nonatomic) AddressModel *addressModel;

@property (strong, nonatomic) NSArray *arrayMyClubs, *arrayMemberOfClubs;
@property (nonatomic) BOOL hasClubs;

@property (weak, nonatomic) IBOutlet UIButton *buttonSelectRecipients;
@property (weak, nonatomic) IBOutlet UIButton *buttonSelectTime;
@property (weak, nonatomic) IBOutlet UITextField *textFieldDestination;
@property (weak, nonatomic) IBOutlet UIButton *buttonDestinationMap;
@property (weak, nonatomic) IBOutlet UIButton *buttonStart;
@property (weak, nonatomic) IBOutlet UITextView *textViewRecipients;

@end

@implementation ShareLocationViewController

#define CONSTANT_TEXT_MINUTES                   @" minutes"
#define BUTTON_TITLE_START                      @"Start"
#define BUTTON_TITLE_STOP                       @"Stop"

- (NSString *)TAG {
    return @"ShareLocationViewController";
}

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        [_locationManager setDelegate:self];
    }
    return _locationManager;
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
    
    [[self textFieldDestination] setDelegate:self];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:KEY_IS_LOCATION_SHARING_ON]) {
        [[self buttonStart] setTitle:BUTTON_TITLE_STOP
                            forState:UIControlStateNormal];
        
        [[self buttonSelectRecipients] setEnabled:NO];
        [[self buttonSelectTime] setEnabled:NO];
        [[self textFieldDestination] setEnabled:NO];
        [[self buttonDestinationMap] setEnabled:NO];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        NSString *type = [userDefaults objectForKey:KEY_SHARE_LOCATION_TYPE];
        if ([type isEqualToString:SHARE_LOCATION_TYPE_DURATION]) {
            [[self buttonSelectTime] setTitle:[userDefaults objectForKey:KEY_SHARE_LOCATION_DURATION]
                                     forState:UIControlStateNormal];
            [[self textFieldDestination] setText:@""];
        } else if ([type isEqualToString:SHARE_LOCATION_TYPE_DESTINATION]) {
            [[self buttonSelectTime] setTitle:@"Select Time"
                                     forState:UIControlStateNormal];
            [[self textFieldDestination] setText:[userDefaults objectForKey:KEY_SHARE_LOCATION_DESTINATION]];
        }
        
        [[self textViewRecipients] setText:[userDefaults objectForKey:KEY_SHARE_LOCATION_RECP_NAMES]];
        [[self textViewRecipients] setHidden:NO];
//        [self setRecipientNames:[userDefaults objectForKey:KEY_SHARE_LOCATION_RECP_NAMES]];
//        [self setRecipientNumbers:[userDefaults objectForKey:KEY_SHARE_LOCATION_RECP_NUMBERS]];
    } else {
        [[self buttonStart] setTitle:BUTTON_TITLE_START
                            forState:UIControlStateNormal];
        [[self buttonSelectRecipients] setEnabled:YES];
        [[self buttonSelectTime] setEnabled:YES];
        [[self textFieldDestination] setEnabled:YES];
        [[self buttonDestinationMap] setEnabled:YES];
        
        [[self textViewRecipients] setHidden:YES];
    }
    
    [[self textViewRecipients] setEditable:YES];
    [[self textViewRecipients] setFont:[UIFont systemFontOfSize:17.0f]];
    [[self textViewRecipients] setEditable:NO];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_FETCH_CLUBS
                                                     parameters:[NSString stringWithFormat:@"OwnerNumber=%@", [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_MOBILE]]
                                            delegateForProtocol:self];
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

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    
    [self performSegueWithIdentifier:@"AutoCompleteLocShareSegue"
                              sender:SEGUE_TYPE_HOME_PAGE_FROM_AUTO_COMPLETE];
    
    return NO;
}

#pragma mark - IBAction methods

- (IBAction)startPressed:(UIButton *)sender {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:KEY_IS_LOCATION_SHARING_ON]) {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate stopLocationSharing];
        [[self buttonStart] setTitle:BUTTON_TITLE_START
                            forState:UIControlStateNormal];
        [[self buttonSelectRecipients] setEnabled:YES];
        [[self buttonSelectTime] setEnabled:YES];
        [[self textFieldDestination] setEnabled:YES];
        [[self buttonDestinationMap] setEnabled:YES];
        
        [[self buttonSelectTime] setTitle:@"Select Time"
                                 forState:UIControlStateNormal];
        [[self textFieldDestination] setText:@""];
        [self setRecipientNames:@""];
        [self setRecipientNumbers:@""];
        [[self textViewRecipients] setText:@""];
        [[self textViewRecipients] setHidden:YES];
        
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Stop Location Sharing"
                                                              action:@"Stop Location Sharing"
                                                               label:@"Stop Location Sharing"
                                                               value:nil] build]];
    } else {
        if ([[[self buttonStart] titleForState:UIControlStateNormal] isEqualToString:BUTTON_TITLE_STOP]) {
            [[self buttonStart] setTitle:BUTTON_TITLE_START
                                forState:UIControlStateNormal];
            [[self buttonSelectRecipients] setEnabled:YES];
            [[self buttonSelectTime] setEnabled:YES];
            [[self textFieldDestination] setEnabled:YES];
            [[self buttonDestinationMap] setEnabled:YES];
            
            [[self buttonSelectTime] setTitle:@"Select Time"
                                     forState:UIControlStateNormal];
            [[self textFieldDestination] setText:@""];
            [self setRecipientNames:@""];
            [self setRecipientNumbers:@""];
            [[self textViewRecipients] setText:@""];
            [[self textViewRecipients] setHidden:YES];
        } else {
            [self checkLocationPermission];
        }
    }
    
}

- (IBAction)selectRecipientsPressed:(UIButton *)sender {
    if ([self hasClubs]) {
        [self performSegueWithIdentifier:@"ShareLocClubInviteSegue"
                                  sender:self];
    } else {
        [self performSegueWithIdentifier:@"ShareLocContactInviteSegue"
                                  sender:self];
    }
}

- (IBAction)selectTimePressed:(UIButton *)sender {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@""
                                                                             message:@"Please select an interval"
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (int i = 1; i <= 6; i++) {
        [alertController addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%d%@", (i * 10), CONSTANT_TEXT_MINUTES]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              [[self buttonSelectTime] setTitle:[action title]
                                                                                       forState:UIControlStateNormal];
                                                              [self setCurrentDuration:[[action title] stringByReplacingOccurrencesOfString:CONSTANT_TEXT_MINUTES
                                                                                                                                 withString:@""]];
                                                              [self setSharingType:SHARE_LOCATION_TYPE_DURATION];
                                                              [[self textFieldDestination] setText:@""];
                                                              [self setAddressModel:nil];
                                                          }]];
    }
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {}]];
    
    [self presentViewController:alertController
                       animated:YES
                     completion:^{}];
    
    
}

- (IBAction)destinationMapPressed:(UIButton *)sender {
    [self performSegueWithIdentifier:@"GenericShareLocationSegue"
                              sender:SEGUE_TYPE_HOME_PAGE_FROM_LOCATION];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([[segue identifier] isEqualToString:@"AutoCompleteLocShareSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[PlacesAutoCompleteViewController class]]) {
            [(PlacesAutoCompleteViewController *)[segue destinationViewController] setSegueType:sender];
            [(PlacesAutoCompleteViewController *)[segue destinationViewController] setDelegatePlacesAutoCompleteVC:self];
        }
    } else if ([[segue identifier] isEqualToString:@"GenericShareLocationSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[GenericLocationPickerViewController class]]) {
            [(GenericLocationPickerViewController *)[segue destinationViewController] setDelegateGenericLocationPickerVC:self];
            [(GenericLocationPickerViewController *)[segue destinationViewController] setSegueType:sender];

        }
    } else if ([[segue identifier] isEqualToString:@"ShareLocClubInviteSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[ClubsInviteViewController class]]) {
            
            [(ClubsInviteViewController *)[segue destinationViewController] setArrayMyClubs:[self arrayMyClubs]];
            [(ClubsInviteViewController *)[segue destinationViewController] setArrayMemberOfClubs:[self arrayMemberOfClubs]];
            [(ClubsInviteViewController *)[segue destinationViewController] setDelegateClubsInviteVC:self];
            [(ClubsInviteViewController *)[segue destinationViewController] setDelegateClubsInviteVCShareLocation:self];
//            [(ClubsInviteViewController *)[segue destinationViewController] setNumberOfSeats:[[[self labelCoPassengers] text] intValue]];
        }
    } else if ([[segue identifier] isEqualToString:@"ShareLocContactInviteSegue"]) {
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
    
    [[self navigationController] popViewControllerAnimated:NO];
    
    [self setRecipientNames:names];
    [self setRecipientNumbers:numbers];
    
    NSString *string = [[names stringByReplacingOccurrencesOfString:@"["
                                                         withString:@""] stringByReplacingOccurrencesOfString:@"]"
                        withString:@""];
    [[self textViewRecipients] setText:string];
    [[self textViewRecipients] setHidden:NO];
}

#pragma mark - ClubsInviteVCShareLocationProtocol methods

- (void)membersToInviteFrom:(ClubsInviteViewController *)sender
                withNumbers:(NSString *)numbers
                   andNames:(NSString *)names
               andClubNames:(NSString *)clubs {
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" ClubsInviteVCShareLocationProtocol numbers : %@ names : %@ clubs : %@", numbers, names, clubs]];
    
//    [[self navigationController] popViewControllerAnimated:NO];
    
    [self setRecipientNames:names];
    [self setRecipientNumbers:numbers];
    [self setRecipientClubs:clubs];
    
    [[self textViewRecipients] setText:[self recipientClubs]];
    [[self textViewRecipients] setHidden:NO];
}

#pragma mark - GenericContactsVCProtocol methods

- (void)contactsToInviteFrom:(GenericContactsViewController *)sender
                 withNumbers:(NSString *)numbers
                    andNames:(NSString *)names {
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" GenericContactsVCProtocol numbers : %@ names : %@", numbers, names]];
    
    [self setRecipientNames:names];
    [self setRecipientNumbers:numbers];
    
    NSString *string = [[names stringByReplacingOccurrencesOfString:@"["
                                                         withString:@""] stringByReplacingOccurrencesOfString:@"]"
                        withString:@""];
    [[self textViewRecipients] setText:string];
    [[self textViewRecipients] setHidden:NO];
}

#pragma mark - GenericLocationPickerVCProtocol methods

- (void)addressModelFromSender:(GenericLocationPickerViewController *)sender
                       address:(AddressModel *)model
                  forSegueType:(NSString *)segueType {
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" addressModelFromSender model : %@ segueType : %@", model, segueType]];
    
    [self setAddressModel:model];
    [[self textFieldDestination] setText:[[self addressModel] longName]];
    [self setSharingType:SHARE_LOCATION_TYPE_DESTINATION];
    [[self buttonSelectTime] setTitle:@"Select Time"
                             forState:UIControlStateNormal];
    [self setCurrentDuration:nil];
}

#pragma mark - PlacesAutoCompleteVCProtocol methods

- (void)addressModelFromSenderAutoComp:(PlacesAutoCompleteViewController *)sender
                               address:(AddressModel *)model
                          forSegueType:(NSString *)segueType {
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" addressModelFromSenderAutoComp model : %@ segueType : %@", model, segueType]];
    
    [self setAddressModel:model];
    [[self textFieldDestination] setText:[[self addressModel] longName]];
    [self setSharingType:SHARE_LOCATION_TYPE_DESTINATION];
    [[self buttonSelectTime] setTitle:@"Select Time"
                             forState:UIControlStateNormal];
    [self setCurrentDuration:nil];
}

#pragma mark - CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" didChangeAuthorizationStatus : %d", status]];
    
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        NSLog(@"kCLAuthorizationStatusAuthorizedAlways");
        [self startLocationUpdates];
    } else if (status == kCLAuthorizationStatusNotDetermined) {
        //nothing to do here
    } else {
        [self showLocationPermissionAlert];
    }
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:@"Settings"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

#pragma mark - Private methods

- (void)checkLocationPermission {
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" checkLocationPermission : %d", status]];
    
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        NSLog(@"kCLAuthorizationStatusAuthorizedAlways");
        [self startLocationUpdates];
    } else {
        [self getLocationPermission];
    }
}

- (void)getLocationPermission {
    [[self locationManager] requestAlwaysAuthorization];
}

- (void)showLocationPermissionAlert {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Location services off"
                                                        message:@"iShareRyde needs access to your location. Please provide access in Settings"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Cancel", @"Settings", nil];
    [alertView show];
}

- (void)startLocationUpdates {
    
    if ([[self recipientNames] length] <= 0 || [[self recipientNumbers] length] <= 0) {
        [self makeToastWithMessage:@"Please select recipients"];
        return;
    }
    
    if (![self addressModel] && [[self currentDuration] length] <= 0) {
        [self makeToastWithMessage:@"Please select a duration or destination"];
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:YES
                                            forKey:KEY_IS_LOCATION_SHARING_ON];
    [[self buttonStart] setTitle:BUTTON_TITLE_STOP
                        forState:UIControlStateNormal];
    [[self buttonSelectRecipients] setEnabled:NO];
    [[self buttonSelectTime] setEnabled:NO];
    [[self textFieldDestination] setEnabled:NO];
    [[self buttonDestinationMap] setEnabled:NO];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate initiateLocationSharingForType:[self sharingType]
                                    forDuration:([[self currentDuration] intValue] * 60)
                                   tillLocation:([self addressModel] ? [[self addressModel] location] : nil)
                                recipientsNames:[self recipientNames]
                              recipientsNumbers:[self recipientNumbers]
                                          cabID:@""];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[self sharingType]
                     forKey:KEY_SHARE_LOCATION_TYPE];
    [userDefaults setObject:[NSString stringWithFormat:@"%@%@", [self currentDuration], CONSTANT_TEXT_MINUTES]
                     forKey:KEY_SHARE_LOCATION_DURATION];
    [userDefaults setObject:([self addressModel] ? [[self addressModel] longName] : nil)
                     forKey:KEY_SHARE_LOCATION_DESTINATION];
    NSString *string = @"";
    if ([[self recipientClubs] length] > 0) {
        string = [self recipientClubs];
    } else {
        string = [[[self recipientNames] stringByReplacingOccurrencesOfString:@"["
                                                                   withString:@""] stringByReplacingOccurrencesOfString:@"]"
                  withString:@""];
    }
    [userDefaults setObject:string
                     forKey:KEY_SHARE_LOCATION_RECP_NAMES];
    [userDefaults setObject:[self recipientNumbers]
                     forKey:KEY_SHARE_LOCATION_RECP_NUMBERS];
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    if ([[self sharingType] isEqualToString:SHARE_LOCATION_TYPE_DURATION]) {
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Start Location Sharing (Time)"
                                                              action:@"Start Location Sharing (Time)"
                                                               label:@"Start Location Sharing (Time)"
                                                               value:nil] build]];
    } else if ([[self sharingType] isEqualToString:SHARE_LOCATION_TYPE_DESTINATION]) {
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Start Location Sharing (Destination)"
                                                              action:@"Start Location Sharing (Destination)"
                                                               label:@"Start Location Sharing (Destination)"
                                                               value:nil] build]];
    }
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
            if ([endPoint isEqualToString:ENDPOINT_FETCH_CLUBS]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                if (response && [response caseInsensitiveCompare:@"No Users of your Club"] == NSOrderedSame) {
                    [self setHasClubs:NO];
                } else {
                    NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                    NSError *error = nil;
                    NSArray *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                          options:NSJSONReadingMutableContainers
                                                                            error:&error];
                    if (!error) {
                        [self setHasClubs:YES];
                        
                        NSMutableArray *mutableMyClubs = [NSMutableArray array];
                        NSMutableArray *mutableMemberOfClubs = [NSMutableArray array];
                        
                        for (int i = 0; i < [parsedJson count]; i++) {
                            if ([[[parsedJson objectAtIndex:i] objectForKey:@"IsPoolOwner"] isEqualToString:@"1"]) {
                                [mutableMyClubs addObject:[parsedJson objectAtIndex:i]];
                            } else {
                                [mutableMemberOfClubs addObject:[parsedJson objectAtIndex:i]];
                            }
                        }
                        
                        [self setArrayMyClubs:[mutableMyClubs copy]];
                        [self setArrayMemberOfClubs:[mutableMemberOfClubs copy]];
                    } else {
                        [self setHasClubs:NO];
                        [Logger logError:[self TAG]
                                 message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                        [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                    }
                }
                
            }
        }
    });
}

@end
