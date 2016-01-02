//
//  BookACabViewController.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 08/12/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddressModel.h"


@interface BookACabViewController : UIViewController

@property (strong, nonatomic) AddressModel *addressModelFrom, *addressModelTo;

@property (strong, nonatomic) NSDictionary *dictionaryBookCabFromRide;

@end
