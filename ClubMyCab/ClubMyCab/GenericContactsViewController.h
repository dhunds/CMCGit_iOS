//
//  GenericContactsViewController.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 09/10/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GenericContactsViewController : UIViewController

#define SEGUE_FROM_CREATE_CLUB              @"SegueFromCreateClub"
#define SEGUE_FROM_ADD_MEMBERS              @"SegueFromAddMembers"
#define SEGUE_FROM_REFER_MEMBERS            @"SegueFromReferMembers"

@property (strong, nonatomic) NSString *segueType;
@property (strong, nonatomic) NSDictionary *dictionaryClubDetails;

@end
