//
//  WalletsViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 11/09/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import "WalletsViewController.h"
#import "SWRevealViewController.h"
#import "Logger.h"
#import "ActivityIndicatorView.h"
#import "ToastLabel.h"
#import "GlobalMethods.h"
#import "FirstLoginClubsViewController.h"
#import "MyProfileViewController.h"
#import <Google/Analytics.h>

@interface WalletsViewController () <GlobalMethodsAsyncRequestProtocol, UITextFieldDelegate>

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (weak, nonatomic) IBOutlet UILabel *labelWalletStatus;
@property (weak, nonatomic) IBOutlet UIView *viewLinkCreate;
@property (weak, nonatomic) IBOutlet UITextField *textFieldMobile;
@property (weak, nonatomic) IBOutlet UITextField *textFieldEmail;
@property (weak, nonatomic) IBOutlet UIButton *buttonSendOTP;
@property (weak, nonatomic) IBOutlet UITextField *textFieldOTP;
@property (weak, nonatomic) IBOutlet UIButton *buttonLinkWallet;
@property (weak, nonatomic) IBOutlet UILabel *labelTNC;
@property (weak, nonatomic) IBOutlet UIView *viewAlreadyLinked;
@property (weak, nonatomic) IBOutlet UILabel *labelWalletBalance;
@property (weak, nonatomic) IBOutlet UIButton *buttonTopUp;
@property (weak, nonatomic) IBOutlet UILabel *labelCoupon;
@property (weak, nonatomic) IBOutlet UILabel *labelCouponTNC;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *buttonSkip;

@property (strong, nonatomic) NSString *mobileNumber, *name, *email;

@property (strong, nonatomic) NSString *walletAction;

@property (strong, nonatomic) UIAlertView *alertViewProfileImage;

@end

@implementation WalletsViewController

#define LINK_WALLET                 @"LinkWallet"
#define CREATE_WALLET               @"CreateWallet"

- (NSString *)TAG {
    return @"WalletsViewController";
}

#pragma mark - View Controller Life Cycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    SWRevealViewController *revealViewController = [self revealViewController];
    if (revealViewController) {
        [[self barButtonItem] setTarget:revealViewController];
        [[self barButtonItem] setAction:@selector(revealToggle:)];
        [[self view] addGestureRecognizer:[[self revealViewController] panGestureRecognizer]];
    }
    
    NSString *mobile = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_MOBILE];
    [self setMobileNumber:[mobile substringFromIndex:4]];
