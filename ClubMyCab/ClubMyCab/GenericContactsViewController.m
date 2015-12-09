//
//  GenericContactsViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 09/10/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import "GenericContactsViewController.h"
#import "GlobalMethods.h"
#import "Logger.h"
#import "ActivityIndicatorView.h"
#import "ToastLabel.h"
#import "ContactsTableViewCell.h"
#import "ClubDetailsViewController.h"

@import AddressBook;

@interface GenericContactsViewController () <UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, GlobalMethodsAsyncRequestProtocol>

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (weak, nonatomic) IBOutlet UITableView *tableViewContacts;
@property (weak, nonatomic) IBOutlet UITextField *textFieldSearch;
@property (weak, nonatomic) IBOutlet UITextField *textFieldClubName;
@property (weak, nonatomic) IBOutlet UILabel *labelClubName;

@property (strong, nonatomic) NSArray *arrayContacts;
@property (strong, nonatomic) NSArray *arrayContactsFiltered;

@property (strong, nonatomic) NSString *ownerMobileNumber, *ownerName;

@end

@implementation GenericContactsViewController

#define KEY_DICT_NAME                                       @"KeyDictName"
#define KEY_DICT_PHONE                                      @"KeyDictPhone"
#define KEY_DICT_IMAGE                                      @"KeyDictImage"
#define KEY_DICT_SELECTED                                   @"KeyDictSelected"
#define VALUE_DICT_SELECTED_YES                             @"ValueDictSelectedYes"
#define VALUE_DICT_SELECTED_NO                              @"ValueDictSelectedNo"

- (NSString *)TAG {
    return @"GenericContactsViewController";
}

#pragma mark - View Controller Life Cycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [self setOwnerMobileNumber:[userDefaults objectForKey:KEY_USER_DEFAULT_MOBILE]];
    [self setOwnerName:[userDefaults objectForKey:KEY_USER_DEFAULT_NAME]];
    
    [[self textFieldSearch] addTarget:self
                               action:@selector(textFieldEditing:)
                     forControlEvents:UIControlEventEditingChanged];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
//    [Logger logDebug:[self TAG]
//             message:[NSString stringWithFormat:@" viewDidAppear : %ld", ABAddressBookGetAuthorizationStatus()]];
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied || ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusRestricted) {
        [self askForAddressBookAccess];
    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        [self getContactsArray];
    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        [self askForAddressBookAccess];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:@"Cancel"]) {
        [self popVC];
    } else if ([buttonTitle isEqualToString:@"Settings"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Private methods

- (void)askForAddressBookAccess {
    ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil), ^(bool granted, CFErrorRef error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                [self getContactsArray];
            } else {
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Access needed"
                                                                    message:@"ClubMyCab cannot add your friend(s) to clubs without access to your Address Book. Please provide access to your contacts in Settings."
                                                                   delegate:self
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"Cancel", @"Settings", nil];
                [alertView show];
                
            }
        });
    });
}

