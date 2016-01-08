//
//  ContactsTableViewCell.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 12/10/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageViewImage;
@property (weak, nonatomic) IBOutlet UILabel *labelName;
@property (weak, nonatomic) IBOutlet UILabel *labelNumber;
@property (weak, nonatomic) IBOutlet UIButton *buttonSelected;

@end
