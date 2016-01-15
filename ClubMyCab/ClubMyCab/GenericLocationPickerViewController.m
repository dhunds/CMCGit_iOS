//
//  GenericLocationPickerViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 13/11/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import "GenericLocationPickerViewController.h"
#import "Logger.h"
#import <GoogleMaps/GoogleMaps.h>
#import "ActivityIndicatorView.h"
#import "ToastLabel.h"
#import "GlobalMethods.h"

//@import GoogleMaps;

@interface GenericLocationPickerViewController () <CLLocationManagerDelegate, GMSMapViewDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *labelLocationAddress;

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) AddressModel *addressModel;

@end

@implementation GenericLocationPickerViewController

- (NSString *)TAG {
    return @"GenericLocationPickerViewController";
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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self checkLocationPermission];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBAction methods

- (IBAction)cancelPressed:(UIButton *)sender {
    [self popVC];
}

- (IBAction)donePressed:(UIButton *)sender {
    if ([self addressModel]) {
        [[self delegateGenericLocationPickerVC] addressModelFromSender:self
                                                               address:[self addressModel]
                                                          forSegueType:[self segueType]];
        
        [self popVC];
    } else {
        [self makeToastWithMessage:@"Could not locate the address, please try using the map or a different address"];
    }
}

#pragma mark - Private methods

- (void)checkLocationPermission {
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" checkLocationPermission : %d", status]];
    
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
        [self startLocationUpdates];
    } else {
        [self getLocationPermission];
    }
}

- (void)getLocationPermission {
    [[self locationManager] requestWhenInUseAuthorization];
}

- (void)showLocationPermissionAlert {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Location services off"
                                                        message:@"iShareRyde needs access to your location to function properly. Please provide access in Settings"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Cancel", @"Settings", nil];
    [alertView show];
}

- (void)startLocationUpdates {
    
    [self showActivityIndicatorView];
    
    [[self mapView] setDelegate:self];
    [[self mapView] setMyLocationEnabled:YES];
    [[[self mapView] settings] setMyLocationButton:YES];
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" startLocationUpdates : %@", [[[self mapView] myLocation] description]]];
    
    [[self locationManager] setDistanceFilter:kCLDistanceFilterNone];
    [[self locationManager] setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
    
    [[self locationManager] requestLocation];
}

- (void)reverseGeocodeLocation:(CLLocation *)loc {
    
    GMSGeocoder *geoCoder = [[GMSGeocoder alloc] init];
    [geoCoder reverseGeocodeCoordinate:[loc coordinate]
                     completionHandler:^(GMSReverseGeocodeResponse *response, NSError *error) {
                         if (!error) {
                             [Logger logDebug:[self TAG]
                                      message:[NSString stringWithFormat:@" reverseGeocodeCoordinate : %@", [[response results] description]]];
                             
                             NSString *address = @"";
                             NSArray *addressObject = [(GMSAddress *)[[response results] firstObject] lines];
                             for (int i = 0; i < [addressObject count]; i++) {
                                 address = [address stringByAppendingString:[NSString stringWithFormat:@"%@%@ ", [addressObject objectAtIndex:i], @","]];
                             }
                             address = [address substringToIndex:([address length] - 2)];
                             
                             [[self labelLocationAddress] setText:address];
                             
                             GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
                             
                             AddressModel *model = [[AddressModel alloc] init];
                             [model setLocation:loc];
                             [model setLongName:address];
                             [model setShortName:[globalMethods getShortNameForGMSAddress:(GMSAddress *)[[response results] firstObject]]];
//                             [model setShortName:[self getShortNameForGMSAddress:(GMSAddress *)[[response results] firstObject]]];
                             
                             [self setAddressModel:model];
                         } else {
                             [Logger logError:[self TAG]
                                      message:[NSString stringWithFormat:@" reverseGeocodeCoordinate error : %@", [error localizedDescription]]];
                             [self makeToastWithMessage:@"Could not locate the address, please try using the map or a different address"];
                             
                             [self setAddressModel:nil];
                         }
                     }];
}

- (void)popVC {
    [[self navigationController] popViewControllerAnimated:NO];
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

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:@"Cancel"]) {
        [self popVC];
    } else if ([buttonTitle isEqualToString:@"Settings"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

#pragma mark - CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" didChangeAuthorizationStatus : %d", status]];
    
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
        [self startLocationUpdates];
    } else if (status == kCLAuthorizationStatusDenied) {
        [self showLocationPermissionAlert];
    }
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations {
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" locationManager didUpdateLocations : %@", [locations description]]];
    
    CLLocation *currentLocation = [locations lastObject];
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:[currentLocation coordinate].latitude
                                                            longitude:[currentLocation coordinate].longitude
                                                                 zoom:14];
    [[self mapView] animateToCameraPosition:camera];
    
//    GMSMarker *marker = [ [GMSMarker alloc] init];
//    marker.position = [currentLocation coordinate];
//    marker.title = @"Sydney";
//    marker.snippet = @"Australia";
//    marker.map = self.mapView;
    
    [self reverseGeocodeLocation:currentLocation];
    
    [self hideActivityIndicatorView];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    [self hideActivityIndicatorView];
    [self makeToastWithMessage:@"Your location could not be determined, please try again"];
    [Logger logError:[self TAG]
             message:[NSString stringWithFormat:@" locationManager didFailWithError : %@", [error localizedDescription]]];
}

#pragma mark - GMSMapViewDelegate methods

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position {
    [self reverseGeocodeLocation:[[CLLocation alloc] initWithLatitude:[position target].latitude
                                                            longitude:[position target].longitude]];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
