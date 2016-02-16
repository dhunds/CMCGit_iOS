//
//  ClubDetailsTableViewCell.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 04/11/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ClubDetailsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageViewImage;
@property (weak, nonatomic) IBOutlet UILabel *labelName;
@property (weak, nonatomic) IBOutlet UIButton *buttonDelete;

@end
