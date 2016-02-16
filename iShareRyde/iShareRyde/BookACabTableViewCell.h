//
//  BookACabTableViewCell.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 19/12/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HCSStarRatingView.h"

@interface BookACabTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageViewCabLogo;
@property (weak, nonatomic) IBOutlet UILabel *labelCabName;
@property (weak, nonatomic) IBOutlet UIButton *buttonBookNow;
@property (weak, nonatomic) IBOutlet UILabel *labelEstimatedTime;
@property (weak, nonatomic) IBOutlet UILabel *labelEstimatedPrice;
@property (weak, nonatomic) IBOutlet HCSStarRatingView *ratingView;
@property (weak, nonatomic) IBOutlet UILabel *labelNumberRatings;

@end