//    [self setMobileNumber:@"9920981333"];
    [self setName:[[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_NAME]];
    [self setEmail:[[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_EMAIL]];
    
    [[self textFieldMobile] setText:[self mobileNumber]];
    
    if ([self segueType] && [[self segueType] isEqualToString:OTP_FROM_REGISTRATION]) {
        [[self buttonSkip] setHidden:NO];
    } else {
        [[self buttonSkip] setHidden:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName
           value:[self TAG]];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_MOBIKWIK_TOKEN];
    if (token && [token length] > 0) {
        [[self viewAlreadyLinked] setHidden:NO];
        [[self viewLinkCreate] setHidden:YES];
        [[self labelWalletStatus] setHidden:YES];
        
        [self updateCouponLabels];
    } else {
        [self showActivityIndicatorView];
        
        GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
        [globalMethods makeMobikwikURLConnectionAsynchronousRequestToServer:MOBIKWIK_SERVER_URL
                                                                   endPoint:MOBIKWIK_ENDPOINT_QUERY_WALLET
                                                                 parameters:[NSString stringWithFormat:@"cell=%@&msgcode=500&action=existingusercheck&mid=%@&merchantname=%@", [self mobileNumber], MOBIKWIK_MID, MOBIKWIK_MERCHANT_NAME]
                                                        delegateForProtocol:self];
    }
    
    if (![self segueType] || ![[self segueType] isEqualToString:OTP_FROM_REGISTRATION]) {
        NSMutableArray *barButtons = [[[self navigationItem] leftBarButtonItems] mutableCopy];
        if ([barButtons count] < 2) {
            GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
            [barButtons addObject:[globalMethods getProfileImageBarButtonItemWithTarget:self]];
            
            [[self navigationItem] setLeftBarButtonItems:[barButtons copy]];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"WalletClubSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[FirstLoginClubsViewController class]]) {
            
        }
    } else if ([[segue identifier] isEqualToString:@"WalletProfileSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[MyProfileViewController class]]) {
            [(MyProfileViewController *)[segue destinationViewController] setChangeProfilePicture:YES];
        }
    }
}

#pragma mark - Private methods

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

- (BOOL)isResponseCheckSumValid:(NSDictionary *)response {
    
    NSArray *array = [[response allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSString *string = @"";
    
    for (int i = 0; i < [array count]; i++) {
        if (![[array objectAtIndex:i] isEqualToString:@"checksum"]) {
            NSString *value = [response objectForKey:[array objectAtIndex:i]];
            if (value && [value length] > 0) {
                string = [string stringByAppendingString:[NSString stringWithFormat:@"'%@'", value]];
            }
        }
    }
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    if ([globalMethods checkMobikwikResponseCheckSum:[response objectForKey:@"checksum"]
                                         andResponse:string]) {
        return YES;
    } else {
        [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
        [Logger logError:[self TAG]
                 message:@" ResponseCheckSum Invalid!"];
        return NO;
    }
}

- (void)updateCouponLabels {
    NSString *coupon = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_MOBIKWIK_COUPON];
    if (coupon && [coupon length] > 0) {
        [[self labelCoupon] setText:[NSString stringWithFormat:@"Your 50 on 50 offer coupon code : %@", coupon]];
        [[self labelCouponTNC] setText:@"1. Extra cash Amount is fixed at Rs. 50/- for a Minimum \'Add Money\' amount of Rs.50/- \r\n2. Sign Up platform, Coupon Redemption and Payment should be done on iPhone, Windows or Android App\r\n3. Offer can be redeemed only once per user per card and is applicable for the \'Add Money\' payment done during the offer period on MobiKwik App\r\n4. Offer will be valid only for the transactions done through Debit Card or Credit Card. Not valid on Net Banking and Virtual Cards\r\n5. Offer valid for new MobiKwik user only\r\n6. Valid till 31st Oct\'15"];
    } else {
        [[self labelCoupon] setText:@""];
        [[self labelCouponTNC] setText:@""];
    }
    
    [self getWalletBalance];
}

- (void)getWalletBalance {
    [self showActivityIndicatorView];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeMobikwikURLConnectionAsynchronousRequestToServer:MOBIKWIK_SERVER_URL
                                                               endPoint:MOBIKWIK_ENDPOINT_USER_BALANCE
                                                             parameters:[NSString stringWithFormat:@"cell=%@&token=%@&msgcode=501&mid=%@&merchantname=%@", [self mobileNumber], [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_MOBIKWIK_TOKEN], MOBIKWIK_MID, MOBIKWIK_MERCHANT_NAME]
                                                    delegateForProtocol:self];
}

- (void)regenerateToken {
    [self showActivityIndicatorView];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeMobikwikURLConnectionAsynchronousRequestToServer:MOBIKWIK_SERVER_URL
                                                               endPoint:MOBIKWIK_ENDPOINT_TOKEN_REGENERATE
                                                             parameters:[NSString stringWithFormat:@"cell=%@&token=%@&tokentype=1&msgcode=507&mid=%@&merchantname=%@", [self mobileNumber], [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_MOBIKWIK_TOKEN], MOBIKWIK_MID, MOBIKWIK_MERCHANT_NAME]
                                                    delegateForProtocol:self];
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [[self scrollView] setContentOffset:CGPointZero];
    
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    
    if (textField == [self textFieldMobile]) {
        [[self scrollView] setContentOffset:CGPointMake(0.0f, 50.0f)];
    } else if (textField == [self textFieldEmail]) {
        [[self scrollView] setContentOffset:CGPointMake(0.0f, 50.0f)];
    } else if (textField == [self textFieldOTP]) {
        [[self scrollView] setContentOffset:CGPointMake(0.0f, 100.0f)];
    }
    
    return YES;
}

#pragma mark - IBAction methods

- (IBAction)sendOTPPressed:(UIButton *)sender {
    
    [[self textFieldMobile] resignFirstResponder];
    [[self scrollView] setContentOffset:CGPointZero];
    
    [self showActivityIndicatorView];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeMobikwikURLConnectionAsynchronousRequestToServer:MOBIKWIK_SERVER_URL
                                                               endPoint:MOBIKWIK_ENDPOINT_OTP_GENERATE
                                                             parameters:[NSString stringWithFormat:@"cell=%@&amount=10000&msgcode=504&mid=%@&merchantname=%@&tokentype=1", [self mobileNumber], MOBIKWIK_MID, MOBIKWIK_MERCHANT_NAME]
                                                    delegateForProtocol:self];
}

