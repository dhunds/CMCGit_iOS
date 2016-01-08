//
//  BookACabViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 08/12/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import "BookACabViewController.h"
#import "GlobalMethods.h"
#import "Logger.h"
#import "ActivityIndicatorView.h"
#import "ToastLabel.h"
#import "BookACabTableViewCell.h"
#import "CabsWebViewController.h"
#import "MyRidesViewController.h"
#import "HCSStarRatingView.h"

@interface BookACabViewController () <UIAlertViewDelegate, GlobalMethodsAsyncRequestProtocol, CabsWebViewControllerProtocol>

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) NSString *fromLocality, *toLocality, *estTime, *estDistance;

@property (strong, nonatomic) NSArray *arrayCabDetails;

@property (weak, nonatomic) IBOutlet UITableView *tableViewCabDetails;

@property (strong, nonatomic) UIAlertView *alertViewBookUber, *alertViewBookOla, *alertViewBookTFS;

@property (strong, nonatomic) NSString *uberBookingParams, *requestIDInTable, *cabTypeUberOla;

@property (nonatomic) NSUInteger indexForBookingCab;

@end

@implementation BookACabViewController

- (NSString *)TAG {
    return @"BookACabViewController";
}

#pragma mark - View Controller Life Cycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    [Logger logDebug:[self TAG]
//             message:[NSString stringWithFormat:@" viewDidLoad addressModelFrom : %@ addressModelTo : %@", [[[self addressModelFrom] location] description], [[[self addressModelTo] location] description]]];
    
//    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//    
//    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
//    
//    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
//                                                       endPoint:ENDPOINT_FETCH_UNREAD_NOTIFICATIONS_COUNT
//                                                     parameters:[NSString stringWithFormat:@"MobileNumber=%@", [userDefaults objectForKey:KEY_USER_DEFAULT_MOBILE]]
//                                            delegateForProtocol:self];
    
    [self fetchLocality];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
    
    if ([[segue identifier] isEqualToString:@"CabsWebSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[CabsWebViewController class]]) {
            NSString *requestIDAndType = sender;
            NSArray *array = [requestIDAndType componentsSeparatedByString:@"_"];
            if ([[array firstObject] isEqualToString:UBER_REQUEST_ID]) {
                [(CabsWebViewController *)[segue destinationViewController] setCabType:UBER_REQUEST_ID];
                [(CabsWebViewController *)[segue destinationViewController] setUberRequestID:[array lastObject]];
                [(CabsWebViewController *)[segue destinationViewController] setUberURL:[NSString stringWithFormat:@"%@/uberapi.php?type=oauth", SERVER_ADDRESS]];
                [(CabsWebViewController *)[segue destinationViewController] setDelegateCabsWebViewControllerProtocol:self];
            } else if ([[array firstObject] isEqualToString:OLA_REQUEST_ID]) {
                [(CabsWebViewController *)[segue destinationViewController] setCabType:OLA_REQUEST_ID];
                [(CabsWebViewController *)[segue destinationViewController] setOlaRequestID:[array lastObject]];
                [(CabsWebViewController *)[segue destinationViewController] setOlaURL:[NSString stringWithFormat:@"%@/olaApi.php?type=oauth", SERVER_ADDRESS]];
                [(CabsWebViewController *)[segue destinationViewController] setDelegateCabsWebViewControllerProtocol:self];
            }
        }
    } else if ([[segue identifier] isEqualToString:@"BookCabRidesSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[MyRidesViewController class]]) {
            
        }
    }
}

#pragma mark - CabsWebViewControllerProtocol methods

