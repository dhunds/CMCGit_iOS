//
//  ToastLabel.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 26/08/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ToastLabel : UILabel

- (id)initToastWithFrame:(CGRect)frame
              andMessage:(NSString *)message;

@end
