//
//  OfferDetailsViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 02/01/16.
//  Copyright © 2016 ClubMyCab. All rights reserved.
//

#import "OfferDetailsViewController.h"

@interface OfferDetailsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *labelOfferTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelOfferDescription;
@property (weak, nonatomic) IBOutlet UILabel *labelOfferStatus;
@property (weak, nonatomic) IBOutlet UILabel *labelOfferStatusDescription;
@property (weak, nonatomic) IBOutlet UIButton *buttonInviteFriends;

@end

@implementation OfferDetailsViewController

#pragma mark - View Controller Life Cycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[self labelOfferTitle] setText:[[self dictionaryOffer] objectForKey:@"title"]];
    if ([[[[self dictionaryOffer] objectForKey:@"type"] lowercaseString] rangeOfString:@"referral"].location != NSNotFound) {
        [[self labelOfferDescription] setText:[NSString stringWithFormat:@"%@ Your referral code : %@",[[self dictionaryOffer] objectForKey:@"description"], [[self dictionaryUserData] objectForKey:@"referralCode"]]];
        [[self buttonInviteFriends] setHidden:NO];
    } else {
        [[self labelOfferDescription] setText:[[self dictionaryOffer] objectForKey:@"description"]];
        [[self buttonInviteFriends] setHidden:YES];
    }
    [[self labelOfferStatusDescription] setText:[[self dictionaryOffer] objectForKey:@"UserOfferStatus"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBAction methods

- (IBAction)inviteFriendsPressed:(UIButton *)sender {
    
    NSString *content = @"";
    
    if ([[[self dictionaryOffer] objectForKey:@"useCount"] doubleValue] >= [[[self dictionaryOffer] objectForKey:@"maxUsePerUser"] doubleValue]) {
        content = [NSString stringWithFormat:@"I am using this cool app 'iShareRyde' to share rides. Check it out @ %@", SHARE_THIS_APP];
    } else {
        content = [NSString stringWithFormat:@"I am using this cool app 'iShareRyde' to share rides. Check it out @ %@ . Use my referral code %@ and earn credits worth Rs.%@", SHARE_THIS_APP, [[self dictionaryUserData] objectForKey:@"referralCode"], [[self dictionaryOffer] objectForKey:@"amount"]];
    }
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:[NSArray arrayWithObject:content]
                                                                                         applicationActivities:nil];
    
    [activityViewController setExcludedActivityTypes:[NSArray arrayWithObjects:UIActivityTypeAddToReadingList, UIActivityTypeAssignToContact, UIActivityTypeOpenInIBooks, UIActivityTypePostToFlickr, UIActivityTypePostToTencentWeibo, UIActivityTypePostToVimeo, UIActivityTypePostToWeibo, UIActivityTypePrint, UIActivityTypeSaveToCameraRoll, nil]];
    
    [self presentViewController:activityViewController
                       animated:YES
                     completion:^{
                         
                     }];
    
//    UIActivityTypePostToFacebook
//    UIActivityTypePostToTwitter
//    UIActivityTypePostToWeibo
//    UIActivityTypeMessage
//    UIActivityTypeMail
//    UIActivityTypePrint
//    UIActivityTypeCopyToPasteboard
//    UIActivityTypeAssignToContact
//    UIActivityTypeSaveToCameraRoll
//    UIActivityTypeAddToReadingList
//    UIActivityTypePostToFlickr
//    UIActivityTypePostToVimeo
//    UIActivityTypePostToTencentWeibo
//    UIActivityTypeAirDrop
}

- (IBAction)termsAndConditionsPressed:(UIButton *)sender {
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Terms & Conditions"
                                                        message:[[self dictionaryOffer] objectForKey:@"terms"]
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
    [alertView show];
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
