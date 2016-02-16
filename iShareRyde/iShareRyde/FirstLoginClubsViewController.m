//
//  FirstLoginClubsViewController.m
//  iShareRyde
//
//  Created by Rohit Dhundele on 21/01/16.
//  Copyright © 2016 ClubMyCab. All rights reserved.
//

#import "FirstLoginClubsViewController.h"
#import "SWRevealViewController.h"
#import "Logger.h"
#import "ActivityIndicatorView.h"
#import "ToastLabel.h"
#import "GlobalMethods.h"
#import "MemberOfClubsTableViewCell.h"

@interface FirstLoginClubsViewController ()

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (weak, nonatomic) IBOutlet UILabel *labelClubStatus;
@property (weak, nonatomic) IBOutlet UITableView *tableViewClubs;
@property (weak, nonatomic) IBOutlet UIButton *buttonContinue;
@property (weak, nonatomic) IBOutlet UIButton *buttonSkip;

@property (strong, nonatomic) NSArray *arrayMyClubs, *arrayMemberOfClubs;

@end

@implementation FirstLoginClubsViewController

- (NSString *)TAG {
    return @"FirstLoginClubsViewController";
}

#pragma mark - View Controller Life Cycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[self labelClubStatus] setText:@""];
    
    [self showActivityIndicatorView];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_FETCH_CLUBS
                                                     parameters:[NSString stringWithFormat:@"OwnerNumber=%@", [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_MOBILE]]
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
    if ([[segue identifier] isEqualToString:@"ClubsRevealSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[SWRevealViewController class]]) {
            
        }
    }
}

#pragma mark - IBAction methods

- (IBAction)continuePressed:(UIButton *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:YES
                                            forKey:KEY_USER_DEFAULT_FIRST_LOGIN_CLUB];
    [self performSegueWithIdentifier:@"ClubsRevealSegue"
                              sender:self];
}

- (IBAction)skipPressed:(UIButton *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:NO
                                            forKey:KEY_USER_DEFAULT_FIRST_LOGIN_CLUB];
    [self performSegueWithIdentifier:@"ClubsRevealSegue"
                              sender:self];
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
            if ([endPoint isEqualToString:ENDPOINT_FETCH_CLUBS]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                if (response && [response caseInsensitiveCompare:@"No Users of your Club"] == NSOrderedSame) {
                    [[self labelClubStatus] setText:@"Let\'s start!! Invite your friends to join your ride sharing groups"];
                    [[self buttonContinue] setTitle:@"Create groups"
                                           forState:UIControlStateNormal];
                    [[self tableViewClubs] setHidden:YES];
                } else {
                    NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                    NSError *error = nil;
                    NSArray *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                          options:NSJSONReadingMutableContainers
                                                                            error:&error];
                    if (!error) {
                        //                        [Logger logDebug:[self TAG]
                        //                                 message:[NSString stringWithFormat:@" parsedJson : %@", parsedJson]];
                        
                        [[self labelClubStatus] setText:@"Congratulations! You are already member of the following groups and can start sharing rides immediately!"];
                        [[self buttonContinue] setTitle:@"Create more groups"
                                               forState:UIControlStateNormal];
                        [[self tableViewClubs] setHidden:NO];
                        
                        NSMutableArray *mutableMyClubs = [NSMutableArray array];
                        NSMutableArray *mutableMemberOfClubs = [NSMutableArray array];
                        
                        for (int i = 0; i < [parsedJson count]; i++) {
                            if ([[[parsedJson objectAtIndex:i] objectForKey:@"IsPoolOwner"] isEqualToString:@"1"]) {
                                
                                [mutableMyClubs addObject:[parsedJson objectAtIndex:i]];
                                //                                [Logger logDebug:[self TAG]
                                //                                         message:[NSString stringWithFormat:@" IsPoolOwner : %@", [[parsedJson objectAtIndex:i] objectForKey:@"NoofMembers"]]];
                            } else {
                                [mutableMemberOfClubs addObject:[parsedJson objectAtIndex:i]];
                                //                                [Logger logDebug:[self TAG]
                                //                                         message:[NSString stringWithFormat:@" IsNotPoolOwner : %@", [[parsedJson objectAtIndex:i] objectForKey:@"NoofMembers"]]];
                            }
                        }
                        
                        [self setArrayMyClubs:[mutableMyClubs copy]];
                        [self setArrayMemberOfClubs:[mutableMemberOfClubs copy]];
                        
                        [[self tableViewClubs] reloadData];
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

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self arrayMemberOfClubs] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MemberOfClubsTableViewCell *cell;
    
    static NSString *reuseIdentifier = @"MemberOfClubsTableViewCell";
    cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (!cell) {
        cell = [[MemberOfClubsTableViewCell alloc] init];
    }
    
    [[cell buttonLowMembership] setHidden:YES];
    
    [[cell labelClubNameAndMembers] setText:[NSString stringWithFormat:@"%@    (%@)", [[[self arrayMemberOfClubs] objectAtIndex:indexPath.row] objectForKey:@"PoolName"], [[[self arrayMemberOfClubs] objectAtIndex:indexPath.row] objectForKey:@"NoofMembers"]]];
    [[cell labelOwnerName] setText:[NSString stringWithFormat:@"(%@)", [[[self arrayMemberOfClubs] objectAtIndex:indexPath.row] objectForKey:@"OwnerName"]]];
    
    [[cell buttonDeleteClub] setHidden:YES];
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGRect frameTableView = [tableView frame];
    return frameTableView.size.height / 5;
}

@end
