//
//  MyRidesViewController.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 11/09/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyRidesViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIBarButtonItem *barButtonItem;

@property (strong, nonatomic) NSString *cabIDFromNotification;
@property (strong, nonatomic) NSString *nidFromNotifications;
@end
