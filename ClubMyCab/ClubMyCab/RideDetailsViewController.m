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
#import "XMPPFramework.h"

@interface RideDetailsViewController () <GMSMapViewDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, GenericContactsVCProtocol, XMPPStreamDelegate>

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

@property (strong, nonatomic) NSArray *arrayMembers;

@property (strong, nonatomic) UIAlertView *alertViewCancelRide;

@property (strong, nonatomic) XMPPStream *xmppStream;

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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self changeChatStatus:CHAT_STATUS_ONLINE];
    [self getMembersForMap];
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" viewDidAppear connect : %d", [self connect]]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self changeChatStatus:CHAT_STATUS_OFFLINE];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - XMPP methods

- (void)setupStream {
    [self setXmppStream:[[XMPPStream alloc] init]];
    [[self xmppStream] setHostName:SERVER_IP_ADDRESS];
    [[self xmppStream] setHostPort:5222];
    [[self xmppStream] addDelegate:self
                     delegateQueue:dispatch_get_main_queue()];
}

- (void)goOnline {
    XMPPPresence *presence = [XMPPPresence presence];
    [[self xmppStream] sendElement:presence];
}

- (void)goOffline {
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    [[self xmppStream] sendElement:presence];
}

- (BOOL)connect {
    
    [self setupStream];
    
    NSString *jabberID = @"00919920981334_009199209813341445412514809";
    NSString *myPassword = @"00919920981334_009199209813341445412514809";
    
//    if (![[self xmppStream] isDisconnected]) {
//        return YES;
//    }
    
    if (jabberID == nil || myPassword == nil) {
        
        return NO;
    }
    
    [[self xmppStream] setMyJID:[XMPPJID jidWithString:jabberID]];
//    password = myPassword;
    
    NSError *error = nil;
    [[self xmppStream] connectWithTimeout:XMPPStreamTimeoutNone
                                    error:&error];
    if (error)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:[NSString stringWithFormat:@"Can't connect to server %@", [error localizedDescription]]
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
        [alertView show];
        
        return NO;
    }
    
    return YES;
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender {
    
    NSLog(@"xmppStreamDidConnect");
    
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
    
    NSLog(@"xmppStreamDidAuthenticate");
    
}


- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {
    
    NSLog(@"didReceiveMessage");
    
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence {
    
    NSLog(@"didReceivePresence");
    
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([[segue identifier] isEqualToString:@"BookACabRideSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[BookACabViewController class]]) {
            
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
    
    NSString *bookingRef = [[self dictionaryRideDetails] objectForKey:@"BookingRefNo"];
    if (bookingRef && [bookingRef length] > 0 && ![bookingRef isEqualToString:@"null"]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Book a cab"
                                                            message:@"A cab has already been booked for the ride"
                                                           delegate:self
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
        [alertView show];
    } else {
        [self performSegueWithIdentifier:@"BookACabRideSegue"
                                  sender:self];
    }
}

- (IBAction)cancelRidePressed:(UIButton *)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cancel Ride"
                                                        message:@"Are you sure you want to cancel the ride?"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Yes", @"No", nil];
    [alertView show];
    
    [self setAlertViewCancelRide:alertView];
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
    
//    [Logger logDebug:[self TAG]
//             message:[NSString stringWithFormat:@" getPath url : %@", urlString]];
    
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
    
//    [Logger logDebug:[self TAG]
//             message:[NSString stringWithFormat:@" getPathForMembersJoinedWithWayPoints url : %@", urlString]];
    
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
        
        [[self viewRideInfoParent] setHidden:NO];
    } else {
        [[self viewRideInfoParent] setHidden:YES];
    }
}

- (void)checkCabStatusAndShowDialog {
    //TODO
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
                [self hideActivityIndicatorView];
                [self popVC];
            } else if ([endPoint isEqualToString:ENDPOINT_OWNER_INVITE_FRIENDS]) {
                [self hideActivityIndicatorView];
                [self makeToastWithMessage:@"Invitation sent!"];
            }
        }
    });
}

@end