- (void)bookingProcessCompletedForCabType:(NSString *)cabType
                            withRequestID:(NSString *)reqID
                           andOptionalURL:(NSString *)url {
    if ([cabType isEqualToString:UBER_REQUEST_ID]) {
        
        [self setRequestIDInTable:reqID];
        
        GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
        [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                           endPoint:ENDPOINT_CAB_BOOK_REQUEST_STATUS_UBER
                                                         parameters:[NSString stringWithFormat:@"requestid=%@", reqID]
                                                delegateForProtocol:self];
    } else if ([cabType isEqualToString:OLA_REQUEST_ID]) {
        
        [self setRequestIDInTable:reqID];
        
        [self showActivityIndicatorView];
        
        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
        [urlRequest setHTTPMethod:@"POST"];
        [urlRequest setURL:[NSURL URLWithString:url]];
        
        [Logger logDebug:[self TAG]
                 message:[NSString stringWithFormat:@" bookingProcessCompletedFor Ola url : %@", url]];
        
        [NSURLConnection sendAsynchronousRequest:urlRequest
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                   
                                   [self hideActivityIndicatorView];
                                   
                                   if (!connectionError && data) {
                                       NSString *resp = [[NSString alloc] initWithData:data
                                                                              encoding:NSUTF8StringEncoding];
                                       //
                                       //                                   [Logger logDebug:[self TAG]
                                       //                                            message:[NSString stringWithFormat:@" bookingProcessCompletedFor Ola response : %@", resp]];
                                       
                                       NSError *error = nil;
                                       NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:data
                                                                                                  options:NSJSONReadingMutableContainers
                                                                                                    error:&error];
                                       if (!error) {
                                           if ([resp rangeOfString:@"crn"].location != NSNotFound) {
                                               
                                               NSDictionary *dictionary = [[self arrayCabDetails] objectAtIndex:[self indexForBookingCab]];
                                               if ([self dictionaryBookCabFromRide]) {
                                                   [self updateCMCRecords:[NSString stringWithFormat:@"%@~%@", [dictionary objectForKey:@"CabNameID"], [self requestIDInTable]]
                                                                  cabType:[dictionary objectForKey:@"CarType"]
                                                                   modeID:@"1"
                                                             bookingRefNo:[parsedJson objectForKey:@"crn"]
                                                                 distance:[[self dictionaryBookCabFromRide] objectForKey:@"Distance"]
                                                             tripDuration:[[self dictionaryBookCabFromRide] objectForKey:@"ExpTripDuration"]
                                                                    cabID:[[self dictionaryBookCabFromRide] objectForKey:@"CabId"]
                                                               driverName:[parsedJson objectForKey:@"driver_name"]
                                                             driverNumber:[parsedJson objectForKey:@"driver_number"]
                                                                carNumber:[parsedJson objectForKey:@"cab_number"]
                                                                  siteURL:@""
                                                                  appLink:@""
                                                            shouldOpenURL:NO
                                                      shouldOpenRidesPage:NO];
                                               } else {
                                                   [self updateCMCRecords:[NSString stringWithFormat:@"%@~%@", [dictionary objectForKey:@"CabNameID"], [self requestIDInTable]]
                                                                  cabType:[dictionary objectForKey:@"CarType"]
                                                                   modeID:@"1"
                                                             bookingRefNo:[parsedJson objectForKey:@"crn"]
                                                                 distance:@""
                                                             tripDuration:@""
                                                                    cabID:@""
                                                               driverName:[parsedJson objectForKey:@"driver_name"]
                                                             driverNumber:[parsedJson objectForKey:@"driver_number"]
                                                                carNumber:[parsedJson objectForKey:@"cab_number"]
                                                                  siteURL:@""
                                                                  appLink:@""
                                                            shouldOpenURL:NO
                                                      shouldOpenRidesPage:NO];
                                               }
                                               
                                               UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                                                   message:[NSString stringWithFormat:@"Cab booked succesfully!\r\nDriver : %@ (%@)\r\nVehicle : %@ (%@)\r\nEst. Time : %@ mins", [parsedJson objectForKey:@"driver_name"], [parsedJson objectForKey:@"driver_number"], [parsedJson objectForKey:@"car_model"], [parsedJson objectForKey:@"cab_number"], [parsedJson objectForKey:@"eta"]]
                                                                                                  delegate:self
                                                                                         cancelButtonTitle:nil
                                                                                         otherButtonTitles:@"Ok", nil];
                                               [alertView show];
                                           } else {
                                               UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[parsedJson objectForKey:@"message"]
                                                                                                   message:[NSString stringWithFormat:@"Cab could not be booked because : %@", [parsedJson objectForKey:@"code"]]
                                                                                                  delegate:self
                                                                                         cancelButtonTitle:nil
                                                                                         otherButtonTitles:@"Ok", nil];
                                               [alertView show];
                                           }
                                           
                                       } else {
                                           [Logger logError:[self TAG]
                                                    message:[NSString stringWithFormat:@" bookingProcessCompletedFor Ola parsing error : %@", [error localizedDescription]]];
                                       }
                                   } else {
                                       [Logger logError:[self TAG]
                                                message:[NSString stringWithFormat:@" bookingProcessCompletedFor Ola error : %@", [connectionError localizedDescription]]];
                                   }
                               }];
    }
}

#pragma mark - IBAction methods

- (IBAction)notificationsBarButtonItemPressed {
    
    [self performSegueWithIdentifier:@"NotificationsBookCabSegue"
                              sender:self];
}

- (IBAction)sortByTime:(id)sender {
    [self sortByTimeArray:[self arrayCabDetails]];
}

- (IBAction)sortByPrice:(id)sender {
    [self sortByPriceArray:[self arrayCabDetails]];
}

- (void)sortByTimeArray:(NSArray *)arrayToSort {
    
    //    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeEstimate"
    //                                                                   ascending:YES];
    //    NSArray *descriptors = [NSArray arrayWithObject:sortDescriptor];
    //    NSArray *arraySorted = [arrayToSort sortedArrayUsingDescriptors:descriptors];
    
    NSArray *arraySorted = [arrayToSort sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *dict1, NSDictionary *dict2) {
        NSNumber *est1 = [NSNumber numberWithInteger:[[dict1 objectForKey:@"timeEstimate"] integerValue]];
        NSNumber *est2 = [NSNumber numberWithInteger:[[dict2 objectForKey:@"timeEstimate"] integerValue]];
        
        return [est1 compare:est2];
    }];
    
    //    [Logger logDebug:[self TAG]
    //             message:[NSString stringWithFormat:@" sortByTime : %@", [arraySorted description]]];
    
    [self setArrayCabDetails:arraySorted];
    [[self tableViewCabDetails] reloadData];
    
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"sort_icon_rupee.png"]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(sortByPrice:)];
    [barButton setImageInsets:UIEdgeInsetsMake(3.0, 0.0, 0.0, 0.0)];
    
    NSMutableArray *barButtonItems = [[[self navigationItem] rightBarButtonItems] mutableCopy];
    if ([barButtonItems count] > 1) {
        [barButtonItems removeObject:[barButtonItems lastObject]];
    }
    [barButtonItems addObject:barButton];
    [[self navigationItem] setRightBarButtonItems:[barButtonItems copy]];
}

