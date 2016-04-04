//
//  RidesViewController.h
//  iShareRyde
//
//  Created by MacDev2 on 29/03/16.
//  Copyright © 2016 iShareRyde. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RidesViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIBarButtonItem *barButtonItem;

@property (strong, nonatomic) NSString *cabIDFromNotification;
@property (strong, nonatomic) NSString *nidFromNotifications;

@end
