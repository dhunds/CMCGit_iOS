//
//  ClubDetailsViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 09/10/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import "ClubDetailsViewController.h"

@interface ClubDetailsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *labelClubName;
@property (weak, nonatomic) IBOutlet UITableView *tableViewMembers;
@property (weak, nonatomic) IBOutlet UIButton *buttonAddReferFriends;

@end

@implementation ClubDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[self labelClubName] setText:[[self dictionaryClubDetails] objectForKey:@"PoolName"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
