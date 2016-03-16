//
//  ShowLocationViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 01/01/16.
//  Copyright © 2016 ClubMyCab. All rights reserved.
//

#import "ShowLocationViewController.h"
#import <GoogleMaps/GoogleMaps.h>

@interface ShowLocationViewController () <GMSMapViewDelegate>

@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *labelAddress;

@end

@implementation ShowLocationViewController

#pragma mark - View Controller Life Cycle methods 

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSArray *array = [[[self dictionaryNotification] objectForKey:@"Message"] componentsSeparatedByString:@"-"];
    [[self labelAddress] setText:[array lastObject]];
    
    array = [[[self dictionaryNotification] objectForKey:@"UserLatLong"] componentsSeparatedByString:@","];
    
    GMSMarker *marker = [GMSMarker markerWithPosition:CLLocationCoordinate2DMake([[array firstObject] doubleValue], [[array lastObject] doubleValue])];
    [marker setIcon:[UIImage imageNamed:@"shared_location"]];
    [marker setMap:[self mapView]];
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:[[array firstObject] doubleValue]
                                                            longitude:[[array lastObject] doubleValue]
                                                                 zoom:14];
    
    [[self mapView] animateToCameraPosition:camera];
    
    [[self mapView] setMyLocationEnabled:YES];
    [[[self mapView] settings] setMyLocationButton:YES];
    
    [[self mapView] setDelegate:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - GMSMapViewDelegate methods

- (BOOL)mapView:(GMSMapView *)mapView
   didTapMarker:(GMSMarker *)marker {
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
        NSArray *array = [[[self dictionaryNotification] objectForKey:@"UserLatLong"] componentsSeparatedByString:@","];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"comgooglemaps://?center=%@,%@&zoom=14", [array firstObject], [array lastObject]]]];
    }
    
    return YES;
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
