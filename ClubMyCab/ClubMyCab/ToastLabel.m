//
//  ToastLabel.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 26/08/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import "ToastLabel.h"

@implementation ToastLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initToastWithFrame:(CGRect)frame
              andMessage:(NSString *)message {
    
    self = [super init];
    //	self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        CGRect toastFrame = CGRectMake(frame.origin.x + frame.size.width * 0.05, frame.origin.y + frame.size.height * 0.9, frame.size.width * 0.9, frame.size.height * 0.075);
        
        [self setFrame:toastFrame];
        [self setAlpha:0.75f];
        [self setBackgroundColor:[UIColor colorWithRed:0.0f
                                                 green:0.0f
                                                  blue:0.0f
                                                 alpha:1.0f]];
        [self setTextAlignment:NSTextAlignmentCenter];
        [self setTextColor:[UIColor whiteColor]];
        [self setFont:[UIFont systemFontOfSize:13.0f]];
        [[self layer] setCornerRadius:5.0f];
        [[self layer] setMasksToBounds:YES];
        [self setNumberOfLines:3];
        [self setLineBreakMode:NSLineBreakByWordWrapping];
        [self setText:message];
    }
    
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
