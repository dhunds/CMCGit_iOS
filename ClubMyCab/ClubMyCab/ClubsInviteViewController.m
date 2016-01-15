//
//  ClubsInviteViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 30/11/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import "ClubsInviteViewController.h"
#import "Logger.h"
#import "MyClubsTableViewCell.h"
#import "MemberOfClubsTableViewCell.h"
#import "ToastLabel.h"

@interface ClubsInviteViewController () <UIAlertViewDelegate>

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;

@property (strong, nonatomic) NSMutableArray *arrayMyClubsSelected, *arrayMemberOfClubsSelected;

@property (weak, nonatomic) IBOutlet UITableView *tableViewMyClubs;
@property (weak, nonatomic) IBOutlet UITableView *tableViewMemberOfClubs;

@property (strong, nonatomic) NSString *numberString, *nameString;

@end

@implementation ClubsInviteViewController

- (NSString *)TAG {
    return @"ClubsInviteViewController";
}

- (NSMutableArray *)arrayMyClubsSelected {
    if (!_arrayMyClubsSelected) {
        _arrayMyClubsSelected = [NSMutableArray array];
    }
    
    return _arrayMyClubsSelected;
}

- (NSMutableArray *)arrayMemberOfClubsSelected {
    if (!_arrayMemberOfClubsSelected) {
        _arrayMemberOfClubsSelected = [NSMutableArray array];
    }
    
    return _arrayMemberOfClubsSelected;
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

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (tableView == [self tableViewMyClubs]) {
        return [[self arrayMyClubs] count];
    } else if (tableView == [self tableViewMemberOfClubs]) {
        return [[self arrayMemberOfClubs] count];
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tableView == [self tableViewMyClubs]) {
        
        MyClubsTableViewCell *cell;
        
        static NSString *reuseIdentifier = @"MyClubsTableViewCell";
        cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
        
        if (!cell) {
            cell = [[MyClubsTableViewCell alloc] init];
        }
        
        if ([[[[self arrayMyClubs] objectAtIndex:indexPath.row] objectForKey:@"NoofMembers"] intValue] <= 10) {
            [[cell buttonLowMembership] setHidden:NO];
            [[cell buttonLowMembership] addTarget:self
                                           action:@selector(lowMembershipWarning)
                                 forControlEvents:UIControlEventTouchUpInside];
        } else {
            [[cell buttonLowMembership] setHidden:YES];
        }
        
        [[cell labelClubNameAndMembers] setText:[NSString stringWithFormat:@"%@    (%@)", [[[self arrayMyClubs] objectAtIndex:indexPath.row] objectForKey:@"PoolName"], [[[self arrayMyClubs] objectAtIndex:indexPath.row] objectForKey:@"NoofMembers"]]];
        
        if ([[self arrayMyClubsSelected] containsObject:[NSNumber numberWithInteger:indexPath.row]]) {
            [[cell buttonDeleteClub] setImage:[UIImage imageNamed:@"checkbox_checked.png"]
                                     forState:UIControlStateNormal];
        } else {
            [[cell buttonDeleteClub] setImage:[UIImage imageNamed:@"checkbox_unchecked.png"]
                                     forState:UIControlStateNormal];
        }
        [[cell buttonDeleteClub] setTag:indexPath.row];
        [[cell buttonDeleteClub] addTarget:self
                                    action:@selector(myClubSelected:)
                          forControlEvents:UIControlEventTouchUpInside];
        
        return cell;
    } else if (tableView == [self tableViewMemberOfClubs]) {
        
        MemberOfClubsTableViewCell *cell;
        
        static NSString *reuseIdentifier = @"MemberOfClubsTableViewCell";
        cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
        
        if (!cell) {
            cell = [[MemberOfClubsTableViewCell alloc] init];
        }
        
        if ([[[[self arrayMemberOfClubs] objectAtIndex:indexPath.row] objectForKey:@"NoofMembers"] intValue] <= 10) {
            [[cell buttonLowMembership] setHidden:NO];
            [[cell buttonLowMembership] addTarget:self
                                           action:@selector(lowMembershipWarning)
                                 forControlEvents:UIControlEventTouchUpInside];
        } else {
            [[cell buttonLowMembership] setHidden:YES];
        }
        
        [[cell labelClubNameAndMembers] setText:[NSString stringWithFormat:@"%@    (%@)", [[[self arrayMemberOfClubs] objectAtIndex:indexPath.row] objectForKey:@"PoolName"], [[[self arrayMemberOfClubs] objectAtIndex:indexPath.row] objectForKey:@"NoofMembers"]]];
        [[cell labelOwnerName] setText:[NSString stringWithFormat:@"(%@)", [[[self arrayMemberOfClubs] objectAtIndex:indexPath.row] objectForKey:@"OwnerName"]]];
        
        if ([[self arrayMemberOfClubsSelected] containsObject:[NSNumber numberWithInteger:indexPath.row]]) {
            [[cell buttonDeleteClub] setImage:[UIImage imageNamed:@"checkbox_checked.png"]
                                     forState:UIControlStateNormal];
        } else {
            [[cell buttonDeleteClub] setImage:[UIImage imageNamed:@"checkbox_unchecked.png"]
                                     forState:UIControlStateNormal];
        }
        [[cell buttonDeleteClub] setTag:indexPath.row];
        [[cell buttonDeleteClub] addTarget:self
                                    action:@selector(memberOfClubSelected:)
                          forControlEvents:UIControlEventTouchUpInside];
        
        return cell;
    }
    
    return nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGRect frameTableView = [tableView frame];
    return frameTableView.size.height / 4.0;
}

#pragma mark - IBAction methods

- (void)lowMembershipWarning {
    
    [[self toastLabel] removeFromSuperview];
    
    [self makeToastWithMessage:@"Low group membership - add/refer more members to improve chances of sharing"];
}

