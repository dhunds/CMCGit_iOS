//
//  MyRidesTableViewCell.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 03/12/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyRidesTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageViewOwnerImage;
@property (weak, nonatomic) IBOutlet UILabel *labelOwnerName;
@property (weak, nonatomic) IBOutlet UILabel *labelFromTo;
@property (weak, nonatomic) IBOutlet UILabel *labelDate;
@property (weak, nonatomic) IBOutlet UILabel *labelTime;
@property (weak, nonatomic) IBOutlet UILabel *labelTotalSeats;
@property (weak, nonatomic) IBOutlet UILabel *labelAvailableSeats;

@end