- (void)getContactsArray {
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, nil);
    NSArray *contacts = (__bridge NSArray*) ABAddressBookCopyArrayOfAllPeople(addressBookRef);
    
    [self setArrayContacts:[NSArray array]];
    NSMutableArray *mutableArrayContacts = [NSMutableArray array];
    
    for (id person in contacts) {
        
        ABRecordRef record = (__bridge ABRecordRef)person;
        
        UIImage *image;
        if (ABPersonHasImageData(record)) {
            image = [UIImage imageWithData:(__bridge NSData *)ABPersonCopyImageData(record)];
        } else {
            image = nil;
        }
        
        ABMultiValueRef phoneRef = ABRecordCopyValue(record, kABPersonPhoneProperty);
        
        for (int i = 0; i < ABMultiValueGetCount(phoneRef); i++) {
//            [Logger logDebug:[self TAG]
//                     message:[NSString stringWithFormat:@" getContactsArray : %@ , %@ , %@", ABRecordCopyCompositeName(record), ABMultiValueCopyLabelAtIndex(phoneRef, i), ABMultiValueCopyValueAtIndex(phoneRef, i)]];
            
            CFStringRef labelAtIndex = ABMultiValueCopyLabelAtIndex(phoneRef, i);
            NSString *valueAtIndex = (__bridge NSString *)ABMultiValueCopyValueAtIndex(phoneRef, i);
            
            if ((CFStringFind(labelAtIndex, CFSTR("mobile"), kCFCompareCaseInsensitive).location != kCFNotFound) || (CFStringFind(labelAtIndex, CFSTR("phone"), kCFCompareCaseInsensitive).location != kCFNotFound) || (CFStringFind(labelAtIndex, CFSTR("main"), kCFCompareCaseInsensitive).location != kCFNotFound) || (CFStringFind(labelAtIndex, CFSTR("home"), kCFCompareCaseInsensitive).location != kCFNotFound) || (CFStringFind(labelAtIndex, CFSTR("work"), kCFCompareCaseInsensitive).location != kCFNotFound)) {
                
                NSString *number = [self formatPhoneNumber:valueAtIndex];
                if (number) {
                    [mutableArrayContacts addObject:[self createContactDictionaryWithName:(__bridge NSString *)ABRecordCopyCompositeName(record)
                                                                                   number:number
                                                                               isSelected:VALUE_DICT_SELECTED_NO
                                                                                userImage:image]];
                    
                    break;
                }
            } else {
                NSString *number = [self formatPhoneNumber:valueAtIndex];
                if (number) {
                    [mutableArrayContacts addObject:[self createContactDictionaryWithName:(__bridge NSString *)ABRecordCopyCompositeName(record)
                                                                                   number:number
                                                                               isSelected:VALUE_DICT_SELECTED_NO
                                                                                userImage:image]];
                    
                    break;
                }
            }
        }
    }
    
    [self setArrayContacts:[mutableArrayContacts copy]];
    [self setArrayContactsFiltered:[self arrayContacts]];
    
    [[self tableViewContacts] reloadData];
    
//    [Logger logDebug:[self TAG]
//             message:[NSString stringWithFormat:@"%@, %@, %@, %@, %@, %@, %@, %@", kABPersonPhoneMobileLabel, kABPersonPhoneMainLabel, kABPersonPhoneIPhoneLabel, kABPersonPhoneMainLabel, kABPersonPhoneHomeFAXLabel, kABPersonPhoneWorkFAXLabel, kABPersonPhoneOtherFAXLabel, kABPersonPhonePagerLabel]];
    
}

- (NSString *)formatPhoneNumber:(NSString *)phone {
    
    phone = [phone stringByReplacingOccurrencesOfString:@"+"
                                             withString:@""];
    phone = [phone stringByReplacingOccurrencesOfString:@"-"
                                             withString:@""];
    phone = [phone stringByReplacingOccurrencesOfString:@" "
                                             withString:@""];
    phone = [phone stringByReplacingOccurrencesOfString:@"("
                                             withString:@""];
    phone = [phone stringByReplacingOccurrencesOfString:@")"
                                             withString:@""];
    
    NSString *formatted = nil;
    
    if ([phone length] >= 10) {
        if ([phone length] > 10) {
            formatted = [phone substringFromIndex:([phone length] - 10)];
        } else {
            formatted = phone;
        }
    }
    return formatted;
}

- (NSMutableDictionary *)createContactDictionaryWithName:(NSString *)name
                                                  number:(NSString *)phone
                                              isSelected:(NSString *)select
                                               userImage:(UIImage *)image {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:name
                   forKey:KEY_DICT_NAME];
    [dictionary setObject:phone
                   forKey:KEY_DICT_PHONE];
    [dictionary setObject:select
                   forKey:KEY_DICT_SELECTED];
    if (image) {
        [dictionary setObject:image
                       forKey:KEY_DICT_IMAGE];
    } else {
        [dictionary setObject:@""
                       forKey:KEY_DICT_IMAGE];
    }
    
    return dictionary;
}

