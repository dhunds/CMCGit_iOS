//
//  TripDateTimeViewController.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 23/11/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddressModel.h"

@interface TripDateTimeViewController : UIViewController

@property (strong, nonatomic) AddressModel *addressModelFrom;
@property (strong, nonatomic) AddressModel *addressModelTo;

@property (strong, nonatomic) NSString *segueType;
@end
