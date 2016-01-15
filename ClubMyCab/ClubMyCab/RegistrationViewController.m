//
//  RegistrationViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 28/08/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import "RegistrationViewController.h"
#import "ToastLabel.h"
#import "ActivityIndicatorView.h"
#import "Logger.h"
#import "GlobalMethods.h"
#import "OTPViewController.h"

@interface RegistrationViewController () <GlobalMethodsAsyncRequestProtocol>

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (weak, nonatomic) IBOutlet UITextField *textFieldFullName;
@property (weak, nonatomic) IBOutlet UITextField *textFieldMobileNumber;
@property (weak, nonatomic) IBOutlet UITextField *textFieldEmail;
@property (weak, nonatomic) IBOutlet UITextField *textFieldReferralCode;

@end

@implementation RegistrationViewController

- (NSString *)TAG {
    return @"RegistrationViewController";
}

#pragma mark - View Controller Life Cycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[self navigationController] setNavigationBarHidden:NO
                                               animated:NO];
    
    if([[self mobileNumber] length] > 0) {
        [[self textFieldMobileNumber] setText:[self mobileNumber]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBAction methods

- (IBAction)submitPressed:(UIButton *)sender {
    
    [[self textFieldFullName] resignFirstResponder];
    [[self textFieldMobileNumber] resignFirstResponder];
    [[self textFieldEmail] resignFirstResponder];
    [[self textFieldReferralCode] resignFirstResponder];
    
    NSString *name = [[self textFieldFullName] text];
    NSString *number = [[self textFieldMobileNumber] text];
    number = [number stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *email = [[self textFieldEmail] text];
    NSString *referralCode = [[self textFieldReferralCode] text];
    
    if([name length] <= 0) {
        [self makeToastWithMessage:@"Please enter Full Name"];
    } else if ([number length] <= 0) {
        [self makeToastWithMessage:@"Please enter mobile number"];
    } else if ([number length] < 10) {
        [self makeToastWithMessage:@"Please enter valid mobile number"];
    } else if ([email length] <= 0) {
        [self makeToastWithMessage:@"Please enter e-mail address"];
    } else if ([email rangeOfString:@"@"].location == NSNotFound || [email rangeOfString:@"."].location == NSNotFound) {
        [self makeToastWithMessage:@"Please enter a valid e-mail address"];
    } else {
        [self showActivityIndicatorView];
        
        NSString *params = @"";
        if([referralCode length] > 0) {
            params = [NSString stringWithFormat:@"FullName=%@&Password=&MobileNumber=0091%@&DeviceToken=%@&Email=%@&Gender=&DOB=&Platform=I&referralCode=%@", name, number, @"", email, referralCode];
        } else {
            params = [NSString stringWithFormat:@"FullName=%@&Password=&MobileNumber=0091%@&DeviceToken=%@&Email=%@&Gender=&DOB=&Platform=I", name, number, @"", email];
        }
        GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
        [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                           endPoint:ENDPOINT_REGISTRATION
                                                         parameters:params
                                                delegateForProtocol:self];
    }
}

- (IBAction)termsConditionsPressed:(UIButton *)sender {
    
    NSURL *url = [[NSURL alloc] initWithString:@"http://ishareryde.com/terms.html"];
    [[UIApplication sharedApplication] openURL:url];
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
            if ([endPoint isEqualToString:ENDPOINT_REGISTRATION]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                
                NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                           options:NSJSONReadingAllowFragments
                                                                             error:&error];
                if(!error) {
                    
                    NSString *status = [parsedJson valueForKey:@"status"];
                    NSString *message = [parsedJson valueForKey:@"message"];
                    
                    [Logger logDebug:[self TAG]
                             message:[NSString stringWithFormat:@" %@ status : %@ message : %@", endPoint, status, message]];
                    
                    if (status && [status caseInsensitiveCompare:@"SUCCESS"] == NSOrderedSame) {
                        
                        NSString *name = [[self textFieldFullName] text];
                        NSString *number = [[self textFieldMobileNumber] text];
                        number = [NSString stringWithFormat:@"0091%@", [number stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
                        NSString *email = [[self textFieldEmail] text];
                        
                        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                        [userDefaults setObject:name
                                         forKey:KEY_USER_DEFAULT_NAME];
                        [userDefaults setObject:number
                                         forKey:KEY_USER_DEFAULT_MOBILE];
                        [userDefaults setObject:email
                                         forKey:KEY_USER_DEFAULT_EMAIL];
                        [userDefaults setBool:NO
                                       forKey:KEY_USER_DEFAULT_VERIFY_OTP];
                        [userDefaults setObject:[self currentAppVersion]
                                         forKey:KEY_USER_DEFAULT_LAST_APP_VERSION];
                        
                        [self performSegueWithIdentifier:@"OTPRegisterSegue"
                                                  sender:self];
                    } else {
                        [self makeToastWithMessage:message];
                    }
                } else {
                    [Logger logError:[self TAG]
                             message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                    [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                }
                
                
                
                
//                if([response isEqualToString:@"login error"]) {
//                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
//                                                                        message:@"You are not registered, please click on Register"
//                                                                       delegate:nil
//                                                              cancelButtonTitle:@"OK"
//                                                              otherButtonTitles:nil];
//                    [alertView show];
//                } else {
//                    NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
//                    NSError *error = nil;
//                    NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
//                                                                               options:NSJSONReadingMutableContainers
//                                                                                 error:&error];
//                    
//                    if(!error) {
//                        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//                        [userDefaults setObject:[[parsedJson valueForKey:@"FullName"] objectAtIndex:0]
//                                         forKey:KEY_USER_DEFAULT_NAME];
//                        [userDefaults setObject:[[parsedJson valueForKey:@"MobileNumber"] objectAtIndex:0]
//                                         forKey:KEY_USER_DEFAULT_MOBILE];
//                        [userDefaults setObject:[[parsedJson valueForKey:@"Email"] objectAtIndex:0]
//                                         forKey:KEY_USER_DEFAULT_EMAIL];
//                        [userDefaults setBool:NO
//                                       forKey:KEY_USER_DEFAULT_VERIFY_OTP];
//                        
//                        [Logger logDebug:[self TAG]
//                                 message:[NSString stringWithFormat:@" %@ parsedJson : %@ value : %@", ENDPOINT_LOGIN, [parsedJson description], [[parsedJson valueForKey:@"MobileNumber"] objectAtIndex:0]]];
//                        [self performSegueWithIdentifier:@"OTPSegue"
//                                                  sender:self];
//                    } else {
//                        
//                    }
//                }
            }
        }
    });
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"OTPRegisterSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[OTPViewController class]]) {
            [(OTPViewController *)[segue destinationViewController] setFromLoginOrRegistration:OTP_FROM_REGISTRATION];
        }
    }
}

#pragma mark - Private methods

- (NSString *)currentAppVersion {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
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
