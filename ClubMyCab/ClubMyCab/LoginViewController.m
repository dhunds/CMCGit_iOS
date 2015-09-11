//
//  LoginViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 19/08/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import "LoginViewController.h"
#import "ToastLabel.h"
#import "GlobalMethods.h"
#import "Logger.h"
#import "ActivityIndicatorView.h"
#import "OTPViewController.h"
#import "RegistrationViewController.h"

@interface LoginViewController () <GlobalMethodsAsyncRequestProtocol>

@property (strong, nonatomic) NSString *TAG;

@property (weak, nonatomic) IBOutlet UITextField *textFieldMobileNumber;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@end

@implementation LoginViewController

- (NSString *)TAG {
    return @"LoginViewController";
}

#pragma mark - View Controller Life Cycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[self navigationController] setNavigationBarHidden:YES
                                               animated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBAction methods

- (IBAction)loginPressed:(UIButton *)sender {
    
    [[self textFieldMobileNumber] resignFirstResponder];
    
    NSString *mobileNumber = [[self textFieldMobileNumber] text];
    
    mobileNumber = [mobileNumber stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if([mobileNumber length] <= 0) {
        [self makeToastWithMessage:@"Please enter mobile number"];
    } else if ([mobileNumber length] < 10) {
        [self makeToastWithMessage:@"Please enter valid mobile number"];
    } else {
        
        [self showActivityIndicatorView];
        
        GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
        
        [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                           endPoint:ENDPOINT_LOGIN
                                                         parameters:[NSString stringWithFormat:@"MobileNumber=%@&DeviceToken=%@&Platform=I", [NSString stringWithFormat:@"0091%@", mobileNumber], @""]
                                                delegateForProtocol:self];
    }
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
        } else if ([error isEqualToString:ERROR_UNAUTHORIZED_ACCESS]) {
            [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
        } else {
            NSString *endPoint = [data valueForKey:KEY_ENDPOINT_ASYNC_CONNECTION];
            if ([endPoint isEqualToString:ENDPOINT_LOGIN]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                if([response isEqualToString:@"login error"]) {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                        message:@"You are not registered, please click on Register"
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                    [alertView show];
                } else {
                    NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                    NSError *error = nil;
                    NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                               options:NSJSONReadingMutableContainers
                                                                                 error:&error];
                    
                    if(!error) {
                        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                        [userDefaults setObject:[[parsedJson valueForKey:@"FullName"] objectAtIndex:0]
                                         forKey:KEY_USER_DEFAULT_NAME];
                        [userDefaults setObject:[[parsedJson valueForKey:@"MobileNumber"] objectAtIndex:0]
                                         forKey:KEY_USER_DEFAULT_MOBILE];
                        [userDefaults setObject:[[parsedJson valueForKey:@"Email"] objectAtIndex:0]
                                         forKey:KEY_USER_DEFAULT_EMAIL];
                        [userDefaults setBool:NO
                                       forKey:KEY_USER_DEFAULT_VERIFY_OTP];
                        
                        [Logger logDebug:[self TAG]
                                 message:[NSString stringWithFormat:@" %@ parsedJson : %@ value : %@", endPoint, [parsedJson description], [[parsedJson valueForKey:@"MobileNumber"] objectAtIndex:0]]];
                        [self performSegueWithIdentifier:@"OTPSegue"
                                                  sender:self];
                    } else {
                        [Logger logError:[self TAG]
                                 message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                        [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                    }
                }
            }
        }
    });
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if([[segue identifier] isEqualToString:@"OTPSegue"]) {
        if([[segue destinationViewController] isKindOfClass:[OTPViewController class]]) {
            [(OTPViewController *)[segue destinationViewController] setFromLoginOrRegistration:OTP_FROM_LOGIN];
        }
    } else if ([[segue identifier] isEqualToString:@"RegisterSegue"]) {
        if([[segue destinationViewController] isKindOfClass:[RegistrationViewController class]]) {
            if([[[self textFieldMobileNumber] text] length] > 0) {
                [(RegistrationViewController *)[segue destinationViewController] setMobileNumber:[[self textFieldMobileNumber] text]];
            }
        }
    }
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
