//
//  MyClubsTableViewCell.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 08/10/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyClubsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *buttonLowMembership;
@property (weak, nonatomic) IBOutlet UILabel *labelClubNameAndMembers;
@property (weak, nonatomic) IBOutlet UIButton *buttonDeleteClub;

@end
