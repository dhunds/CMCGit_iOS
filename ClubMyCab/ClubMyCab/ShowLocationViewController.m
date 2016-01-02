//
//  ShowLocationViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 01/01/16.
//  Copyright © 2016 ClubMyCab. All rights reserved.
//

#import "ShowLocationViewController.h"
#import <GoogleMaps/GoogleMaps.h>

@interface ShowLocationViewController ()

@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *labelAddress;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewPin;

@end

@implementation ShowLocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSArray *array = [[[self dictionaryNotification] objectForKey:@"Message"] componentsSeparatedByString:@"-"];
    [[self labelAddress] setText:[array lastObject]];
    
    array = [[[self dictionaryNotification] objectForKey:@"UserLatLong"] componentsSeparatedByString:@","];
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:[[array firstObject] doubleValue]
                                                            longitude:[[array lastObject] doubleValue]
                                                                 zoom:14];
    
    [[self mapView] animateToCameraPosition:camera];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