- (void)sortByPriceArray:(NSArray *)arrayToSort {
    
    NSArray *arraySorted = [arrayToSort sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *dict1, NSDictionary *dict2) {
        NSNumber *est1 = [NSNumber numberWithInteger:[[dict1 objectForKey:@"low_estimate"] integerValue]];
        NSNumber *est2 = [NSNumber numberWithInteger:[[dict2 objectForKey:@"low_estimate"] integerValue]];
        
        return [est1 compare:est2];
    }];
    
    //    [Logger logDebug:[self TAG]
    //             message:[NSString stringWithFormat:@" sortByPrice : %@", [arraySorted description]]];
    
    [self setArrayCabDetails:arraySorted];
    [[self tableViewCabDetails] reloadData];
    
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"sort_icon_time.png"]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(sortByTime:)];
    [barButton setImageInsets:UIEdgeInsetsMake(3.0, 0.0, 0.0, 0.0)];
    
    NSMutableArray *barButtonItems = [[[self navigationItem] rightBarButtonItems] mutableCopy];
    if ([barButtonItems count] > 1) {
        [barButtonItems removeObject:[barButtonItems lastObject]];
    }
    [barButtonItems addObject:barButton];
    [[self navigationItem] setRightBarButtonItems:[barButtonItems copy]];
}

- (IBAction)bookNowPressed:(id)sender {
    
    NSString *cabName = [[[self arrayCabDetails] objectAtIndex:[sender tag]] objectForKey:@"CabName"];
    if (cabName && [cabName length] > 0) {
        
        if ([cabName caseInsensitiveCompare:@"Ola"] == NSOrderedSame) {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                message:@"Please provide us with your Ola account information on the next page"
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"Ok", nil];
            [alertView setTag:[sender tag]];
            [self setAlertViewBookOla:alertView];
            
            [alertView show];
        } else if ([cabName caseInsensitiveCompare:@"Uber"] == NSOrderedSame) {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                message:@"Please provide us with your Uber account information on the next page, you need to do this only once"
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"Ok", nil];
            [alertView setTag:[sender tag]];
            [self setAlertViewBookUber:alertView];
            
            [alertView show];
        } else if ([cabName caseInsensitiveCompare:@"TaxiForSure"] == NSOrderedSame) {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login"
                                                                message:@"Please enter your TaxiForSure Username/Password"
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"Cancel", @"Book Now", nil];
            [alertView setTag:[sender tag]];
            [alertView setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
            [self setAlertViewBookTFS:alertView];
            
            [alertView show];
        } else if ([cabName caseInsensitiveCompare:@"Mega"] == NSOrderedSame) {
            
            [self setIndexForBookingCab:[sender tag]];
            [self bookMegaCab];
        } else {
            
            NSDictionary *dictionary = [[self arrayCabDetails] objectAtIndex:[sender tag]];
            NSString *mSiteURL = [NSString stringWithFormat:@"http://%@", [dictionary objectForKey:@"CabMobileSite"]];
            
            [self updateCMCRecords:[dictionary objectForKey:@"CabNameID"]
                           cabType:[dictionary objectForKey:@"CarType"]
                            modeID:@"2"
                      bookingRefNo:@""
                          distance:@""
                      tripDuration:@""
                             cabID:@""
                        driverName:@""
                      driverNumber:@""
                         carNumber:@""
                           siteURL:mSiteURL
                           appLink:[dictionary objectForKey:@"CabPackageName"]
                     shouldOpenURL:YES
               shouldOpenRidesPage:NO];
        }
        
    }
    
}

#pragma mark - Private methods

- (void)bookUberCab:(NSUInteger)index {
    
    [self showActivityIndicatorView];
    
    [self setCabTypeUberOla:UBER_REQUEST_ID];
    
    NSDictionary *dictionary = [[self arrayCabDetails] objectAtIndex:index];
    [self setIndexForBookingCab:index];
    
    [self setUberBookingParams:[NSString stringWithFormat:@"cabType=%@&productid=%@&lat=%f&lon=%f&elat=%f&elon=%f&cabID=", [dictionary objectForKey:@"CabName"], [dictionary objectForKey:@"productId"], [[[self addressModelFrom] location] coordinate].latitude, [[[self addressModelFrom] location] coordinate].longitude, [[[self addressModelTo] location] coordinate].latitude, [[[self addressModelTo] location] coordinate].longitude]];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_CAB_BOOK_REQUEST_UBER
                                                     parameters:[self uberBookingParams]
                                            delegateForProtocol:self];
}

- (void)bookOlaCab:(NSUInteger)index {
    
    [self showActivityIndicatorView];
    
    [self setCabTypeUberOla:OLA_REQUEST_ID];
    
    NSDictionary *dictionary = [[self arrayCabDetails] objectAtIndex:index];
    [self setIndexForBookingCab:index];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_CAB_BOOK_REQUEST_UBER
                                                     parameters:[NSString stringWithFormat:@"cabType=%@&productid=%@&lat=%f&lon=%f&elat=%f&elon=%f&cabID=", [dictionary objectForKey:@"CabName"], [dictionary objectForKey:@"CarType"], [[[self addressModelFrom] location] coordinate].latitude, [[[self addressModelFrom] location] coordinate].longitude, [[[self addressModelTo] location] coordinate].latitude, [[[self addressModelTo] location] coordinate].longitude]
                                            delegateForProtocol:self];
}

- (void)bookTFSCab:(NSUInteger)index
          userName:(NSString *)user
          password:(NSString *)pass {
    
    [self showActivityIndicatorView];
    
    NSDictionary *dictionary = [[self arrayCabDetails] objectAtIndex:index];
    [self setIndexForBookingCab:index];
    
    NSDate *date = [NSDate date];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd/MM/yyyy"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    
    [dateFormatter setDateFormat:@"HH:mm"];
    NSString *timeString = [dateFormatter stringFromDate:date];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_TAXI_FOR_SURE_API
                                                     parameters:[NSString stringWithFormat:@"type=booking&username=%@&password=%@&car_type=%@&source=app&pickup_time=%@&pickup_date=%@&city=%@&pickup_area=%@&landmark=%@&pickup_latitude=%f&pickup_longitude=%f&eta_from_app=%1.0f", user, pass, [dictionary objectForKey:@"carType"], timeString, dateString, [self fromLocality], [[self addressModelFrom] longName], [[self addressModelFrom] longName], [[[self addressModelFrom] location] coordinate].latitude, [[[self addressModelFrom] location] coordinate].longitude, ceilf([[dictionary objectForKey:@"timeEstimate"] doubleValue] / 60.0f)]
                                            delegateForProtocol:self];
}

