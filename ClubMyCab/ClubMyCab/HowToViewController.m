//
//  HowToViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 11/09/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import "HowToViewController.h"
#import "SWRevealViewController.h"

@interface HowToViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textViewOne;
@property (weak, nonatomic) IBOutlet UITextView *textViewTwo;
@property (weak, nonatomic) IBOutlet UITextView *textViewThree;
@property (weak, nonatomic) IBOutlet UITextView *textViewFour;

@end

@implementation HowToViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    SWRevealViewController *revealViewController = [self revealViewController];
    if (revealViewController) {
        [[self barButtonItem] setTarget:revealViewController];
        [[self barButtonItem] setAction:@selector(revealToggle:)];
        [[self view] addGestureRecognizer:[[self revealViewController] panGestureRecognizer]];
    }
    
    [[self textViewOne] setText:@"1) iShareRyde makes ride sharing safe and convenient\r\n2) You can carpool or share a cab – allows you to share ride even if you don’t have a car\r\n3) Sharing a ride can reduce journey cost to as low as Rs. 2/km\r\n4) Sharing works best with people you trust – your colleagues, friends and friends of friends"];
    [[self textViewTwo] setText:@"1) Sharing with a group gives you flexibility to leave at different times and not have to wait.\r\n2) Bigger groups increase chances of ride sharing. Someone or other will be ready to leave at same time as you\r\n3) Keep groups focused to friends who travel same route as you\r\n4) Name your groups to show destinations. Or just choose a fun name\r\n5) Add a profile image - helps your friends identify you"];
    [[self textViewThree] setText:@"1) For your safety, we show only rides open in your groups\r\n2) If there is no ride in your groups that you can join, you can start one"];
    [[self textViewFour] setText:@"1) If it is a carpool, the person offering the ride asks for a per km rate. You can see this in ride details\r\n2) If you are sharing a cab, the cost will depend on bill\r\n3) Wallet to wallet transfer in the app is most convenient for paying"];
    
}

- (void)viewDidLayoutSubviews {
    [[self textViewOne] setContentOffset:CGPointZero
                                animated:NO];
    [[self textViewTwo] setContentOffset:CGPointZero
                                animated:NO];
    [[self textViewThree] setContentOffset:CGPointZero
                                animated:NO];
    [[self textViewFour] setContentOffset:CGPointZero
                                animated:NO];
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
