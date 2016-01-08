//
//  ClubsInviteViewController.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 30/11/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ClubsInviteViewController;

@protocol ClubsInviteVCProtocol <NSObject>

@required

- (void)membersToInviteFrom:(ClubsInviteViewController *)sender
                withNumbers:(NSString *)numbers
                   andNames:(NSString *)names;

@end

@interface ClubsInviteViewController : UIViewController

@property (strong, nonatomic) NSArray *arrayMyClubs, *arrayMemberOfClubs;
@property (nonatomic) int numberOfSeats;

@property (weak, nonatomic) id <ClubsInviteVCProtocol> delegateClubsInviteVC;

@end
