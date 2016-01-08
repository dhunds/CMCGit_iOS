//
//  FavoriteLocationsTableViewCell.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 18/11/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FavoriteLocationsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *labelTag;
@property (weak, nonatomic) IBOutlet UITextField *textFieldAddress;
@property (weak, nonatomic) IBOutlet UIButton *buttonMap;

@end