- (IBAction)linkCreateWalletPressed:(UIButton *)sender {
    
    [[self scrollView] setContentOffset:CGPointZero];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    
    if ([[self walletAction] isEqualToString:LINK_WALLET]) {
        if ([[[self textFieldOTP] text] length] <= 0) {
            [self makeToastWithMessage:@"Please enter the OTP"];
            return;
        }
        
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"LinkExistingWallet"
                                                              action:@"LinkExistingWallet"
                                                               label:@"LinkExistingWallet"
                                                               value:nil] build]];
        
        [self showActivityIndicatorView];
        
        [globalMethods makeMobikwikURLConnectionAsynchronousRequestToServer:MOBIKWIK_SERVER_URL
                                                                   endPoint:MOBIKWIK_ENDPOINT_TOKEN_GENERATE
                                                                 parameters:[NSString stringWithFormat:@"cell=%@&amount=10000&otp=%@&msgcode=507&mid=%@&merchantname=%@&tokentype=1", [self mobileNumber], [[self textFieldOTP] text], MOBIKWIK_MID, MOBIKWIK_MERCHANT_NAME]
                                                        delegateForProtocol:self];
    } else if ([[self walletAction] isEqualToString:CREATE_WALLET]) {
        if ([[[self textFieldEmail] text] length] <= 0) {
            [self makeToastWithMessage:@"Please enter your e-mail"];
            return;
        }
        if ([[[self textFieldOTP] text] length] <= 0) {
            [self makeToastWithMessage:@"Please enter the OTP"];
            return;
        }
        
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"CreateNewWallet"
                                                              action:@"CreateNewWallet"
                                                               label:@"CreateNewWallet"
                                                               value:nil] build]];
        
        [self showActivityIndicatorView];
        
        [globalMethods makeMobikwikURLConnectionAsynchronousRequestToServer:MOBIKWIK_SERVER_URL
                                                                   endPoint:MOBIKWIK_ENDPOINT_CREATE_WALLET
                                                                 parameters:[NSString stringWithFormat:@"email=%@&cell=%@&otp=%@&msgcode=502&mid=%@&merchantname=%@", [[self textFieldEmail] text], [self mobileNumber], [[self textFieldOTP] text], MOBIKWIK_MID, MOBIKWIK_MERCHANT_NAME]
                                                        delegateForProtocol:self];
    }
}

- (IBAction)tncPressed:(UIButton *)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Terms & Conditions"
                                                        message:@"User agrees to allow iShareRyde to transfer amount to/from user\'s Mobikwik wallet to settle fare splits at the end of each journey undertaken by the user. These transfers will be undertaken only after confirmation of fare split by both sending and receiving user. Further upon completion of journey and subsequent payment done, the User will not claim any other charges whatsoever from iShareRyde or its partners"
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (IBAction)topUpPressed:(UIButton *)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://m.mobikwik.com"]];
}

- (IBAction)skipPressed:(UIButton *)sender {
    
    if ([self segueType] && [[self segueType] isEqualToString:OTP_FROM_REGISTRATION]) {
        [self performSegueWithIdentifier:@"WalletClubSegue"
                                  sender:self];
    }
}

