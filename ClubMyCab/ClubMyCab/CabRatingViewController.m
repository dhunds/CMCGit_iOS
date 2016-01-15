//
//  CabRatingViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 31/12/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import "CabRatingViewController.h"
#import "HCSStarRatingView.h"
#import "Logger.h"
#import "ToastLabel.h"
#import "ActivityIndicatorView.h"
#import "GlobalMethods.h"

@interface CabRatingViewController () <GlobalMethodsAsyncRequestProtocol, UITextFieldDelegate>

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (weak, nonatomic) IBOutlet UITextField *textFieldCabName;
@property (weak, nonatomic) IBOutlet UILabel *labelRating;

@property (strong, nonatomic) NSString *currentRating;

@property (strong, nonatomic) NSArray *arrayCabs;
@property (nonatomic) NSUInteger currentSelectedIndex;

@end

@implementation CabRatingViewController

- (NSString *)TAG {
    return @"CabRatingViewController";
}

#pragma mark - View Controller Life Cycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CGRect labelFrame = [[self labelRating] frame];
    CGRect viewFrame = [[self view] frame];
    
    HCSStarRatingView *ratingView = [[HCSStarRatingView alloc] initWithFrame:CGRectMake(25.0, labelFrame.origin.y + 75.0, viewFrame.size.width * 0.75, viewFrame.size.height * 0.15)];
    [ratingView setMinimumValue:0.0];
    [ratingView setMaximumValue:5.0];
    [ratingView setValue:0.0];
    [self setCurrentRating:@"0.0"];
    [ratingView setAllowsHalfStars:NO];
    [ratingView setAccurateHalfStars:NO];
    [ratingView setTintColor:[UIColor greenColor]];
    [ratingView addTarget:self
                   action:@selector(didChangeValue:)
         forControlEvents:UIControlEventValueChanged];
    [[self view] addSubview:ratingView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self showActivityIndicatorView];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_GET_CABS_FOR_RATING
                                                     parameters:[NSString stringWithFormat:@"CabID=%@", [self cabID]]
                                            delegateForProtocol:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBAction methods

- (IBAction)didChangeValue:(id)sender {
    
    if ([sender isKindOfClass:[HCSStarRatingView class]]) {
        [Logger logDebug:[self TAG]
                 message:[NSString stringWithFormat:@" rating : %1.0f", [(HCSStarRatingView *)sender value]]];
        [self setCurrentRating:[NSString stringWithFormat:@"%1.0f", [(HCSStarRatingView *)sender value]]];
    }
}

- (IBAction)submitPressed:(UIButton *)sender {
    if ([[self arrayCabs] count] > 0) {
        if ([self currentRating] > 0) {
            [self showActivityIndicatorView];
            
            GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
            [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                               endPoint:ENDPOINT_CABS_RATING_CMC
                                                             parameters:[NSString stringWithFormat:@"CabDetailID=%@&CabID=%@&Rating=%@&MobileNumber=%@", [[[self arrayCabs] objectAtIndex:[self currentSelectedIndex]] objectForKey:@"CabDetailID"], [self cabID], [self currentRating], [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_MOBILE]]
                                                    delegateForProtocol:self];
        } else {
            [self makeToastWithMessage:@"Please provide a rating!"];
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
    
    if ([self activityIndicatorView] != nil) {
        return;     //location update method being called twice, so 2 activity indicators are being displayed
    }
    
    [self setActivityIndicatorView:[[ActivityIndicatorView alloc] initWithFrame:[[self view] bounds]
                                                               messageToDisplay:PLEASE_WAIT_MESSAGE]];
    [[self view] addSubview:[self activityIndicatorView]];
}

- (void)hideActivityIndicatorView {
    
    if ([self activityIndicatorView] != nil) {
        [[self activityIndicatorView] removeFromSuperview];
    }
}

- (void)popVC {
    [[self navigationController] popViewControllerAnimated:NO];
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
            if ([endPoint isEqualToString:ENDPOINT_GET_CABS_FOR_RATING]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                if(!response || [[response lowercaseString] rangeOfString:@"no cabs found"].location != NSNotFound) {
                    [self makeToastWithMessage:@"Sorry, no cabs were found"];
                } else {
                    NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                    NSError *error = nil;
                    NSArray *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                          options:NSJSONReadingMutableContainers
                                                                            error:&error];
                    
                    if(!error) {
                        
                        //                        [Logger logDebug:[self TAG]
                        //                                 message:[NSString stringWithFormat:@" %@ parsedJson : %@", endPoint, [[parsedJson objectAtIndex:1] objectForKey:@"Message"]]];
                        [self setArrayCabs:parsedJson];
                        
                        [[self textFieldCabName] setText:[NSString stringWithFormat:@"%@ (%@)", [[[self arrayCabs] firstObject] objectForKey:@"CabName"], [[[self arrayCabs] firstObject] objectForKey:@"CarType"]]];
                        [self setCurrentSelectedIndex:0];
                        
                    } else {
                        [Logger logError:[self TAG]
                                 message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                        [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                    }
                }
            } else if ([endPoint isEqualToString:ENDPOINT_CABS_RATING_CMC]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                if (response && [[response lowercaseString] rangeOfString:@"success"].location != NSNotFound) {
                    [[self delegateCabRatingVCProtocol] cabRatingSubmittedForSender:self
                                                                  andNotificationID:[self nid]];
                    [self popVC];
                } else {
                    [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                }
            }
        }
    });
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@""
                                                                             message:@"Please select a cab"
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (int i = 0; i < [[self arrayCabs] count]; i++) {
        [alertController addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%@ (%@)", [[[self arrayCabs] objectAtIndex:i] objectForKey:@"CabName"], [[[self arrayCabs] objectAtIndex:i] objectForKey:@"CarType"]]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              [self setCurrentSelectedIndex:i];
                                                              [[self textFieldCabName] setText:[action title]];
                                                              [Logger logDebug:[self TAG]
                                                                       message:[NSString stringWithFormat:@" selected index : %lu", [self currentSelectedIndex]]];
                                                          }]];
    }
    
    [self presentViewController:alertController
                       animated:YES
                     completion:^{}];
    
    return NO;
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
