//
//  PlacesAutoCompleteViewController.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 18/11/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddressModel.h"

@class PlacesAutoCompleteViewController;

@protocol PlacesAutoCompleteVCProtocol <NSObject>

@required

- (void)addressModelFromSenderAutoComp:(PlacesAutoCompleteViewController *)sender
                       address:(AddressModel *)model
                  forSegueType:(NSString *)segueType;

@end

@interface PlacesAutoCompleteViewController : UIViewController

#define SEGUE_TYPE_HOME_PAGE_FROM_AUTO_COMPLETE              @"SegueTypeHomePageFromAutoComplete"
#define SEGUE_TYPE_HOME_PAGE_TO_AUTO_COMPLETE                @"SegueTypeHomePageToAutoComplete"
#define SEGUE_TYPE_FAV_LOC_AUTO_COMPLETE                     @"SegueTypeFavLocAutoComplete"

@property (strong, nonatomic) NSString *segueType;

@property (weak, nonatomic) id <PlacesAutoCompleteVCProtocol> delegatePlacesAutoCompleteVC;

@end
