//
//  SettingsViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 11/09/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import "SettingsViewController.h"
#import "SWRevealViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    SWRevealViewController *revealViewController = [self revealViewController];
    if (revealViewController) {
        [[self barButtonItem] setTarget:revealViewController];
        [[self barButtonItem] setAction:@selector(revealToggle:)];
        [[self view] addGestureRecognizer:[[self revealViewController] panGestureRecognizer]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