- (void)makeToastWithMessage:(NSString *)message {
    
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

- (NSString *)generateSelectedMemberNamesString:(NSArray *)selectionArray {
    NSString *memberNames = @"[";
    
    for (int i = 0; i < ([selectionArray count] - 1); i++) {
        memberNames = [memberNames stringByAppendingString:[NSString stringWithFormat:@"%@, ", [[selectionArray objectAtIndex:i] objectForKey:KEY_DICT_NAME]]];
    }
    memberNames = [memberNames stringByAppendingString:[NSString stringWithFormat:@"%@]", [[selectionArray lastObject] objectForKey:KEY_DICT_NAME]]];
    
    return memberNames;
}

- (NSString *)generateSelectedMemberNumbersString:(NSArray *)selectionArray {
    NSString *memberNumbers = @"[";
    
    for (int i = 0; i < ([selectionArray count] - 1); i++) {
        memberNumbers = [memberNumbers stringByAppendingString:[NSString stringWithFormat:@"0091%@, ", [[selectionArray objectAtIndex:i] objectForKey:KEY_DICT_PHONE]]];
    }
    memberNumbers = [memberNumbers stringByAppendingString:[NSString stringWithFormat:@"0091%@]", [[selectionArray lastObject] objectForKey:KEY_DICT_PHONE]]];
    
    return memberNumbers;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return [[self arrayContactsFiltered] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ContactsTableViewCell *cell;
    static NSString *reuseIdentifier = @"ContactsTableViewCell";
    cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (!cell) {
        cell = [[ContactsTableViewCell alloc] init];
    }
    
    //    [Logger logDebug:[self TAG]
    //             message:[NSString stringWithFormat:@" cellForRowAtIndexPath : %@", [indexPath description]]];
    
    [[cell labelName] setText:[[[self arrayContactsFiltered] objectAtIndex:indexPath.row] objectForKey:KEY_DICT_NAME]];
    [[cell labelNumber] setText:[[[self arrayContactsFiltered] objectAtIndex:indexPath.row] objectForKey:KEY_DICT_PHONE]];
    
    NSMutableDictionary *dict = [[self arrayContactsFiltered] objectAtIndex:indexPath.row];
    if ([[dict objectForKey:KEY_DICT_SELECTED] isEqualToString:VALUE_DICT_SELECTED_YES]) {
        [[cell buttonSelected] setImage:[UIImage imageNamed:@"checkbox_checked.png"]
                               forState:UIControlStateNormal];
    } else {
        [[cell buttonSelected] setImage:[UIImage imageNamed:@"checkbox_unchecked.png"]
                               forState:UIControlStateNormal];
    }
    [[cell buttonSelected] setTag:indexPath.row];
    [[cell buttonSelected] addTarget:self
                              action:@selector(selectContactPressed:)
                    forControlEvents:UIControlEventTouchUpInside];
    
    id image = [dict objectForKey:KEY_DICT_IMAGE];
    if ([image isKindOfClass:[UIImage class]]) {
        
        [[cell imageViewImage] setContentMode:UIViewContentModeScaleAspectFit];
        [[cell imageViewImage] setClipsToBounds:YES];
        [[cell imageViewImage] setFrame:CGRectMake(28.0, 25.0, 50.0, 50.0)];
        [[cell imageViewImage] setImage:image];
        
    } else {
        [[cell imageViewImage] setImage:[UIImage imageNamed:@"contact_image_icon.png"]];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGRect frameTableView = [[self tableViewContacts] frame];
    return frameTableView.size.height / 6.0;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:NO];
}

#pragma mark - IBAction methods

- (IBAction)selectContactPressed:(id)sender {
    
    if ([[[[self arrayContactsFiltered] objectAtIndex:[sender tag]] objectForKey:KEY_DICT_SELECTED] isEqualToString:VALUE_DICT_SELECTED_NO]) {
        [[[self arrayContactsFiltered] objectAtIndex:[sender tag]] setObject:VALUE_DICT_SELECTED_YES
                                                              forKey:KEY_DICT_SELECTED];
    } else {
        [[[self arrayContactsFiltered] objectAtIndex:[sender tag]] setObject:VALUE_DICT_SELECTED_NO
                                                              forKey:KEY_DICT_SELECTED];
    }
    
    [[self tableViewContacts] reloadData];
    
}

- (IBAction)textFieldEditing:(id)sender {
    NSString *searchString = [(UITextField *)sender text];
    
    if ([searchString length] > 0) {
        [self setArrayContactsFiltered:[[self arrayContacts] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(KeyDictName CONTAINS[cd] %@)", searchString]]];
    } else {
        [self setArrayContactsFiltered:[self arrayContacts]];
    }
    
//    [Logger logDebug:[self TAG]
//             message:[NSString stringWithFormat:@" shouldChangeCharactersInRange : %@ filtered : %@", searchString, [[self arrayContactsFiltered] description]]];
    
    [[self tableViewContacts] reloadData];
}

- (IBAction)createClubPressed:(UIButton *)sender {
    
    if ([[self segueType] isEqualToString:SEGUE_FROM_CREATE_CLUB]) {
        NSString *clubName = [[self textFieldClubName] text];
        
        if ([clubName length] <= 0) {
            [self makeToastWithMessage:@"Please enter the club name"];
        } else {
            NSArray *selectionArray = [[self arrayContacts] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(KeyDictSelected CONTAINS[cd] %@)", @"ValueDictSelectedYes"]];
            [Logger logDebug:[self TAG]
                     message:[NSString stringWithFormat:@" createClubPressed : %@", [selectionArray description]]];
            if ([selectionArray count] <= 0) {
                [self makeToastWithMessage:@"Please select contact(s) to create club"];
            } else {
                [self showActivityIndicatorView];
                
                NSString *memberNames = [self generateSelectedMemberNamesString:selectionArray];
                NSString *memberNumbers = [self generateSelectedMemberNumbersString:selectionArray];
                
                GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
                [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                                   endPoint:ENDPOINT_STORE_CLUB
                                                                 parameters:[NSString stringWithFormat:@"OwnerName=%@&OwnerNumber=%@&ClubName=%@&ClubMembersName=%@&ClubMembersNumber=%@&", [self ownerName], [self ownerMobileNumber], clubName, memberNames, memberNumbers]
                                                        delegateForProtocol:self];
            }
        }
    } else if ([[self segueType] isEqualToString:SEGUE_FROM_ADD_MEMBERS]) {
        NSArray *selectionArray = [[self arrayContacts] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(KeyDictSelected CONTAINS[cd] %@)", @"ValueDictSelectedYes"]];
        if ([selectionArray count] <= 0) {
            [self makeToastWithMessage:@"Please select contact(s) to add"];
        } else {
            [self showActivityIndicatorView];
            
            NSString *memberNames = [self generateSelectedMemberNamesString:selectionArray];
            NSString *memberNumbers = [self generateSelectedMemberNumbersString:selectionArray];
            
            GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
            [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                               endPoint:ENDPOINT_ADD_USERS_CLUB
                                                             parameters:[NSString stringWithFormat:@"poolid=%@&ClubMembersName=%@&ClubMembersNumber=%@", [[self dictionaryClubDetails] objectForKey:@"PoolId"], memberNames, memberNumbers]
                                                    delegateForProtocol:self];
        }
    } else if ([[self segueType] isEqualToString:SEGUE_FROM_REFER_MEMBERS]) {
        NSArray *selectionArray = [[self arrayContacts] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(KeyDictSelected CONTAINS[cd] %@)", @"ValueDictSelectedYes"]];
        if ([selectionArray count] <= 0) {
            [self makeToastWithMessage:@"Please select contact(s) to refer"];
        } else {
            [self showActivityIndicatorView];
            
            NSString *memberNames = [self generateSelectedMemberNamesString:selectionArray];
            NSString *memberNumbers = [self generateSelectedMemberNumbersString:selectionArray];
            
            GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
            [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                               endPoint:ENDPOINT_REFER_USERS_CLUB
                                                             parameters:[NSString stringWithFormat:@"ClubId=%@&MemberName=%@&MemberNumber=%@&ReferedUserName=%@&ReferedUserNumber=%@", [[self dictionaryClubDetails] objectForKey:@"PoolId"], [[self dictionaryClubDetails] objectForKey:@"OwnerName"], [[self dictionaryClubDetails] objectForKey:@"OwnerNumber"], memberNames, memberNumbers]
                                                    delegateForProtocol:self];
        }
    } else if ([[self segueType] isEqualToString:SEGUE_FROM_RIDE_INVITATION] || [[self segueType] isEqualToString:SEGUE_FROM_OWNER_RIDE_INVITATION]) {
        NSArray *selectionArray = [[self arrayContacts] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(KeyDictSelected CONTAINS[cd] %@)", @"ValueDictSelectedYes"]];
        if ([selectionArray count] <= 0) {
            [self makeToastWithMessage:@"Please select contact(s) to invite"];
        } else {
            NSString *memberNames = [self generateSelectedMemberNamesString:selectionArray];
            NSString *memberNumbers = [self generateSelectedMemberNumbersString:selectionArray];
            
            [[self delegateGenericContactsVC] contactsToInviteFrom:self
                                                       withNumbers:memberNumbers
                                                          andNames:memberNames];
            
            [self popVC];
        }
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
            if ([endPoint isEqualToString:ENDPOINT_STORE_CLUB] || [endPoint isEqualToString:ENDPOINT_REFER_USERS_CLUB]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                
                [self makeToastWithMessage:response];
                
                if([response rangeOfString:@"SUCCESS"].location != NSNotFound) {
                    [self performSelector:@selector(popVC)
                               withObject:self
                               afterDelay:1.5];
                }
            } else if ([endPoint isEqualToString:ENDPOINT_ADD_USERS_CLUB]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                
                if([response rangeOfString:@"SUCCESS"].location != NSNotFound) {
                    [self showActivityIndicatorView];
                    
                    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
                    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                                       endPoint:ENDPOINT_FETCH_CLUBS
                                                                     parameters:[NSString stringWithFormat:@"OwnerNumber=%@", [self ownerMobileNumber]]
                                                            delegateForProtocol:self];
                }
            } else if ([endPoint isEqualToString:ENDPOINT_FETCH_CLUBS]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                if (response && [response caseInsensitiveCompare:@"No Users of your Club"] == NSOrderedSame) {
                    [self makeToastWithMessage:@"No clubs created yet!!"];
                } else {
                    NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                    NSError *error = nil;
                    NSArray *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                          options:NSJSONReadingMutableContainers
                                                                            error:&error];
                    if (!error) {
                        BOOL success = NO;
                        id viewController = [[[self navigationController] viewControllers] objectAtIndex:([[[self navigationController] viewControllers] count] - 2)];
                        for (int i = 0; i < [parsedJson count]; i++) {
                            if ([[[parsedJson objectAtIndex:i] objectForKey:@"IsPoolOwner"] isEqualToString:@"1"]) {
                                
                                if ([[[parsedJson objectAtIndex:i] objectForKey:@"PoolId"] isEqualToString:[[self dictionaryClubDetails] objectForKey:@"PoolId"]]) {
                                    if ([viewController isKindOfClass:[ClubDetailsViewController class]]) {
                                        [(ClubDetailsViewController *)viewController setDictionaryClubDetails:[parsedJson objectAtIndex:i]];
                                        success = YES;
                                        break;
                                    }
                                }
                            }
                        }
                        if (success) {
                            [self popVC];
                        }
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

@end
