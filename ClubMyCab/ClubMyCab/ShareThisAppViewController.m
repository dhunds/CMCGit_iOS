//
//  ShareThisAppViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 11/09/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import "ShareThisAppViewController.h"
#import "SWRevealViewController.h"
#import "Logger.h"
#import "ToastLabel.h"
#import "ActivityIndicatorView.h"
#import "GlobalMethods.h"
#import "OfferDetailsViewController.h"

@interface ShareThisAppViewController () <UITableViewDataSource, UITableViewDelegate, GlobalMethodsAsyncRequestProtocol>

@property (weak, nonatomic) IBOutlet UILabel *labelRewardPoints;
@property (weak, nonatomic) IBOutlet UITableView *tableViewOffers;

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) NSArray *arrayOffers;
@property (strong, nonatomic) NSDictionary *dictionaryUserData;

@end

@implementation ShareThisAppViewController

- (NSString *)TAG {
    return @"ShareThisAppViewController";
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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self showActivityIndicatorView];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_USER_DATA
                                                     parameters:[NSString stringWithFormat:@"mobileNumber=%@", [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_MOBILE]]
                                            delegateForProtocol:self];
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
    if ([[segue identifier] isEqualToString:@"OfferDetailsSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[OfferDetailsViewController class]]) {
            [(OfferDetailsViewController *)[segue destinationViewController] setDictionaryUserData:[self dictionaryUserData]];
            [(OfferDetailsViewController *)[segue destinationViewController] setDictionaryOffer:sender];
        }
    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return [[self arrayOffers] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    static NSString *reuseIdentifier = @"OffersTableViewCell";
    cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:reuseIdentifier];
    }
    
    //    [Logger logDebug:[self TAG]
    //             message:[NSString stringWithFormat:@" cellForRowAtIndexPath : %@", [indexPath description]]];
    
    [[cell textLabel] setText:[[[self arrayOffers] objectAtIndex:indexPath.row] objectForKey:@"title"]];
    [[cell detailTextLabel] setText:[[[self arrayOffers] objectAtIndex:indexPath.row] objectForKey:@"UserOfferStatus"]];
    [[cell detailTextLabel] setNumberOfLines:0];
    [[cell detailTextLabel] setLineBreakMode:NSLineBreakByWordWrapping];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGRect frameTableView = [tableView frame];
    return frameTableView.size.height / 5.0;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" didSelectRowAtIndexPath : %tu", indexPath.row]];
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:NO];
    
    [self performSegueWithIdentifier:@"OfferDetailsSegue"
                              sender:[[self arrayOffers] objectAtIndex:indexPath.row]];
    
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
            if ([endPoint isEqualToString:ENDPOINT_USER_DATA]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                
                NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                      options:NSJSONReadingMutableContainers
                                                                        error:&error];
                
                if(!error) {
                    
                    //                        [Logger logDebug:[self TAG]
                    //                                 message:[NSString stringWithFormat:@" %@ parsedJson : %@", endPoint, [[parsedJson objectAtIndex:1] objectForKey:@"Message"]]];
                    
                    if([[parsedJson objectForKey:@"status"] caseInsensitiveCompare:@"success"] == NSOrderedSame) {
                        [self setDictionaryUserData:[parsedJson objectForKey:@"data"]];
                        
                        [[self labelRewardPoints] setText:[NSString stringWithFormat:@"Your reward points : %@", [[self dictionaryUserData] objectForKey:@"totalCredits"]]];
                        
                        [self showActivityIndicatorView];
                        
                        GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
                        [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                                           endPoint:ENDPOINT_GET_OFFERS
                                                                         parameters:[NSString stringWithFormat:@"mobileNumber=%@", [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_MOBILE]]
                                                                delegateForProtocol:self];
                    } else {
                        [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                    }
                    
                } else {
                    [Logger logError:[self TAG]
                             message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                    [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                }
            } else if ([endPoint isEqualToString:ENDPOINT_GET_OFFERS]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                
                NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                           options:NSJSONReadingMutableContainers
                                                                             error:&error];
                
                if(!error) {
                    
                    //                        [Logger logDebug:[self TAG]
                    //                                 message:[NSString stringWithFormat:@" %@ parsedJson : %@", endPoint, [[parsedJson objectAtIndex:1] objectForKey:@"Message"]]];
                    
                    if([[parsedJson objectForKey:@"status"] caseInsensitiveCompare:@"success"] == NSOrderedSame) {
                        [self setArrayOffers:[parsedJson objectForKey:@"data"]];
                        
                        [[self tableViewOffers] reloadData];
                    } else {
                        [self makeToastWithMessage:[parsedJson objectForKey:@"message"]];
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
