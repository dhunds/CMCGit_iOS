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
}

- (void)viewDidAppear:(BOOL)animated {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *name = [userDefaults objectForKey:KEY_USER_DEFAULT_NAME];
    NSString *mobile = [userDefaults objectForKey:KEY_USER_DEFAULT_MOBILE];
    BOOL verifyOTP = [userDefaults boolForKey:KEY_USER_DEFAULT_VERIFY_OTP];
    NSString *lastRegisteredAppVersion = [userDefaults objectForKey:KEY_USER_DEFAULT_LAST_APP_VERSION];
//    NSString *email = [userDefaults objectForKey:KEY_USER_DEFAULT_EMAIL];
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" viewDidLoad name : %@ mobile : %@ currentAppVersion : %@ verifyOTP : %d", name, mobile, [self currentAppVersion], verifyOTP]];
    
    if(name && mobile && [name length] > 0 && [mobile length] > 0) {
        if(lastRegisteredAppVersion && [lastRegisteredAppVersion length] > 0) {
            if([lastRegisteredAppVersion doubleValue] < [[self currentAppVersion] doubleValue]) {
                [userDefaults setObject:[self currentAppVersion]
                                 forKey:KEY_USER_DEFAULT_LAST_APP_VERSION];
                
                [self changeUserStatus];
            } else {
                [self changeUserStatus];
            }
        } else {
            [self changeUserStatus];
        }
    } else {
//        id viewController = nil;
//        
//        viewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"MainIntroPageVC"];
//        
//        [(IntroPageViewController *)viewController initializeDatasource];
//        
//        [self presentViewController:viewController
//                           animated:NO
//                         completion:nil];
        
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
                                                              otherButtonTitles:@"Update", nil];
                    [alertView show];
                } else {
                    [self fetchImageName];
                }
            } else if ([endPoint isEqualToString:ENDPOINT_FETCH_IMAGE_NAME]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                
                if (response && [response length] > 0) {
                    NSData *image = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/ProfileImages/%@", SERVER_ADDRESS, response]]];
                    
                    [userDefaults setObject:image
                                     forKey:KEY_USER_DEFAULT_PROFILE_IMAGE_DATA];
                } else {
                    [userDefaults setObject:nil
                                     forKey:KEY_USER_DEFAULT_PROFILE_IMAGE_DATA];
                }
                
                if ([userDefaults boolForKey:KEY_USER_DEFAULT_VERIFY_OTP]) {
                    [self performSegueWithIdentifier:@"SplashHomeSegue"
                                              sender:self];
                } else {
                    [self performSegueWithIdentifier:@"OTPSplashSegue"
                                              sender:self];
                }
                
            }
        }
    });
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Update"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/in/app/ishareryde/id1073560784?ls=1&mt=8"]];
//        https://itunes.apple.com/in/app/ishareryde/id1073560784?ls=1&mt=8
    }
//    else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Later"]) {
//        //handle exit with an alert view, abrupt quit not apple approved way
//        exit(0);
//    }
    
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
    } else if ([[segue identifier] isEqualToString:@"SplashHomeSegue"]) {
        
    }
}

#pragma mark - Private methods

- (void)fetchImageName {
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_FETCH_IMAGE_NAME
                                                     parameters:[NSString stringWithFormat:@"MobileNumber=%@", [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_MOBILE]]
                                            delegateForProtocol:self];
}

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
    
    if ([self toastLabel]) {
        [[self toastLabel] removeFromSuperview];
    }
    
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
