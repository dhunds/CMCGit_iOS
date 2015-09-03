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
#import "GlobalMethods.h"
#import "ToastLabel.h"
#import "OTPViewController.h"

@interface AfterSplashViewController () <GlobalMethodsAsyncRequestProtocol, UIAlertViewDelegate>

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;

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
                //TODO update app version in user defaults & open home page vc
            } else {
                //TODO call /changeuserstatus.php to get force update version
                // in the response check if app to be force updated else if verifyotp false
                // open OTPVC else if veriyotp true fetch pool & open home page vc
                
                [self changeUserStatus];
            }
        } else {
            //TODO call /updateregid.php with APN id
            
            //TODO call /changeuserstatus.php to get force update version
            // in the response check if app to be force updated else if verifyotp false
            // open OTPVC else if veriyotp true fetch pool & open home page vc
            
            [self changeUserStatus];
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

#pragma mark - GlobalMethodsAsyncRequestProtocol methods

- (void)asyncRequestComplete:(GlobalMethods *)sender
                        data:(NSDictionary *)data {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString *error = [data valueForKey:KEY_ERROR_ASYNC_REQUEST];
        
        if([error isEqualToString:ERROR_CONNECTION_VALUE]) {
            [self makeToastWithMessage:NO_INTERNET_ERROR_MESSAGE];
        } else if ([error isEqualToString:ERROR_DATA_NIL_VALUE]) {
            [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
        } else {
            NSString *endPoint = [data valueForKey:KEY_ENDPOINT_ASYNC_CONNECTION];
            if ([endPoint isEqualToString:ENDPOINT_CHANGE_USER_STATUS]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                
                if ([[self currentAppVersion] doubleValue] < [response doubleValue]) {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Upgrade available!"
                                                                        message:@"Newer version of the app is available. You need to update before proceeding"
                                                                       delegate:self
                                                              cancelButtonTitle:nil
                                                              otherButtonTitles:@"Update", @"Later", nil];
                    [alertView show];
                } else {
                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                    if ([userDefaults boolForKey:KEY_USER_DEFAULT_VERIFY_OTP]) {
                        //TODO open home page vc
                    } else {
                        [self performSegueWithIdentifier:@"OTPSplashSegue"
                                                  sender:self];
                    }
                }
            }
        }
    });
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Update"]) {
        //TODO get actual app link & test on device
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/in/app/whatsapp-messenger/id310633997?mt=8"]];
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Later"]) {
        //TODO handle exit with an alert view, abrupt quit not apple approved way
        exit(0);
    }
    
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
    } else if ([[segue identifier] isEqualToString:@"OTPSplashSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[OTPViewController class]]) {
            [(OTPViewController *)[segue destinationViewController] setFromLoginOrRegistration:OTP_FROM_LOGIN];
        }
    }
}

#pragma mark - Private methods

- (NSString *)currentAppVersion {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
}

- (void)changeUserStatus {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_CHANGE_USER_STATUS
                                                     parameters:[NSString stringWithFormat:@"CabId=&MemberNumber=%@&chatstatus=offline&IsOwner=&platform=I", [userDefaults objectForKey:KEY_USER_DEFAULT_MOBILE]]
                                            delegateForProtocol:self];
}

- (void)makeToastWithMessage:(NSString *)message {
    
    [self setToastLabel:[[ToastLabel alloc] initToastWithFrame:[[self view] bounds]
                                                    andMessage:message]];
    
    [[self view] addSubview:[self toastLabel]];
    
    UIViewAnimationOptions optionsForToast = UIViewAnimationOptionCurveLinear;
    
    [UIView animateWithDuration:(TOAST_DELAY * 2)
                          delay:0.0
                        options:optionsForToast
                     animations:^{
                         [[self toastLabel] setAlpha:1.0f];
                     }
                     completion:^(BOOL finished) {
                         
                         if (finished)
                         {
                             [UIView animateWithDuration:TOAST_DELAY
                                                   delay:0.0
                                                 options:optionsForToast
                                              animations:^{
                                                  [[self toastLabel] setAlpha:0.0f];
                                              }
                                              completion:^(BOOL finished) {
                                                  [[self toastLabel] removeFromSuperview];
                                              }];
                         }
                         
                     }];
}


@end
