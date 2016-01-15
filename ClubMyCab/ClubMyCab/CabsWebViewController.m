//
//  CabsWebViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 28/12/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import "CabsWebViewController.h"
#import "Logger.h"
#import "ActivityIndicatorView.h"
#import "ToastLabel.h"

@interface CabsWebViewController () <UIWebViewDelegate>

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation CabsWebViewController

- (NSString *)TAG {
    return @"CabsWebViewController";
}

#pragma mark - View Controller Life Cycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if ([[self cabType] isEqualToString:UBER_REQUEST_ID]) {
        [[self webView] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[self uberURL]]]];
    } else if ([[self cabType] isEqualToString:OLA_REQUEST_ID]) {
        [[self webView] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[self olaURL]]]];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIWebViewDelegate methods

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
    [Logger logError:[self TAG]
             message:[NSString stringWithFormat:@" webView didFailLoadWithError : %@", [error localizedDescription]]];
    
    [self hideActivityIndicatorView];
//    [self showAlertViewWithMessage:[error localizedDescription]];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    [self hideActivityIndicatorView];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self showActivityIndicatorView];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" webView shouldStartLoadWithRequest : %@", [[request URL] absoluteString]]];
    NSString *urlString = [[request URL] absoluteString];
    if ([urlString rangeOfString:@"uberapi.php?code="].location != NSNotFound && [urlString rangeOfString:@"&requestid="].location == NSNotFound) {
        urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"&requestid=%@", [self uberRequestID]]];
        urlString = [urlString stringByReplacingOccurrencesOfString:@"https"
                                                         withString:@"http"];
        
        [[self webView] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
        
        return NO;
    } else if ([urlString rangeOfString:@"processing.php"].location != NSNotFound) {
        
        [[self delegateCabsWebViewControllerProtocol] bookingProcessCompletedForCabType:UBER_REQUEST_ID
                                                                          withRequestID:[self uberRequestID]
                                                                         andOptionalURL:@""];
        [self popVC];
    } else if ([urlString rangeOfString:@"olaApi.php#"].location != NSNotFound) {
        
        urlString = [urlString stringByReplacingOccurrencesOfString:@"#"
                                                         withString:@"?"];
        urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"&requestid=%@", [self olaRequestID]]];
        
        [[self delegateCabsWebViewControllerProtocol] bookingProcessCompletedForCabType:OLA_REQUEST_ID
                                                                          withRequestID:[self olaRequestID]
                                                                         andOptionalURL:urlString];
        [self popVC];
        
        return NO;
    }
    
    return YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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

- (void)popVC {
    [[self navigationController] popViewControllerAnimated:NO];
}

@end
