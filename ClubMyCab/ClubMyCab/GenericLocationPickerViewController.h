//
//  GenericLocationPickerViewController.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 13/11/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddressModel.h"

@class GenericLocationPickerViewController;

@protocol GenericLocationPickerVCProtocol <NSObject>

@required

- (void)addressModelFromSender:(GenericLocationPickerViewController *)sender
                       address:(AddressModel *)model
                  forSegueType:(NSString *)segueType;

@end

@interface GenericLocationPickerViewController : UIViewController

#define SEGUE_TYPE_HOME_PAGE_FROM_LOCATION              @"SegueTypeHomePageFromLocation"
#define SEGUE_TYPE_HOME_PAGE_TO_LOCATION                @"SegueTypeHomePageToLocation"
#define SEGUE_TYPE_FAV_LOC_LOCATION                     @"SegueTypeFavLocLocation"

@property (strong, nonatomic) NSString *segueType;

@property (weak, nonatomic) id <GenericLocationPickerVCProtocol> delegateGenericLocationPickerVC;

@end
