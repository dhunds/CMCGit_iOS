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

@interface LoginViewController () <GlobalMethodsAsyncRequestProtocol>

@property (strong, nonatomic) NSString *TAG;

@property (weak, nonatomic) IBOutlet UITextField *textFieldMobileNumber;

@property (strong, nonatomic) ToastLabel *toastLabel;

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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBAction methods

- (IBAction)loginPressed:(UIButton *)sender {
    
    [[self textFieldMobileNumber] resignFirstResponder];
    
    NSString *mobileNumber = [[self textFieldMobileNumber] text];
    
    mobileNumber = [mobileNumber stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if([mobileNumber length] == 0) {
        [self makeToastWithMessage:@"Please enter mobile number"];
    } else if ([mobileNumber length] < 10) {
        [self makeToastWithMessage:@"Please enter valid mobile number"];
    } else {
        GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
        
        [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                           endPoint:ENDPOINT_LOGIN
                                                         parameters:[NSString stringWithFormat:@"MobileNumber=%@&DeviceToken=%@&Platform=I", [NSString stringWithFormat:@"0091%@", mobileNumber], @""]
                                                delegateForProtocol:self];
    }
}

- (IBAction)registerPressed:(UIButton *)sender {
}

#pragma mark - GlobalMethodsAsyncRequestProtocol methods

- (void)asyncRequestComplete:(GlobalMethods *)sender
                        data:(NSDictionary *)data {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [Logger logDebug:[self TAG]
                 message:[NSString stringWithFormat:@" asyncRequestComplete loginResponse : %@", data]];
        
        NSString *error = [data valueForKey:KEY_ERROR_ASYNC_REQUEST];
        
        if([error isEqualToString:ERROR_CONNECTION_VALUE]) {
            [Logger logDebug:[self TAG]
                     message:@"here..."];
            [self makeToastWithMessage:NO_INTERNET_ERROR_MESSAGE];
        } else if ([error isEqualToString:ERROR_DATA_NIL_VALUE]) {
            [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
        } else {
            NSString *endPoint = [data valueForKey:KEY_ENDPOINT_ASYNC_CONNECTION];
            if ([endPoint isEqualToString:ENDPOINT_LOGIN]) {
                
            }
        }
    });
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
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

@end