- (void)bookMegaCab {
    
    [self showActivityIndicatorView];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_MEGA_API
                                                     parameters:[NSString stringWithFormat:@"type=CreateBooking&mobile=%@&slat=%f&slon=%f&elat=%f&elon=%f&stime=", [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_MOBILE], [[[self addressModelFrom] location] coordinate].latitude, [[[self addressModelFrom] location] coordinate].longitude, [[[self addressModelTo] location] coordinate].latitude, [[[self addressModelTo] location] coordinate].longitude]
                                            delegateForProtocol:self];
}

- (void)updateCMCRecords:(NSString *)cabName
                 cabType:(NSString *)cabType
                  modeID:(NSString *)modeID
            bookingRefNo:(NSString *)bookingRef
                distance:(NSString *)distance
            tripDuration:(NSString *)duration
                   cabID:(NSString *)cabid
              driverName:(NSString *)name
            driverNumber:(NSString *)number
               carNumber:(NSString *)carno
                 siteURL:(NSString *)url
                 appLink:(NSString *)appLink
           shouldOpenURL:(BOOL)openUrl
     shouldOpenRidesPage:(BOOL)openRides {
    
//    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
//    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
//                                                       endPoint:ENDPOINT_CMC_RECORDS
//                                                     parameters:[NSString stringWithFormat:@"CabNameID=%@&CabType=%@&ModeID=%@&FromLat=%@&ToLat=%@&MobileNumber=%@&CabUserName=%@&BookingRefNo=%@&FromLocation=%@&ToLocation=%@&FromShortName=%@&ToShortName=%@&TravelDate=%@&TravelTime=%@&Distance=%@&ExpTripDuration=%@&CabId=%@&DriverName=%@&DriverNumber=%@&CarNumber=%@&CarType="]
//                                            delegateForProtocol:self];
    
    NSString *from = [NSString stringWithFormat:@"%f,%f", [[[self addressModelFrom] location] coordinate].latitude, [[[self addressModelFrom] location] coordinate].longitude];
    NSString *to = [NSString stringWithFormat:@"%f,%f", [[[self addressModelTo] location] coordinate].latitude, [[[self addressModelTo] location] coordinate].longitude];
    
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd/MM/yyyy"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    
    [dateFormatter setDateFormat:@"hh:mm aa"];
    NSString *timeString = [dateFormatter stringFromDate:date];
    
    NSString *params = [NSString stringWithFormat:@"CabNameID=%@&CabType=%@&ModeID=%@&FromLat=%@&ToLat=%@&MobileNumber=%@&CabUserName=%@&BookingRefNo=%@&FromLocation=%@&ToLocation=%@&FromShortName=%@&ToShortName=%@&TravelDate=%@&TravelTime=%@&Distance=%@&ExpTripDuration=%@&CabId=%@&DriverName=%@&DriverNumber=%@&CarNumber=%@&CarType=", cabName, cabType, modeID, from, to, [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_MOBILE], @"", bookingRef, [[self addressModelFrom] longName], [[self addressModelTo] longName], [[self addressModelFrom] shortName], [[self addressModelTo] shortName], dateString, timeString, distance, duration, cabid, name, number, carno];
    
    NSString *query = [NSString stringWithFormat:@"%@%@?%@", SERVER_ADDRESS, ENDPOINT_CMC_RECORDS, params];
    query = [query stringByReplacingOccurrencesOfString:@" "
                                             withString:@"%20"];
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setURL:[NSURL URLWithString:query]];
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" updateCMCRecords url : %@", query]];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               [self hideActivityIndicatorView];
                               
                               if (!connectionError && data) {
                                   NSString *resp = [[NSString alloc] initWithData:data
                                                                          encoding:NSUTF8StringEncoding];
                                   
                                   [Logger logDebug:[self TAG]
                                            message:[NSString stringWithFormat:@" updateCMCRecords response : %@", resp]];
                                   
                                   if (openUrl) {
                                       [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
                                   }
                                   
                                   if (openRides) {
                                       [self performSegueWithIdentifier:@"BookCabRidesSegue"
                                                                 sender:self];
                                   }
                               } else {
                                   [Logger logError:[self TAG]
                                            message:[NSString stringWithFormat:@" updateCMCRecords error : %@", [connectionError localizedDescription]]];
                                   [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                               }
                           }];
}

