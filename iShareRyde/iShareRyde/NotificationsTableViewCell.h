//
//  NotificationsTableViewCell.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 06/10/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NotificationsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextView *textViewDescription;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewNotificationType;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewUnread;
@property (weak, nonatomic) IBOutlet UILabel *labelTime;
@property (weak, nonatomic) IBOutlet UILabel *labelDate;


@end
