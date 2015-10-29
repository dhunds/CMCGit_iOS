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

@import AddressBook;

@interface GenericContactsViewController () <UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (weak, nonatomic) IBOutlet UITableView *tableViewContacts;


@property (strong, nonatomic) NSArray *arrayContacts;

@end

@implementation GenericContactsViewController

#define KEY_DICT_NAME                                       @"KeyDictName"
#define KEY_DICT_PHONE                                      @"KeyDictPhone"
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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" viewDidAppear : %ld", ABAddressBookGetAuthorizationStatus()]];
    
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
    
    if ([buttonTitle isEqualToString:@"Ok"]) {
        [[self navigationController] popViewControllerAnimated:YES];
    }
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
                                                          otherButtonTitles:@"Ok", nil];
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
        ABMultiValueRef phoneRef = ABRecordCopyValue(record, kABPersonPhoneProperty);
        
        for (int i = 0; i < ABMultiValueGetCount(phoneRef); i++) {
            [Logger logDebug:[self TAG]
                     message:[NSString stringWithFormat:@" getContactsArray : %@ , %@ , %@", ABRecordCopyCompositeName(record), ABMultiValueCopyLabelAtIndex(phoneRef, i), ABMultiValueCopyValueAtIndex(phoneRef, i)]];
            
            CFStringRef labelAtIndex = ABMultiValueCopyLabelAtIndex(phoneRef, i);
            NSString *valueAtIndex = (__bridge NSString *)ABMultiValueCopyValueAtIndex(phoneRef, i);
            
            if ((CFStringFind(labelAtIndex, CFSTR("mobile"), kCFCompareCaseInsensitive).location != kCFNotFound) || (CFStringFind(labelAtIndex, CFSTR("phone"), kCFCompareCaseInsensitive).location != kCFNotFound) || (CFStringFind(labelAtIndex, CFSTR("main"), kCFCompareCaseInsensitive).location != kCFNotFound) || (CFStringFind(labelAtIndex, CFSTR("home"), kCFCompareCaseInsensitive).location != kCFNotFound) || (CFStringFind(labelAtIndex, CFSTR("work"), kCFCompareCaseInsensitive).location != kCFNotFound)) {
                
                NSString *number = [self formatPhoneNumber:valueAtIndex];
                if (number) {
                    [mutableArrayContacts addObject:[self createContactDictionaryWithName:(__bridge NSString *)ABRecordCopyCompositeName(record)
                                                                                   number:number
                                                                               isSelected:VALUE_DICT_SELECTED_NO]];
                    
                    break;
                }
            } else {
                NSString *number = [self formatPhoneNumber:valueAtIndex];
                if (number) {
                    [mutableArrayContacts addObject:[self createContactDictionaryWithName:(__bridge NSString *)ABRecordCopyCompositeName(record)
                                                                                   number:number
                                                                               isSelected:VALUE_DICT_SELECTED_NO]];
                    
                    break;
                }
            }
        }
    }
    
    [self setArrayContacts:[mutableArrayContacts copy]];
    
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
                                          isSelected:(NSString *)select {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:name
                   forKey:KEY_DICT_NAME];
    [dictionary setObject:phone
                   forKey:KEY_DICT_PHONE];
    [dictionary setObject:select
                   forKey:KEY_DICT_SELECTED];
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
    return [[self arrayContacts] count];
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
    
    [[cell labelName] setText:[[[self arrayContacts] objectAtIndex:indexPath.row] objectForKey:KEY_DICT_NAME]];
    [[cell labelNumber] setText:[[[self arrayContacts] objectAtIndex:indexPath.row] objectForKey:KEY_DICT_PHONE]];
    
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

@end
