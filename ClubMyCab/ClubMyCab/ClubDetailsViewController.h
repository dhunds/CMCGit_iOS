//
//  ClubDetailsViewController.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 09/10/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ClubDetailsViewController : UIViewController

#define MY_CLUBS_SEGUE              @"MyClubsSegue"
#define MEMBER_OF_CLUBS_SEGUE       @"MemberOfClubsSegue"

@property (strong, nonatomic) NSDictionary *dictionaryClubDetails;
@property (strong, nonatomic) NSString *segueType;

@end