- (void)fetchLocality {
    
    [self showActivityIndicatorView];
    
    GMSGeocoder *geoCoder = [[GMSGeocoder alloc] init];
    [geoCoder reverseGeocodeCoordinate:[[[self addressModelFrom] location] coordinate]
                     completionHandler:^(GMSReverseGeocodeResponse *response, NSError *error) {
                         if (!error) {
                             [Logger logDebug:[self TAG]
                                      message:[NSString stringWithFormat:@" reverseGeocodeCoordinate addressModelFrom : %@", [[response results] description]]];
                             
                             [self setFromLocality:[(GMSAddress *)[[response results] firstObject] locality]];
                             
                             GMSGeocoder *geoCoderTo = [[GMSGeocoder alloc] init];
                             [geoCoderTo reverseGeocodeCoordinate:[[[self addressModelTo] location] coordinate]
                                                completionHandler:^(GMSReverseGeocodeResponse *resp, NSError *err) {
                                                    if (!err) {
                                                        
                                                        [Logger logDebug:[self TAG]
                                                                 message:[NSString stringWithFormat:@" reverseGeocodeCoordinate addressModelTo : %@", [[resp results] description]]];
                                                        
                                                        [self setToLocality:[(GMSAddress *)[[resp results] firstObject] locality]];
                                                        
                                                        //                                                        [Logger logDebug:[self TAG]
                                                        //                                                                 message:[NSString stringWithFormat:@" fetchCabs from : %@ to : %@", [self fromLocality], [self toLocality]]];
                                                        
                                                        if ([self fromLocality] && [[self fromLocality] length] > 0 && [self toLocality] && [[self toLocality] length] > 0) {
                                                            [self fetchTimeAndDistance];
                                                        } else {
                                                            [self hideActivityIndicatorView];
                                                            
                                                            [Logger logError:[self TAG]
                                                                     message:[NSString stringWithFormat:@" reverseGeocodeCoordinate error : %@", [error localizedDescription]]];
                                                            [self makeToastWithMessage:@"Could not locate the address, please try using the map or a different address"];
                                                        }
                                                        
                                                    } else {
                                                        [self hideActivityIndicatorView];
                                                        
                                                        [Logger logError:[self TAG]
                                                                 message:[NSString stringWithFormat:@" reverseGeocodeCoordinate error : %@", [error localizedDescription]]];
                                                        [self makeToastWithMessage:@"Could not locate the address, please try using the map or a different address"];
                                                    }
                                                }];
                         } else {
                             [self hideActivityIndicatorView];
                             
                             [Logger logError:[self TAG]
                                      message:[NSString stringWithFormat:@" reverseGeocodeCoordinate error : %@", [error localizedDescription]]];
                             [self makeToastWithMessage:@"Could not locate the address, please try using the map or a different address"];
                         }
                     }];
    
    
    
}

