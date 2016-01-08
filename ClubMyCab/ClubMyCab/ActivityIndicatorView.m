//
//  ActivityIndicatorView.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 27/08/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import "ActivityIndicatorView.h"

@implementation ActivityIndicatorView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
   messageToDisplay:(NSString *)message {
    
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setBackgroundColor:[UIColor colorWithRed:0.0f
                                                 green:0.0f
                                                  blue:0.0f
                                                 alpha:0.6f]];
        
        UIView *subView = [[UIView alloc] init];
        [subView setFrame:CGRectMake(0.0f, 0.0f, [self frame].size.width * 0.80f, [self frame].size.height * 0.15f)];
        [subView setCenter:CGPointMake([self frame].size.width / 2.0f, [self frame].size.height / 2.0f)];
        [subView setBackgroundColor:[UIColor whiteColor]];
//        [subView setBackgroundColor:[UIColor colorWithRed:0.0f
//                                                    green:0.0f
//                                                     blue:0.0f
//                                                    alpha:1.0f]];
        [[subView layer] setCornerRadius:10.0f];
        
        UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        CGRect boundsSubview = [subView bounds];
        CGAffineTransform transform = CGAffineTransformMakeScale(1.5f, 1.5f);
        [activityIndicatorView setTransform:transform];
        [activityIndicatorView setCenter:CGPointMake(boundsSubview.origin.x + (boundsSubview.size.width * 0.15f), boundsSubview.origin.y + (boundsSubview.size.height * 0.50f))];
        [activityIndicatorView setHidesWhenStopped:YES];
        [subView addSubview:activityIndicatorView];
        [activityIndicatorView startAnimating];
        
        UILabel *activityIndicatorMessage = [[UILabel alloc] init];
        [activityIndicatorMessage setFrame:CGRectMake(boundsSubview.origin.x + (boundsSubview.size.width * 0.25f), boundsSubview.origin.y + (boundsSubview.size.height * 0.25f), boundsSubview.size.width * 0.75f, boundsSubview.size.height * 0.5f)];
        //		[activityIndicatorMessage setCenter:CGPointMake(boundsSubview.origin.x + (boundsSubview.size.width * 0.25f), boundsSubview.origin.y + (boundsSubview.size.height * 0.48f))];
        [activityIndicatorMessage setTextColor:[UIColor blackColor]];
        //		[activityIndicatorMessage setAdjustsFontSizeToFitWidth:YES];
        [activityIndicatorMessage setNumberOfLines:2];
        [activityIndicatorMessage setLineBreakMode:NSLineBreakByWordWrapping];
        [activityIndicatorMessage setFont:[UIFont systemFontOfSize:15.0f]];
        [activityIndicatorMessage setText:message];
        [subView addSubview:activityIndicatorMessage];
        
        [self addSubview:subView];
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
