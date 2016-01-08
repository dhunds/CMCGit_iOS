//
//  CabRatingViewController.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 31/12/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CabRatingViewController;

@protocol CabRatingViewControllerProtocol <NSObject>

@required

- (void)cabRatingSubmittedForSender:(CabRatingViewController *)sender
                  andNotificationID:(NSString *)nid;

@end

@interface CabRatingViewController : UIViewController

@property (strong, nonatomic) NSString *cabID, *nid;

@property (weak, nonatomic) id <CabRatingViewControllerProtocol> delegateCabRatingVCProtocol;

@end
