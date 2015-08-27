//
//  AfterSplashViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 20/08/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import "AfterSplashViewController.h"
#import "Logger.h"
#import "IntroPageViewController.h"

@interface AfterSplashViewController ()

@property (strong, nonatomic) NSString *TAG;

@end

@implementation AfterSplashViewController

- (NSString *)TAG {
    return @"AfterSplashViewController";
}

#pragma mark - View controller life cycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *name = [userDefaults stringForKey:KEY_USER_DEFAULT_NAME];
    NSString *mobile = [userDefaults stringForKey:KEY_USER_DEFAULT_MOBILE];
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" viewDidLoad name : %@ mobile : %@", name, mobile]];
    
    if(name && mobile && [name length] > 0 && [mobile length] > 0) {
        
    } else {
        [self performSegueWithIdentifier:@"ViewPagerSegue"
                                  sender:self];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"ViewPagerSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[IntroPageViewController class]]) {
            [(IntroPageViewController *)[segue destinationViewController] initializeDatasource];
        }
    }
}


@end
