//
//  MemberOfClubsTableViewCell.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 08/10/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MemberOfClubsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *buttonLowMembership;
@property (weak, nonatomic) IBOutlet UILabel *labelClubNameAndMembers;
@property (weak, nonatomic) IBOutlet UIButton *buttonDeleteClub;
@property (weak, nonatomic) IBOutlet UILabel *labelOwnerName;

@end