- (IBAction)myClubSelected:(id)sender {
    NSNumber *index = [NSNumber numberWithInteger:[sender tag]];
    
    if ([[self arrayMyClubsSelected] containsObject:index]) {
        [[self arrayMyClubsSelected] removeObject:index];
    } else {
        [[self arrayMyClubsSelected] addObject:index];
    }
    
    [[self tableViewMyClubs] reloadData];
}

- (IBAction)memberOfClubSelected:(id)sender {
    NSNumber *index = [NSNumber numberWithInteger:[sender tag]];
    
    if ([[self arrayMemberOfClubsSelected] containsObject:index]) {
        [[self arrayMemberOfClubsSelected] removeObject:index];
    } else {
        [[self arrayMemberOfClubsSelected] addObject:index];
    }
    
    [[self tableViewMemberOfClubs] reloadData];
}

- (IBAction)sendPressed:(UIButton *)sender {
    
    NSMutableArray *arraySelectedNumbers = [NSMutableArray array];
    NSMutableArray *arraySelectedNames = [NSMutableArray array];
    
    if ([[self arrayMyClubsSelected] count] > 0) {
        for (int i = 0; i < [[self arrayMyClubsSelected] count]; i++) {
            
            NSArray *members = [[[self arrayMyClubs] objectAtIndex:[[[self arrayMyClubsSelected] objectAtIndex:i] integerValue]] objectForKey:@"Members"];
            
            for (NSDictionary *memb in members) {
                NSString *selectedNumber = [memb objectForKey:@"MemberNumber"];
                NSString *selectedName = [memb objectForKey:@"FullName"];
                
//                [Logger logDebug:[self TAG]
//                         message:[NSString stringWithFormat:@" selectedNumber : %@ selectedName : %@", selectedNumber, selectedName]];
                
                if (![arraySelectedNumbers containsObject:selectedNumber]) {
                    [arraySelectedNumbers addObject:selectedNumber];
                    [arraySelectedNames addObject:selectedName];
                }
            }
        }
    }
    
    NSString *myNumber = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_DEFAULT_MOBILE];
    
    if ([[self arrayMemberOfClubsSelected] count] > 0) {
        for (int i = 0; i < [[self arrayMemberOfClubsSelected] count]; i++) {
            
            NSArray *members = [[[self arrayMemberOfClubs] objectAtIndex:[[[self arrayMemberOfClubsSelected] objectAtIndex:i] integerValue]] objectForKey:@"Members"];
            
            for (NSDictionary *memb in members) {
                NSString *selectedNumber = [memb objectForKey:@"MemberNumber"];
                NSString *selectedName = [memb objectForKey:@"FullName"];
                
//                [Logger logDebug:[self TAG]
//                         message:[NSString stringWithFormat:@" selectedNumber : %@ selectedName : %@", selectedNumber, selectedName]];
                
                if (![arraySelectedNumbers containsObject:selectedNumber] && ![selectedNumber isEqualToString:myNumber]) {
                    [arraySelectedNumbers addObject:selectedNumber];
                    [arraySelectedNames addObject:selectedName];
                }
            }
            
            NSString *selectedNumber = [[[self arrayMemberOfClubs] objectAtIndex:[[[self arrayMemberOfClubsSelected] objectAtIndex:i] integerValue]] objectForKey:@"OwnerNumber"];
            NSString *selectedName = [[[self arrayMemberOfClubs] objectAtIndex:[[[self arrayMemberOfClubsSelected] objectAtIndex:i] integerValue]] objectForKey:@"OwnerName"];
            
//            [Logger logDebug:[self TAG]
//                     message:[NSString stringWithFormat:@" OwnerNumber : %@ OwnerName : %@", selectedNumber, selectedName]];
            
            if (![arraySelectedNumbers containsObject:selectedNumber]) {
                [arraySelectedNumbers addObject:selectedNumber];
                [arraySelectedNames addObject:selectedName];
            }
        }
    }
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" arraySelectedNumbers : %@    arraySelectedNames : %@", [arraySelectedNumbers description], [arraySelectedNames description]]];
    
    NSString *numbersString = @"[";
    for (NSString *number in arraySelectedNumbers) {
        numbersString = [numbersString stringByAppendingString:[NSString stringWithFormat:@"%@, ", number]];
    }
    numbersString = [numbersString substringToIndex:([numbersString length] - 2)];
    numbersString = [numbersString stringByAppendingString:@"]"];
    
    NSString *namesString = @"[";
    for (NSString *name in arraySelectedNames) {
        namesString = [namesString stringByAppendingString:[NSString stringWithFormat:@"%@, ", name]];
    }
    namesString = [namesString substringToIndex:([namesString length] - 2)];
    namesString = [namesString stringByAppendingString:@"]"];
    
    [self setNumberString:numbersString];
    [self setNameString:namesString];
    
    if ([arraySelectedNumbers count] < [self numberOfSeats]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
                                                            message:[NSString stringWithFormat:@"You have %d seats to share and have selected only %lu friend(s)", [self numberOfSeats], [arraySelectedNumbers count]]
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Invite more", @"Continue Anyways", nil];
        [alertView show];
    } else {
        [self sendMembersToInvite];
    }
    
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:@"Invite more"]) {
        
    } else if ([buttonTitle isEqualToString:@"Continue Anyways"]) {
        [self sendMembersToInvite];
    }
}

#pragma mark - Private methods

- (void)sendMembersToInvite {
    [[self delegateClubsInviteVC] membersToInviteFrom:self
                                          withNumbers:[self numberString]
                                             andNames:[self nameString]];
    
    [self popVC];
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

- (void)popVC {
    [[self navigationController] popViewControllerAnimated:NO];
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