- (void)fetchTimeAndDistance {
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
                                       
                                       [self setEstTime:[NSString stringWithFormat:@"%f", ([durationvalue doubleValue] / 60.0f)]];
                                       [self setEstDistance:[NSString stringWithFormat:@"%f", ([distancevalue doubleValue] / 1000.0f)]];
                                       
                                       [self fetchCabs];
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

- (void)fetchCabs {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd/MM/yyyy hh:mm:ss"];
    NSString *startDate = [dateFormatter stringFromDate:[NSDate date]];
    
    NSString *parameters = [NSString stringWithFormat:@"FromCity=%@&ToCity=%@&slat=%f&slon=%f&elat=%f&elon=%f&dist=%@&stime=%@&etime=%@", [self fromLocality], [self toLocality], [[[self addressModelFrom] location] coordinate].latitude, [[[self addressModelFrom] location] coordinate].longitude, [[[self addressModelTo] location] coordinate].latitude, [[[self addressModelTo] location] coordinate].longitude, [self estDistance], startDate, [self estTime]];
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" fetchCabs parameters : %@", parameters]];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_FETCH_CAB_DETAILS
                                                     parameters:parameters
                                            delegateForProtocol:self];
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

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    
    if (alertView == [self alertViewBookUber]) {
        if ([buttonTitle isEqualToString:@"Ok"]) {
            [self bookUberCab:[alertView tag]];
        }
    } else if (alertView == [self alertViewBookOla]) {
        if ([buttonTitle isEqualToString:@"Ok"]) {
            [self bookOlaCab:[alertView tag]];
        }
    } else if (alertView == [self alertViewBookTFS]) {
        if ([buttonTitle isEqualToString:@"Book Now"]) {
            NSString *userName = [[alertView textFieldAtIndex:0] text];
            NSString *password = [[alertView textFieldAtIndex:1] text];
            
            [Logger logDebug:[self TAG]
                     message:[NSString stringWithFormat:@" alertViewBookTFS username : %@ password : %@", userName, password]];
            
            if (userName && [userName length] <= 0) {
                [self makeToastWithMessage:@"Please enter Username"];
            } else if (password && [password length] <= 0) {
                [self makeToastWithMessage:@"Please enter password"];
            } else {
                [self bookTFSCab:[alertView tag]
                        userName:userName
                        password:password];
            }
            
        }
//        else if ([buttonTitle isEqualToString:@"Cancel"]) {
//            
//        }
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
                
                [self fetchLocality];
            } else if ([endPoint isEqualToString:ENDPOINT_FETCH_CAB_DETAILS]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                if (response && [response caseInsensitiveCompare:@"error"] == NSOrderedSame) {
                    [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                } else {
                    NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                    NSError *error = nil;
                    NSArray *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                          options:NSJSONReadingMutableContainers
                                                                            error:&error];
                    
                    if(!error) {
                        
                        //                        [Logger logDebug:[self TAG]
                        //                                 message:[NSString stringWithFormat:@" %@ parsedJson : %@", endPoint, [[parsedJson objectAtIndex:1] objectForKey:@"Message"]]];
                        
                        //TODO apply sorting before display & add sort button
                        
                        [self setArrayCabDetails:parsedJson];
                        
                        [self sortByTime:parsedJson];
                        
                    } else {
                        [Logger logError:[self TAG]
                                 message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                        [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                    }
                }
            } else if ([endPoint isEqualToString:ENDPOINT_CAB_BOOK_REQUEST_UBER]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                if (response && [response length] > 0) {
                    [self performSegueWithIdentifier:@"CabsWebSegue"
                                              sender:[NSString stringWithFormat:@"%@_%@", [self cabTypeUberOla], response]];
                }
            } else if ([endPoint isEqualToString:ENDPOINT_CAB_BOOK_REQUEST_STATUS_UBER]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                           options:NSJSONReadingMutableContainers
                                                                             error:&error];
                if (!error) {
                    //                        [Logger logDebug:[self TAG]
                    //                                 message:[NSString stringWithFormat:@" parsedJson : %@", parsedJson]];
                    
                    NSString *parameters = [NSString stringWithFormat:@"type=bookuber&%@&accesstoken=%@", [self uberBookingParams], [parsedJson objectForKey:@"access_token"]];
                    
                    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
                    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                                       endPoint:ENDPOINT_UBER_CONNECT
                                                                     parameters:parameters
                                                            delegateForProtocol:self];
                    
                } else {
                    [Logger logError:[self TAG]
                             message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                    [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                }
            } else if ([endPoint isEqualToString:ENDPOINT_UBER_CONNECT]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                           options:NSJSONReadingMutableContainers
                                                                             error:&error];
                if (!error) {
                    //                        [Logger logDebug:[self TAG]
                    //                                 message:[NSString stringWithFormat:@" parsedJson : %@", parsedJson]];
                    
                    if ([response.lowercaseString rangeOfString:@"error"].location == NSNotFound) {
                        if ([[parsedJson objectForKey:@"status"] caseInsensitiveCompare:@"accepted"] == NSOrderedSame) {
                            
                            NSDictionary *dictionaryCab = [[self arrayCabDetails] objectAtIndex:[self indexForBookingCab]];
                            if ([self dictionaryBookCabFromRide]) {
                                [self updateCMCRecords:[dictionaryCab objectForKey:@"CabNameID"]
                                               cabType:[dictionaryCab objectForKey:@"CarType"]
                                                modeID:@"1"
                                          bookingRefNo:[parsedJson objectForKey:@"request_id"]
                                              distance:[[self dictionaryBookCabFromRide] objectForKey:@"Distance"]
                                          tripDuration:[[self dictionaryBookCabFromRide] objectForKey:@"ExpTripDuration"]
                                                 cabID:[[self dictionaryBookCabFromRide] objectForKey:@"CabId"]
                                            driverName:[[parsedJson objectForKey:@"driver"] objectForKey:@"name"]
                                          driverNumber:[[parsedJson objectForKey:@"driver"] objectForKey:@"phone_number"]
                                             carNumber:[[parsedJson objectForKey:@"vehicle"] objectForKey:@"license_plate"]
                                               siteURL:@""
                                               appLink:@""
                                         shouldOpenURL:NO
                                   shouldOpenRidesPage:NO];
                            } else {
                                [self updateCMCRecords:[dictionaryCab objectForKey:@"CabNameID"]
                                               cabType:[dictionaryCab objectForKey:@"CarType"]
                                                modeID:@"1"
                                          bookingRefNo:[parsedJson objectForKey:@"request_id"]
                                              distance:@""
                                          tripDuration:@""
                                                 cabID:@""
                                            driverName:[[parsedJson objectForKey:@"driver"] objectForKey:@"name"]
                                          driverNumber:[[parsedJson objectForKey:@"driver"] objectForKey:@"phone_number"]
                                             carNumber:[[parsedJson objectForKey:@"vehicle"] objectForKey:@"license_plate"]
                                               siteURL:@""
                                               appLink:@""
                                         shouldOpenURL:NO
                                   shouldOpenRidesPage:NO];
                            }
                            
                            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                                message:[NSString stringWithFormat:@"Cab booked succesfully!\r\nDriver : %@ (%@)\r\nVehicle : %@ (%@)\r\nEst. Time : %@ mins", [[parsedJson objectForKey:@"driver"] objectForKey:@"name"], [[parsedJson objectForKey:@"driver"] objectForKey:@"phone_number"], [[parsedJson objectForKey:@"vehicle"] objectForKey:@"make"], [[parsedJson objectForKey:@"vehicle"] objectForKey:@"license_plate"], [parsedJson objectForKey:@"eta"]]
                                                                               delegate:self
                                                                      cancelButtonTitle:nil
                                                                      otherButtonTitles:@"Ok", nil];
                            [alertView show];
                        } else {
                            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cab could not be booked"
                                                                                message:[parsedJson objectForKey:@"status"]
                                                                               delegate:self
                                                                      cancelButtonTitle:nil
                                                                      otherButtonTitles:@"Ok", nil];
                            [alertView show];
                        }
                    } else {
                        NSDictionary *dictionary = [[parsedJson objectForKey:@"errors"] firstObject];
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[dictionary objectForKey:@"code"]
                                                                            message:[dictionary objectForKey:@"title"]
                                                                           delegate:self
                                                                  cancelButtonTitle:nil
                                                                  otherButtonTitles:@"Ok", nil];
                        [alertView show];
                    }
                    
                } else {
                    [Logger logError:[self TAG]
                             message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                    [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                }
            } else if ([endPoint isEqualToString:ENDPOINT_TAXI_FOR_SURE_API]) {
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
                        
                        NSDictionary *dictionary = [parsedJson objectForKey:@"response_data"];
                        
                        NSDictionary *dictionaryCab = [[self arrayCabDetails] objectAtIndex:[self indexForBookingCab]];
                        if ([self dictionaryBookCabFromRide]) {
                            [self updateCMCRecords:[dictionaryCab objectForKey:@"CabNameID"]
                                           cabType:[dictionaryCab objectForKey:@"CarType"]
                                            modeID:@"1"
                                      bookingRefNo:[dictionary objectForKey:@"booking_id"]
                                          distance:[[self dictionaryBookCabFromRide] objectForKey:@"Distance"]
                                      tripDuration:[[self dictionaryBookCabFromRide] objectForKey:@"ExpTripDuration"]
                                             cabID:[[self dictionaryBookCabFromRide] objectForKey:@"CabId"]
                                        driverName:[dictionary objectForKey:@"driver_name"]
                                      driverNumber:[dictionary objectForKey:@"driver_number"]
                                         carNumber:[dictionary objectForKey:@"vehicle_number"]
                                           siteURL:@""
                                           appLink:@""
                                     shouldOpenURL:NO
                               shouldOpenRidesPage:NO];
                        } else {
                            [self updateCMCRecords:[dictionaryCab objectForKey:@"CabNameID"]
                                           cabType:[dictionaryCab objectForKey:@"CarType"]
                                            modeID:@"1"
                                      bookingRefNo:[dictionary objectForKey:@"booking_id"]
                                          distance:@""
                                      tripDuration:@""
                                             cabID:@""
                                        driverName:[dictionary objectForKey:@"driver_name"]
                                      driverNumber:[dictionary objectForKey:@"driver_number"]
                                         carNumber:[dictionary objectForKey:@"vehicle_number"]
                                           siteURL:@""
                                           appLink:@""
                                     shouldOpenURL:NO
                               shouldOpenRidesPage:NO];
                        }
                        
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                            message:[NSString stringWithFormat:@"Cab booked succesfully!\r\nDriver : %@ (%@)\r\nVehicle : %@", [dictionary objectForKey:@"driver_name"], [dictionary objectForKey:@"driver_number"], [dictionary objectForKey:@"vehicle_number"]]
                                                                           delegate:self
                                                                  cancelButtonTitle:nil
                                                                  otherButtonTitles:@"Ok", nil];
                        [alertView show];
                    } else {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cab could not be booked"
                                                                            message:[parsedJson objectForKey:@"error_desc"]
                                                                           delegate:self
                                                                  cancelButtonTitle:nil
                                                                  otherButtonTitles:@"Ok", nil];
                        [alertView show];
                    }
                    
                } else {
                    [Logger logError:[self TAG]
                             message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                    [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                }
            } else if ([endPoint isEqualToString:ENDPOINT_MEGA_API]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                           options:NSJSONReadingMutableContainers
                                                                             error:&error];
                if (!error) {
                    [Logger logDebug:[self TAG]
                             message:[NSString stringWithFormat:@" parsedJson : %@ Jobno : %@", parsedJson, [parsedJson objectForKey:@"Jobno"]]];
                    
                    if ([[parsedJson objectForKey:@"status"] caseInsensitiveCompare:@"SUCCESS"] == NSOrderedSame) {
                        
                        NSDictionary *dictionary = [parsedJson objectForKey:@"data"];
                        
                        NSDictionary *dictionaryCab = [[self arrayCabDetails] objectAtIndex:[self indexForBookingCab]];
                        if ([self dictionaryBookCabFromRide]) {
                            [self updateCMCRecords:[dictionaryCab objectForKey:@"CabNameID"]
                                           cabType:[dictionaryCab objectForKey:@"CarType"]
                                            modeID:@"1"
                                      bookingRefNo:[parsedJson objectForKey:@"Jobno"]
                                          distance:[[self dictionaryBookCabFromRide] objectForKey:@"Distance"]
                                      tripDuration:[[self dictionaryBookCabFromRide] objectForKey:@"ExpTripDuration"]
                                             cabID:[[self dictionaryBookCabFromRide] objectForKey:@"CabId"]
                                        driverName:[dictionary objectForKey:@"DriverName"]
                                      driverNumber:[dictionary objectForKey:@"DriverNumber"]
                                         carNumber:[dictionary objectForKey:@"VehicleNo"]
                                           siteURL:@""
                                           appLink:@""
                                     shouldOpenURL:NO
                               shouldOpenRidesPage:NO];
                        } else {
                            [self updateCMCRecords:[dictionaryCab objectForKey:@"CabNameID"]
                                           cabType:[dictionaryCab objectForKey:@"CarType"]
                                            modeID:@"1"
                                      bookingRefNo:[parsedJson objectForKey:@"Jobno"]
                                          distance:@""
                                      tripDuration:@""
                                             cabID:@""
                                        driverName:[dictionary objectForKey:@"DriverName"]
                                      driverNumber:[dictionary objectForKey:@"DriverNumber"]
                                         carNumber:[dictionary objectForKey:@"VehicleNo"]
                                           siteURL:@""
                                           appLink:@""
                                     shouldOpenURL:NO
                               shouldOpenRidesPage:NO];
                        }
                        
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                            message:[NSString stringWithFormat:@"Cab booked succesfully!\r\nDriver : %@ (%@)\r\nVehicle : %@", [dictionary objectForKey:@"DriverName"], [dictionary objectForKey:@"DriverNumber"], [dictionary objectForKey:@"VehicleNo"]]
                                                                           delegate:self
                                                                  cancelButtonTitle:nil
                                                                  otherButtonTitles:@"Ok", nil];
                        [alertView show];
                    } else {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cab could not be booked"
                                                                            message:[parsedJson objectForKey:@"data"]
                                                                           delegate:self
                                                                  cancelButtonTitle:nil
                                                                  otherButtonTitles:@"Ok", nil];
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

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self arrayCabDetails] count];
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
    CGRect frameTableView = [tableView frame];
    return frameTableView.size.height / 50.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    BookACabTableViewCell *cell;
    static NSString *reuseIdentifier = @"BookACabTableViewCell";
    cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (!cell) {
        //        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
        //                                      reuseIdentifier:reuseIdentifier];
        cell = [[BookACabTableViewCell alloc] init];
    }
    
    //    [Logger logDebug:[self TAG]
    //             message:[NSString stringWithFormat:@" cellForRowAtIndexPath : %@", [indexPath description]]];
    
