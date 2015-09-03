//
//  OTPViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 27/08/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import "OTPViewController.h"
#import "Logger.h"
#import "GlobalMethods.h"
#import "ToastLabel.h"
#import "ActivityIndicatorView.h"

@interface OTPViewController () <GlobalMethodsAsyncRequestProtocol>

@property (strong, nonatomic) NSString *TAG;

@property (weak, nonatomic) IBOutlet UITextField *textFieldOTP;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@end

@implementation OTPViewController

- (NSString *)TAG {
    return @"OTPViewController";
}

#pragma mark - View Controller Life Cycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBAction methods

- (IBAction)resendOTPPressed:(UIButton *)sender {
    
    [[self textFieldOTP] resignFirstResponder];
    
    [self showActivityIndicatorView];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_RESEND_OTP
                                                     parameters:[NSString stringWithFormat:@"MobileNumber=%@", [userDefaults objectForKey:KEY_USER_DEFAULT_MOBILE]]
                                            delegateForProtocol:self];
}

- (IBAction)continuePressed:(UIButton *)sender {
    
    [[self textFieldOTP] resignFirstResponder];
    
    if([[[self textFieldOTP] text] length] > 0) {
        [self showActivityIndicatorView];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
        
        if ([[self fromLoginOrRegistration] isEqualToString:OTP_FROM_LOGIN]) {
            [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                               endPoint:ENDPOINT_VERIFY_LOGIN_OTP
                                                             parameters:[NSString stringWithFormat:@"MobileNumber=%@&singleusepassword=%@&DeviceToken=%@&Platform=I", [userDefaults objectForKey:KEY_USER_DEFAULT_MOBILE], [[self textFieldOTP] text], @""]
                                                    delegateForProtocol:self];
        } else if ([[self fromLoginOrRegistration] isEqualToString:OTP_FROM_REGISTRATION]) {
            [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                               endPoint:ENDPOINT_VERIFY_REGISTRATION_OTP
                                                             parameters:[NSString stringWithFormat:@"MobileNumber=%@&singleusepassword=%@", [userDefaults objectForKey:KEY_USER_DEFAULT_MOBILE], [[self textFieldOTP] text]]
                                                    delegateForProtocol:self];
        }
        
//        [Logger logDebug:[self TAG]
//                 message:[NSString stringWithFormat:@" continuePressed params : %@", [NSString stringWithFormat:@"MobileNumber=%@&singleusepassword=%@&DeviceToken=%@&Platform=I", [userDefaults stringForKey:KEY_USER_DEFAULT_MOBILE], [[self textFieldOTP] text], @""]]];
    } else {
        [self makeToastWithMessage:@"Please enter OTP"];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark - GlobalMethodsAsyncRequestProtocol methods

- (void)asyncRequestComplete:(GlobalMethods *)sender
                        data:(NSDictionary *)data {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self hideActivityIndicatorView];
        
        NSString *error = [data valueForKey:KEY_ERROR_ASYNC_REQUEST];
        
        if([error isEqualToString:ERROR_CONNECTION_VALUE]) {
            [self makeToastWithMessage:NO_INTERNET_ERROR_MESSAGE];
        } else if ([error isEqualToString:ERROR_DATA_NIL_VALUE]) {
            [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
        } else {
            NSString *endPoint = [data valueForKey:KEY_ENDPOINT_ASYNC_CONNECTION];
            NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
            
            if ([endPoint isEqualToString:ENDPOINT_VERIFY_LOGIN_OTP]) {
                
                if(response && [response caseInsensitiveCompare:@"SUCCESS"] == NSOrderedSame) {
                    
                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                    [userDefaults setBool:YES
                                   forKey:KEY_USER_DEFAULT_VERIFY_OTP];
                    
                    //TODO open home screen vc
                    
                } else if (response && [response caseInsensitiveCompare:@"OTPEXPIRE"] == NSOrderedSame) {
                    [self makeToastWithMessage:@"Entered OTP has expired. Please click resend OTP"];
                } else {
                    [self makeToastWithMessage:@"Entered OTP is not valid"];
                }
            } else if ([endPoint isEqualToString:ENDPOINT_RESEND_OTP]) {
                
                if(response && [response caseInsensitiveCompare:@"FAILURE"] == NSOrderedSame) {
                    [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                }
            } else if ([endPoint isEqualToString:ENDPOINT_VERIFY_REGISTRATION_OTP]) {
                
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                [userDefaults setBool:YES
                               forKey:KEY_USER_DEFAULT_VERIFY_OTP];
                
                //TODO open home screen vc
                
            }
        }
    });
}

#pragma mark - Private methods

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

- (void)showActivityIndicatorView {
    
    [self setActivityIndicatorView:[[ActivityIndicatorView alloc] initWithFrame:[[self view] bounds]
                                                               messageToDisplay:PLEASE_WAIT_MESSAGE]];
    [[self view] addSubview:[self activityIndicatorView]];
}

- (void)hideActivityIndicatorView {
    
    if ([self activityIndicatorView] != nil) {
        [[self activityIndicatorView] removeFromSuperview];
    }
}

@end