- (IBAction)profileImageBarButtonItemPressed {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Profile Picture"
                                                        message:@"Do you want to change your profile picture?"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Yes", @"No", nil];
    [self setAlertViewProfileImage:alertView];
    [alertView show];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:@"Yes"]) {
        [self performSegueWithIdentifier:@"WalletProfileSegue"
                                  sender:self];
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
            if ([endPoint isEqualToString:MOBIKWIK_ENDPOINT_QUERY_WALLET]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                           options:NSJSONReadingMutableContainers
                                                                             error:&error];
                if (!error) {
                    if ([self isResponseCheckSumValid:parsedJson]) {
                        if ([[parsedJson objectForKey:@"status"] isEqualToString:@"SUCCESS"]) {
                            [[self labelWalletStatus] setText:@"Link a wallet to pay for rides quickly. \r\n\r\nYou already have a Mobikwik wallet registered with your number. Click on \'Send OTP\' to link it now"];
                            
                            [self setWalletAction:LINK_WALLET];
                        } else {
                            [[self labelWalletStatus] setText:@"Link a wallet to pay for rides quickly. \r\n\r\nYou do not have a Mobikwik wallet registered with your number. Click on \'Send OTP\' to create a wallet"];
                            
                            [self setWalletAction:CREATE_WALLET];
                            [[self textFieldEmail] setHidden:NO];
                        }
                    }
                } else {
                    [Logger logError:[self TAG]
                             message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                    [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                }
            } else if ([endPoint isEqualToString:MOBIKWIK_ENDPOINT_OTP_GENERATE]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                           options:NSJSONReadingMutableContainers
                                                                             error:&error];
                if (!error) {
                    if ([self isResponseCheckSumValid:parsedJson]) {
                        if ([[parsedJson objectForKey:@"status"] isEqualToString:@"SUCCESS"]) {
                            
                            if ([[self walletAction] isEqualToString:LINK_WALLET]) {
                                [[self buttonLinkWallet] setTitle:@"Link Wallet"
                                                         forState:UIControlStateNormal];
                            } else if ([[self walletAction] isEqualToString:CREATE_WALLET]) {
                                [[self buttonLinkWallet] setTitle:@"Create Wallet"
                                                         forState:UIControlStateNormal];
                            }
                            
                            [[self buttonLinkWallet] setHidden:NO];
                            [[self textFieldOTP] setHidden:NO];
                            [[self labelTNC] setHidden:NO];
                            [[self labelWalletStatus] setHidden:YES];
                            
                            [self makeToastWithMessage:@"We have sent OTP to your mobile"];
                            
                        } else {
                            [self makeToastWithMessage:[parsedJson objectForKey:@"statusdescription"]];
                        }
                    }
                } else {
                    [Logger logError:[self TAG]
                             message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                    [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                }
            } else if ([endPoint isEqualToString:MOBIKWIK_ENDPOINT_TOKEN_GENERATE]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                           options:NSJSONReadingMutableContainers
                                                                             error:&error];
                if (!error) {
                    if ([self isResponseCheckSumValid:parsedJson]) {
                        if ([[parsedJson objectForKey:@"status"] isEqualToString:@"SUCCESS"]) {
                            [[NSUserDefaults standardUserDefaults] setObject:[parsedJson objectForKey:@"token"]
                                                                      forKey:KEY_USER_DEFAULT_MOBIKWIK_TOKEN];
                            
                            [[self viewAlreadyLinked] setHidden:NO];
                            [[self viewLinkCreate] setHidden:YES];
                            
                            [self updateCouponLabels];
                            
                            if ([self segueType] && [[self segueType] isEqualToString:OTP_FROM_REGISTRATION]) {
                                [self performSegueWithIdentifier:@"WalletClubSegue"
                                                          sender:self];
                            }
                        } else {
                            [self makeToastWithMessage:[parsedJson objectForKey:@"statusdescription"]];
                        }
                    }
                } else {
                    [Logger logError:[self TAG]
                             message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                    [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                }
            } else if ([endPoint isEqualToString:MOBIKWIK_ENDPOINT_CREATE_WALLET]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                           options:NSJSONReadingMutableContainers
                                                                             error:&error];
                if (!error) {
                    if ([self isResponseCheckSumValid:parsedJson]) {
                        if ([[parsedJson objectForKey:@"status"] isEqualToString:@"SUCCESS"]) {
                            
                            [self makeToastWithMessage:@"User created succesfully!"];
                            
                            [self showActivityIndicatorView];
                            GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
                            [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                                               endPoint:MOBIKWIK_ENDPOINT_GET_COUPONS
                                                                             parameters:[NSString stringWithFormat:@"type=newWallet&provider=mobikwik&mobileNumber=%@", [self mobileNumber]]
                                                                    delegateForProtocol:self];
                        } else {
                            [self makeToastWithMessage:[parsedJson objectForKey:@"statusdescription"]];
                        }
                    }
                } else {
                    [Logger logError:[self TAG]
                             message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                    [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                }
            } else if ([endPoint isEqualToString:MOBIKWIK_ENDPOINT_USER_BALANCE]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                           options:NSJSONReadingMutableContainers
                                                                             error:&error];
                if (!error) {
                    if ([self isResponseCheckSumValid:parsedJson]) {
                        if ([[parsedJson objectForKey:@"status"] isEqualToString:@"SUCCESS"]) {
                            [[self labelWalletBalance] setText:[NSString stringWithFormat:@"Your wallet balance : \u20B9%@", [parsedJson objectForKey:@"balanceamount"]]];
                            [self regenerateToken];
                        } else {
                            NSString *statusDescription = [parsedJson objectForKey:@"statusdescription"];
                            [self makeToastWithMessage:statusDescription];
                            if ([statusDescription rangeOfString:@"Invalid Token"].location != NSNotFound || [statusDescription rangeOfString:@"Token Expired"].location != NSNotFound) {
                                [self regenerateToken];
                            }
                        }
                    }
                } else {
                    [Logger logError:[self TAG]
                             message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                    [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                }
            } else if ([endPoint isEqualToString:MOBIKWIK_ENDPOINT_TOKEN_REGENERATE]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                           options:NSJSONReadingMutableContainers
                                                                             error:&error];
                if (!error) {
                    if ([[parsedJson objectForKey:@"status"] caseInsensitiveCompare:@"SUCCESS"] == NSOrderedSame) {
                        [[NSUserDefaults standardUserDefaults] setObject:[parsedJson objectForKey:@"token"]
                                                                  forKey:KEY_USER_DEFAULT_MOBIKWIK_TOKEN];
                    } else {
                        [self makeToastWithMessage:[parsedJson objectForKey:@"statusdescription"]];
                    }
                } else {
                    [Logger logError:[self TAG]
                             message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                    [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                }
            } else if ([endPoint isEqualToString:MOBIKWIK_ENDPOINT_GET_COUPONS]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                           options:NSJSONReadingMutableContainers
                                                                             error:&error];
                if (!error) {
                    if ([[parsedJson objectForKey:@"status"] isEqualToString:@"success"]) {
                        NSDictionary *dictionary = [parsedJson objectForKey:@"data"];
                        [[NSUserDefaults standardUserDefaults] setObject:[dictionary objectForKey:@"couponName"]
                                                                  forKey:KEY_USER_DEFAULT_MOBIKWIK_COUPON];
                        
                        [self showActivityIndicatorView];
                        
                        GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
                        [globalMethods makeMobikwikURLConnectionAsynchronousRequestToServer:MOBIKWIK_SERVER_URL
                                                                                   endPoint:MOBIKWIK_ENDPOINT_TOKEN_GENERATE
                                                                                 parameters:[NSString stringWithFormat:@"cell=%@&amount=10000&otp=%@&msgcode=507&mid=%@&merchantname=%@&tokentype=1", [self mobileNumber], [[self textFieldOTP] text], MOBIKWIK_MID, MOBIKWIK_MERCHANT_NAME]
                                                                        delegateForProtocol:self];
                        
                    }
                } else {
                    [Logger logError:[self TAG]
                             message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                    [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                }
            }
        }
    });
}

@end
