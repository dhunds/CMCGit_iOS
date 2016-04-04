//
//  HomeViewController.m
//  iShareRyde
//
//  Created by MacDev2 on 01/04/16.
//  Copyright © 2016 iShareRyde. All rights reserved.
//

#import "HomeViewController.h"
#import "ContentViewController.h"

@interface HomeViewController () <NKJPagerViewDataSource, NKJPagerViewDelegate>

@end

@implementation HomeViewController


- (void)viewDidLoad
{
    
    self.dataSource = self;
    self.delegate = self;
    self.infiniteSwipe = NO;
    
    [super viewDidLoad];
}

#pragma mark - NKJPagerViewDataSource

- (NSUInteger)numberOfTabView
{
    return 3;
}

- (UIView *)viewPager:(NKJPagerViewController *)viewPager viewForTabAtIndex:(NSUInteger)index
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.f, 0.f, 160.f, 44.f)];
    
    CGFloat r = (arc4random_uniform(255) + 1.f) / 255.0;
    CGFloat g = (arc4random_uniform(255) + 1.f) / 255.0;
    CGFloat b = (arc4random_uniform(255) + 1.f) / 255.0;
    UIColor *color = [UIColor colorWithRed:r green:g blue:b alpha:1.0];
    label.backgroundColor = color;
    
    label.font = [UIFont systemFontOfSize:12.0];
    label.text = [NSString stringWithFormat:@"Tab #%lu", index];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    
    return label;
}

- (UIViewController *)viewPager:(NKJPagerViewController *)viewPager contentViewControllerForTabAtIndex:(NSUInteger)index
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ContentViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"ContentViewController"];
    vc.textLabel = [NSString stringWithFormat:@"Content View #%lu", index];
    return vc;
}

- (CGFloat)widthOfTabViewWithIndex:(NSInteger)index
{
    return 107.f;
}

#pragma mark - NKJPagerViewDelegate

- (void)viewPager:(NKJPagerViewController *)viewPager didSwitchAtIndex:(NSInteger)index withTabs:(NSArray *)tabs
{
    [UIView animateWithDuration:0.1f
                     animations:^{
                         for (UIView *view in self.tabs) {
                             if (index == view.tag) {
                                 view.alpha = 1.f;
                             } else {
                                 view.alpha = 0.5f;
                             }
                         }
                     }
                     completion:^(BOOL finished){}];
}


@end
