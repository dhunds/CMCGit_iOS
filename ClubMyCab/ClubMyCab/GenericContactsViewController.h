//
//  GenericContactsViewController.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 09/10/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GenericContactsViewController;

@protocol GenericContactsVCProtocol <NSObject>

@required

- (void)contactsToInviteFrom:(GenericContactsViewController *)sender
                 withNumbers:(NSString *)numbers
                    andNames:(NSString *)names;

@end

@interface GenericContactsViewController : UIViewController

#define SEGUE_FROM_CREATE_CLUB              @"SegueFromCreateClub"
#define SEGUE_FROM_ADD_MEMBERS              @"SegueFromAddMembers"
#define SEGUE_FROM_REFER_MEMBERS            @"SegueFromReferMembers"
#define SEGUE_FROM_RIDE_INVITATION          @"SegueFromRideInvitation"

@property (strong, nonatomic) NSString *segueType;
@property (strong, nonatomic) NSDictionary *dictionaryClubDetails;

@property (weak, nonatomic) id <GenericContactsVCProtocol> delegateGenericContactsVC;

@end
