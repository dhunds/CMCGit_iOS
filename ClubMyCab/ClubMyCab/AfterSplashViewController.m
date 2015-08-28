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

@property (strong, nonatomic) NSString *currentAppVersion;

@end

@implementation AfterSplashViewController

- (NSString *)TAG {
    return @"AfterSplashViewController";
}

- (NSString *)currentAppVersion {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
}

#pragma mark - View controller life cycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *name = [userDefaults objectForKey:KEY_USER_DEFAULT_NAME];
    NSString *mobile = [userDefaults objectForKey:KEY_USER_DEFAULT_MOBILE];
    BOOL verifyOTP = [userDefaults boolForKey:KEY_USER_DEFAULT_VERIFY_OTP];
    NSString *lastRegisteredAppVersion = [userDefaults objectForKey:KEY_USER_DEFAULT_LAST_APP_VERSION];
    NSString *email = [userDefaults objectForKey:KEY_USER_DEFAULT_EMAIL];
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" viewDidLoad name : %@ mobile : %@ currentAppVersion : %@ verifyOTP : %d", name, mobile, [self currentAppVersion], verifyOTP]];
    
    if(name && mobile && [name length] > 0 && [mobile length] > 0) {
        if(lastRegisteredAppVersion && [lastRegisteredAppVersion length] > 0) {
            if([lastRegisteredAppVersion doubleValue] < [[self currentAppVersion] doubleValue]) {
                // update app version in user defaults
            } else {
                // call /changeuserstatus.php to get force update version
                // in the response check if app to be force updated else if verifyotp false
                // open OTPVC else if veriyotp true fetch pool & open home page vc
            }
        } else {
            // call /updateregid.php with APN id
        }
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