//    NSString *cabName = [[[self arrayCabDetails] objectAtIndex:indexPath.section] objectForKey:@"CabName"];
//    [[cell labelCabName] setText:((!cabName || [cabName length] <= 0 || [cabName caseInsensitiveCompare:@"null"] == NSOrderedSame) ? @"-" : cabName)];
    NSString *carType = [[[self arrayCabDetails] objectAtIndex:indexPath.section] objectForKey:@"CarType"];
    [[cell labelCabName] setText:((!carType || [carType length] <= 0 || [carType caseInsensitiveCompare:@"null"] == NSOrderedSame) ? @"-" : carType)];
    
    NSString *timeEstimate = [NSString stringWithFormat:@"%ld", [[[[self arrayCabDetails] objectAtIndex:indexPath.section] objectForKey:@"timeEstimate"] integerValue]];
    NSString *time = @"";
    if (!timeEstimate || [timeEstimate length] <= 0 || [timeEstimate caseInsensitiveCompare:@"null"] == NSOrderedSame) {
        time = @"Est. time: -";
    } else {
        time = [NSString stringWithFormat:@"%@ %1.0f %@", @"Est. time:", ceilf([timeEstimate doubleValue] / 60.0f), @"mins"];
    }
    [[cell labelEstimatedTime] setText:time];
    
    NSString *lowEstimate = [NSString stringWithFormat:@"%ld", [[[[self arrayCabDetails] objectAtIndex:indexPath.section] objectForKey:@"low_estimate"] integerValue]];
    NSString *highEstimate = [NSString stringWithFormat:@"%ld", [[[[self arrayCabDetails] objectAtIndex:indexPath.section] objectForKey:@"high_estimate"] integerValue]];
    NSString *lowHigh = @"";
    
    if (!lowEstimate || [lowEstimate length] <= 0 || [lowEstimate caseInsensitiveCompare:@"null"] == NSOrderedSame || [lowEstimate caseInsensitiveCompare:@"na"] == NSOrderedSame || !highEstimate || [highEstimate length] <= 0 || [highEstimate caseInsensitiveCompare:@"null"] == NSOrderedSame || [highEstimate caseInsensitiveCompare:@"na"] == NSOrderedSame) {
        lowHigh = @"Est. price: -";
    } else {
        lowHigh = [NSString stringWithFormat:@"%@%@-%@", @"Est. price: \u20B9", lowEstimate, highEstimate];
    }
    
    [[cell labelEstimatedPrice] setText:lowHigh];
    
    NSString *cabName = [[[self arrayCabDetails] objectAtIndex:indexPath.section] objectForKey:@"CabName"];
    if (cabName && [cabName length] > 0) {
        if ([cabName caseInsensitiveCompare:@"Ola"] == NSOrderedSame) {
            [[cell imageViewCabLogo] setImage:[UIImage imageNamed:@"cab_ola_icon.png"]];
        } else if ([cabName caseInsensitiveCompare:@"Uber"] == NSOrderedSame) {
            [[cell imageViewCabLogo] setImage:[UIImage imageNamed:@"cab_uber_icon.png"]];
        } else if ([cabName caseInsensitiveCompare:@"Meru"] == NSOrderedSame) {
            [[cell imageViewCabLogo] setImage:[UIImage imageNamed:@"cab_meru_icon.png"]];
        } else if ([cabName caseInsensitiveCompare:@"TaxiForSure"] == NSOrderedSame) {
            [[cell imageViewCabLogo] setImage:[UIImage imageNamed:@"cab_tfs_icon.png"]];
        } else if ([cabName caseInsensitiveCompare:@"Mega"] == NSOrderedSame) {
            [[cell imageViewCabLogo] setImage:[UIImage imageNamed:@"cab_mega_icon.png"]];
        }
    }
    
    [[cell buttonBookNow] setTag:indexPath.section];
    [[cell buttonBookNow] addTarget:self
                             action:@selector(bookNowPressed:)
                   forControlEvents:UIControlEventTouchUpInside];
    
    HCSStarRatingView *ratingView = [cell ratingView];
    [ratingView setAllowsHalfStars:YES];
    [ratingView setAccurateHalfStars:YES];
    NSString *rating = [[[self arrayCabDetails] objectAtIndex:indexPath.section] objectForKey:@"Rating"];
    if (!rating || [rating isEqual:[NSNull null]] || [rating isEqualToString:@"null"] || [rating floatValue] <= 0.0) {
        [ratingView setValue:0.0];
        [[cell labelNumberRatings] setText:@""];
    } else {
        [ratingView setValue:[rating floatValue]];
        NSString *numberRatings = [[[self arrayCabDetails] objectAtIndex:indexPath.section] objectForKey:@"NoofReviews"];
        if (!numberRatings || [numberRatings isEqual:[NSNull null]] || [numberRatings isEqualToString:@"null"]) {
            [[cell labelNumberRatings] setText:@""];
        } else {
            [[cell labelNumberRatings] setText:[NSString stringWithFormat:@"(%@)", numberRatings]];
        }
    }
    
    [ratingView setTintColor:[UIColor greenColor]];
    [[cell contentView] addSubview:ratingView];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGRect frameTableView = [tableView frame];
    return frameTableView.size.height / 4.0;
}

//#pragma mark - UITableViewDelegate methods
//
//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//
//    [Logger logDebug:[self TAG]
//             message:[NSString stringWithFormat:@" didSelectRowAtIndexPath : %lu", indexPath.section]];
//    
//    [self rowSelectedAtIndex:indexPath.section];
//    
//    [tableView deselectRowAtIndexPath:indexPath
//                             animated:NO];
//}


@end
