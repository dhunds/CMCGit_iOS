//
//  ClubDetailsViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 09/10/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import "ClubDetailsViewController.h"
#import "Logger.h"
#import "ActivityIndicatorView.h"
#import "ToastLabel.h"
#import "ClubDetailsTableViewCell.h"
#import "GlobalMethods.h"
#import "GenericContactsViewController.h"

@interface ClubDetailsViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (weak, nonatomic) IBOutlet UILabel *labelClubName;
@property (weak, nonatomic) IBOutlet UITableView *tableViewMembers;
@property (weak, nonatomic) IBOutlet UIButton *buttonAddReferFriends;

@property (strong, nonatomic) NSArray *arrayMembers;

@property (nonatomic) NSUInteger deleteUserIndex;

@property (strong, nonatomic) NSMutableDictionary *dictionaryProfileImages;

@end

@implementation ClubDetailsViewController

- (NSString *)TAG {
    return @"ClubDetailsViewController";
}

- (NSMutableDictionary *)dictionaryProfileImages {
    if (!_dictionaryProfileImages) {
        _dictionaryProfileImages = [NSMutableDictionary dictionary];
    }
    
    return _dictionaryProfileImages;
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([[self segueType] isEqualToString:MY_CLUBS_SEGUE]) {
        [[self buttonAddReferFriends] setTitle:@"Add More Members"
                                      forState:UIControlStateNormal];
    } else if ([[self segueType] isEqualToString:MEMBER_OF_CLUBS_SEGUE]) {
        [[self buttonAddReferFriends] setTitle:@"Refer More Members"
                                      forState:UIControlStateNormal];
    }
    
    [[self labelClubName] setText:[[self dictionaryClubDetails] objectForKey:@"PoolName"]];
    
    [self setArrayMembers:[[self dictionaryClubDetails] objectForKey:@"Members"]];
    
    [[self tableViewMembers] reloadData];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self arrayMembers] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ClubDetailsTableViewCell *cell;
    
    static NSString *reuseIdentifier = @"ClubDetailsTableViewCell";
    cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (!cell) {
        cell = [[ClubDetailsTableViewCell alloc] init];
    }
    
    [[cell labelName] setText:[[[self arrayMembers] objectAtIndex:indexPath.row] objectForKey:@"FullName"]];
    
    CGRect frame = [[cell imageViewImage] frame];
    [[[cell imageViewImage] layer] setCornerRadius:(frame.size.width / 2.0f)];
    [[cell imageViewImage] setClipsToBounds:YES];
    
    NSString *imageName = [[[self arrayMembers] objectAtIndex:indexPath.row] objectForKey:@"ImageName"];
    if (!imageName || [imageName length] <= 0) {
        [[cell imageViewImage] setImage:[UIImage imageNamed:@"contact_appicon.png"]];
    } else {
        if ([[self dictionaryProfileImages] objectForKey:imageName]) {
            [[cell imageViewImage] setImage:[[self dictionaryProfileImages] objectForKey:imageName]];
        } else {
            [[cell imageViewImage] setImage:[UIImage imageNamed:@"contact_appicon.png"]];
            
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/ProfileImages/%@", SERVER_ADDRESS, imageName]];
            NSURLSessionTask *sessionTask = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                            if (data) {
                                                                                UIImage *image = [UIImage imageWithData:data];
                                                                                if (image) {
                                                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                                                        ClubDetailsTableViewCell *imageCell = [[self tableViewMembers] cellForRowAtIndexPath:indexPath];
                                                                                        if (imageCell) {
                                                                                            CGRect frame = [[imageCell imageViewImage] frame];
                                                                                            UIImage *scaledImage = [self scaleImage:image
                                                                                                                             toSize:CGSizeMake(frame.size.width, frame.size.height)];
                                                                                            
                                                                                            [[imageCell imageViewImage] setImage:scaledImage];
                                                                                            [[self dictionaryProfileImages] setObject:scaledImage
                                                                                                                               forKey:imageName];
                                                                                        }
                                                                                    });
                                                                                }
                                                                            }
                                                                        }];
            [sessionTask resume];
        }
    }
    
    if ([[self segueType] isEqualToString:MY_CLUBS_SEGUE]) {
        [[cell buttonDelete] setTag:indexPath.row];
        [[cell buttonDelete] addTarget:self
                                action:@selector(removeUserPressed:)
                      forControlEvents:UIControlEventTouchUpInside];
    } else {
        [[cell buttonDelete] setHidden:YES];
    }
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGRect frameTableView = [tableView frame];
    return frameTableView.size.height / 6.0;
}

#pragma  mark - IBAction methods

- (IBAction)removeUserPressed:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Delete User"
                                                        message:[NSString stringWithFormat:@"Are you sure you want to delete %@ from this group?", [[[self arrayMembers] objectAtIndex:[sender tag]] objectForKey:@"FullName"]]
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Yes", @"No", nil];
    [alertView setTag:[sender tag]];
    [alertView show];
}

- (IBAction)addReferButtonPressed:(UIButton *)sender {
    
    [self performSegueWithIdentifier:@"AddReferContactsSegue"
                              sender:self];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([[segue identifier] isEqualToString:@"AddReferContactsSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[GenericContactsViewController class]]) {
            [(GenericContactsViewController *)[segue destinationViewController] setDictionaryClubDetails:[self dictionaryClubDetails]];
            if ([[self segueType] isEqualToString:MY_CLUBS_SEGUE]) {
                [(GenericContactsViewController *)[segue destinationViewController] setSegueType:SEGUE_FROM_ADD_MEMBERS];
            } else if ([[self segueType] isEqualToString:MEMBER_OF_CLUBS_SEGUE]) {
                [(GenericContactsViewController *)[segue destinationViewController] setSegueType:SEGUE_FROM_REFER_MEMBERS];
            }
        }
    }
}


#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:@"Yes"]) {
        [self showActivityIndicatorView];
        
        [self setDeleteUserIndex:[alertView tag]];
        
        GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
        [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                           endPoint:ENDPOINT_REMOVE_USER_CLUB
                                                         parameters:[NSString stringWithFormat:@"poolid=%@&usernumber=%@", [[self dictionaryClubDetails] objectForKey:@"PoolId"], [[[self arrayMembers] objectAtIndex:[alertView tag]] objectForKey:@"MemberNumber"]]
                                                delegateForProtocol:self];
    }
    //    else if ([buttonTitle isEqualToString:@"No"]) {
    //
    //    }
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
            if ([endPoint isEqualToString:ENDPOINT_REMOVE_USER_CLUB]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                if (response && [response caseInsensitiveCompare:@"SUCCESS"] == NSOrderedSame) {
                    NSMutableArray *array = [[self arrayMembers] mutableCopy];
                    [array removeObjectAtIndex:[self deleteUserIndex]];
                    
                    [self setArrayMembers:[array copy]];
                    [[self tableViewMembers] reloadData];
                } else {
                    [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                }
            }
        }
    });
}

#pragma mark - Private methods

- (UIImage *)scaleImage:(UIImage *)originalImage
                 toSize:(CGSize)newSize {
    if (CGSizeEqualToSize([originalImage size], newSize)) {
        return originalImage;
    }
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0f);
    [originalImage drawInRect:CGRectMake(0.0f, 0.0f, newSize.width, newSize.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
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

@end
