//
//  FavoriteLocationsViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 17/11/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import "FavoriteLocationsViewController.h"
#import "Logger.h"
#import "ActivityIndicatorView.h"
#import "ToastLabel.h"
#import "FavoriteLocationsTableViewCell.h"
#import "GenericLocationPickerViewController.h"
#import "PlacesAutoCompleteViewController.h"

@interface FavoriteLocationsViewController () <UITextFieldDelegate, GenericLocationPickerVCProtocol, PlacesAutoCompleteVCProtocol, UIAlertViewDelegate>

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) NSArray *arrayFavoriteLocations;
@property (strong, nonatomic) NSDictionary *dictionaryFavoriteLocations;

@property (weak, nonatomic) IBOutlet UITableView *tableViewFavoriteLocations;
@property (weak, nonatomic) IBOutlet UIButton *buttonAddMore;

@end

@implementation FavoriteLocationsViewController

#define MAX_FAVORITES                   5

- (NSString *)TAG {
    return @"FavoriteLocationsViewController";
}

- (NSArray *)arrayFavoriteLocations {
    if (!_arrayFavoriteLocations) {
        _arrayFavoriteLocations = [NSArray array];
    }
    
    return _arrayFavoriteLocations;
}

- (NSDictionary *)dictionaryFavoriteLocations {
    if (!_dictionaryFavoriteLocations) {
        _dictionaryFavoriteLocations = [NSDictionary dictionary];
    }
    
    return _dictionaryFavoriteLocations;
}

#pragma mark - View Controller Life Cycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self readFavoriteLocationsJSONFromFile];
    
    [[self tableViewFavoriteLocations] reloadData];
    
    [self updateButtonTitle];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBAction methods

- (IBAction)addMorePressed:(UIButton *)sender {
    AddressModel *home = [[self dictionaryFavoriteLocations] objectForKey:FAVORITE_LOCATIONS_TAG_VALUE_HOME];
    AddressModel *office = [[self dictionaryFavoriteLocations] objectForKey:FAVORITE_LOCATIONS_TAG_VALUE_OFFICE];
    
    if (!home || !office) {
        [self makeToastWithMessage:@"Please enter both Home & Office addresses first!"];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Location name"
                                                            message:@"What do you want to call this location? e.g. Airport, MyAdda"
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Ok", @"Cancel", nil];
        [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [alertView show];
    }
}

- (IBAction)cancelPressed:(UIButton *)sender {
    [self popVC];
}

- (IBAction)savePressed:(UIButton *)sender {
    
    if ([[self dictionaryFavoriteLocations] count] <= 0 || ![[self dictionaryFavoriteLocations] objectForKey:FAVORITE_LOCATIONS_TAG_VALUE_HOME] || ![[self dictionaryFavoriteLocations] objectForKey:FAVORITE_LOCATIONS_TAG_VALUE_OFFICE]) {
        [self makeToastWithMessage:@"Please enter both Home & Office addresses first!"];
    } else {
        [Logger logDebug:[self TAG]
                 message:[NSString stringWithFormat:@" savePressed : %@", [[self dictionaryFavoriteLocations] description]]];
        
        BOOL invalidAddress = NO;
        for (NSString *key in [self arrayFavoriteLocations]) {
            if (![[self dictionaryFavoriteLocations] objectForKey:key]) {
                [self makeToastWithMessage:[NSString stringWithFormat:@"Please enter valid address for %@", key]];
                invalidAddress = YES;
                break;
            }
        }
        if (invalidAddress) {
            return;
        }
        
        [self writeFavoritesDictionaryToFile:YES];
    }
}

- (IBAction)mapButtonPressed:(id)sender {
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" mapButtonPressed : %lu", [sender tag]]];
    [self performSegueWithIdentifier:@"GenericLocationFavLocSegue"
                              sender:sender];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:@"Ok"]) {
        NSString *name = [[alertView textFieldAtIndex:0] text];
        if ([name length] > 0) {
            if ([[self arrayFavoriteLocations] containsObject:name]) {
                [self makeToastWithMessage:@"Name already exists, please enter a new name"];
            } else {
                [self addTagToArray:name];
                [[self tableViewFavoriteLocations] reloadData];
                [self updateButtonTitle];
            }
        } else {
            [self makeToastWithMessage:@"Please enter a name for the location"];
        }
    } else if ([buttonTitle isEqualToString:@"Cancel"]) {
        
    }
}

#pragma mark - Private methods

- (void)writeFavoritesDictionaryToFile:(BOOL)shouldPop {
    
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionary];
    for (NSString *key in [[self dictionaryFavoriteLocations] allKeys]) {
        [mutableDictionary setObject:[[[self dictionaryFavoriteLocations] objectForKey:key] dictionaryAddressModel]
                              forKey:key];
    }
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:mutableDictionary
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                 encoding:NSUTF8StringEncoding];
    if (!error) {
        //            [Logger logDebug:[self TAG]
        //                     message:[NSString stringWithFormat:@" savePressed jsonString : %@", jsonString]];
        [self writeFavoriteLocationsJSONToFile:jsonString
                                   shouldPopVC:shouldPop];
        
    } else {
        [Logger logError:[self TAG]
                 message:[NSString stringWithFormat:@" writeFavoritesDictionaryToFile JSON error : %@", [error localizedDescription]]];
    }
    
}

- (void)writeFavoriteLocationsJSONToFile:(NSString *)jsonString
                             shouldPopVC:(BOOL)shouldPop {
    
    NSError *error = nil;
    
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:FAVORITE_LOCATIONS_FILE_NAME];
    [jsonString writeToFile:filePath
                 atomically:YES
                   encoding:NSUTF8StringEncoding
                      error:&error];
    if (!error) {
        if (shouldPop) {
            [self popVC];
        }
    } else {
        [Logger logError:[self TAG]
                 message:[NSString stringWithFormat:@" writeFavoriteLocationsJSONToFile error : %@", [error localizedDescription]]];
        [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
    }
}

- (void)readFavoriteLocationsJSONFromFile {
    
    NSError *error = nil;
    
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:FAVORITE_LOCATIONS_FILE_NAME];
    NSString *jsonString = [NSString stringWithContentsOfFile:filePath
                                                     encoding:NSUTF8StringEncoding
                                                        error:&error];
    if (!error) {
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                                   options:NSJSONReadingMutableContainers
                                                                     error:&error];
        
        NSMutableArray *array = [NSMutableArray array];
        NSArray *allKeys = [dictionary allKeys];
        
        if ([allKeys containsObject:FAVORITE_LOCATIONS_TAG_VALUE_HOME]) {
            AddressModel *addressModel = [[AddressModel alloc] init];
            [addressModel setLocation:[[CLLocation alloc] initWithLatitude:[[[dictionary objectForKey:FAVORITE_LOCATIONS_TAG_VALUE_HOME] objectForKey:MODEL_DICT_KEY_LATITUDE] doubleValue]
                                                                 longitude:[[[dictionary objectForKey:FAVORITE_LOCATIONS_TAG_VALUE_HOME] objectForKey:MODEL_DICT_KEY_LONGITUDE] doubleValue]]];
            [addressModel setShortName:[[dictionary objectForKey:FAVORITE_LOCATIONS_TAG_VALUE_HOME] objectForKey:MODEL_DICT_KEY_SHORT_NAME]];
            [addressModel setLongName:[[dictionary objectForKey:FAVORITE_LOCATIONS_TAG_VALUE_HOME] objectForKey:MODEL_DICT_KEY_LONG_NAME]];
            
            [array insertObject:FAVORITE_LOCATIONS_TAG_VALUE_HOME
                        atIndex:0];
            
            [self addAddressModelToDictionary:addressModel
                                       forTag:FAVORITE_LOCATIONS_TAG_VALUE_HOME];
        }
        
        if ([allKeys containsObject:FAVORITE_LOCATIONS_TAG_VALUE_OFFICE]) {
            AddressModel *addressModel = [[AddressModel alloc] init];
            [addressModel setLocation:[[CLLocation alloc] initWithLatitude:[[[dictionary objectForKey:FAVORITE_LOCATIONS_TAG_VALUE_OFFICE] objectForKey:MODEL_DICT_KEY_LATITUDE] doubleValue]
                                                                 longitude:[[[dictionary objectForKey:FAVORITE_LOCATIONS_TAG_VALUE_OFFICE] objectForKey:MODEL_DICT_KEY_LONGITUDE] doubleValue]]];
            [addressModel setShortName:[[dictionary objectForKey:FAVORITE_LOCATIONS_TAG_VALUE_OFFICE] objectForKey:MODEL_DICT_KEY_SHORT_NAME]];
            [addressModel setLongName:[[dictionary objectForKey:FAVORITE_LOCATIONS_TAG_VALUE_OFFICE] objectForKey:MODEL_DICT_KEY_LONG_NAME]];
            
            [array insertObject:FAVORITE_LOCATIONS_TAG_VALUE_OFFICE
                        atIndex:1];
            
            [self addAddressModelToDictionary:addressModel
                                       forTag:FAVORITE_LOCATIONS_TAG_VALUE_OFFICE];
        }
        
        for (NSString *key in allKeys) {
            if (![key isEqualToString:FAVORITE_LOCATIONS_TAG_VALUE_HOME] && ![key isEqualToString:FAVORITE_LOCATIONS_TAG_VALUE_OFFICE]) {
                AddressModel *addressModel = [[AddressModel alloc] init];
                [addressModel setLocation:[[CLLocation alloc] initWithLatitude:[[[dictionary objectForKey:key] objectForKey:MODEL_DICT_KEY_LATITUDE] doubleValue]
                                                                     longitude:[[[dictionary objectForKey:key] objectForKey:MODEL_DICT_KEY_LONGITUDE] doubleValue]]];
                [addressModel setShortName:[[dictionary objectForKey:key] objectForKey:MODEL_DICT_KEY_SHORT_NAME]];
                [addressModel setLongName:[[dictionary objectForKey:key] objectForKey:MODEL_DICT_KEY_LONG_NAME]];
                
                [array addObject:key];
                
                [self addAddressModelToDictionary:addressModel
                                           forTag:key];
            }
        }
        
        if ([array count] > 0) {
            [self setArrayFavoriteLocations:[array copy]];
        }
        
//        [Logger logDebug:[self TAG]
//                 message:[NSString stringWithFormat:@" readFavoriteLocationsJSONFromFile name : %@ dictionary : %@", [[dictionary objectForKey:FAVORITE_LOCATIONS_TAG_VALUE_HOME] objectForKey:@"longName"], [dictionary description]]];
    } else {
        [Logger logError:[self TAG]
                 message:[NSString stringWithFormat:@" readFavoriteLocationsJSONFromFile error : %@", [error localizedDescription]]];
        
        [self setArrayFavoriteLocations:[NSArray arrayWithObjects:FAVORITE_LOCATIONS_TAG_VALUE_HOME, FAVORITE_LOCATIONS_TAG_VALUE_OFFICE, nil]];
        
//        [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
    }
}

- (void)addTagToArray:(NSString *)tag {
    if ([[self arrayFavoriteLocations] containsObject:tag]) {
        return;
    }
    NSMutableArray *arrayMutable = [[self arrayFavoriteLocations] mutableCopy];
    [arrayMutable addObject:tag];
    [self setArrayFavoriteLocations:[arrayMutable copy]];
}

- (void)addAddressModelToDictionary:(AddressModel *)address
                             forTag:(NSString *)tag {
    NSMutableDictionary *dictionaryMutable = [[self dictionaryFavoriteLocations] mutableCopy];
    [dictionaryMutable setObject:address
                          forKey:tag];
    [self setDictionaryFavoriteLocations:[dictionaryMutable copy]];
}

- (void)popVC {
    [[self navigationController] popViewControllerAnimated:NO];
}

- (void)updateButtonTitle {
    [[self buttonAddMore] setTitle:[NSString stringWithFormat:@"%@%lu%@", @"Add More (", (MAX_FAVORITES - [[self arrayFavoriteLocations] count]), @" remaining)"]
                          forState:UIControlStateNormal];
    
    if (MAX_FAVORITES == [[self arrayFavoriteLocations] count]) {
        [[self buttonAddMore] setEnabled:NO];
    }
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

- (void)showFavoriteLocationAlertView {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Favorites"
                                                        message:@"You have not saved your home and/or office locations. Save them in favorites to activate these options, would you like to do that now?"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Yes", @"Later", nil];
    [alertView show];
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" textFieldShouldBeginEditing : %lu", [textField tag]]];
    
    [self performSegueWithIdentifier:@"AutoCompleteFavLocSegue"
                              sender:textField];
    
    return NO;
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return [[self arrayFavoriteLocations] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    FavoriteLocationsTableViewCell *cell;
    static NSString *reuseIdentifier = @"FavoriteLocationsTableViewCell";
    cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (!cell) {
        cell = [[FavoriteLocationsTableViewCell alloc] init];
    }
    
    [[cell labelTag] setText:[[self arrayFavoriteLocations] objectAtIndex:indexPath.row]];
    
    AddressModel *addressModel = [[self dictionaryFavoriteLocations] objectForKey:[[self arrayFavoriteLocations] objectAtIndex:indexPath.row]];
    if (addressModel) {
        [[cell textFieldAddress] setText:[addressModel longName]];
    }
    
    [[cell buttonMap] setTag:indexPath.row];
    [[cell buttonMap] addTarget:self
                         action:@selector(mapButtonPressed:)
               forControlEvents:UIControlEventTouchUpInside];
    
    [[cell textFieldAddress] setTag:indexPath.row];
    [[cell textFieldAddress] setDelegate:self];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGRect frameTableView = [tableView frame];
    return frameTableView.size.height / 3.0;
}

#pragma mark - UITableViewDelegate methods

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0 || indexPath.row == 1) {
        return NO;
    } else {
        return YES;
    }
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        NSMutableDictionary *dictionary = [[self dictionaryFavoriteLocations] mutableCopy];
        [dictionary removeObjectForKey:[[self arrayFavoriteLocations] objectAtIndex:indexPath.row]];
        [self setDictionaryFavoriteLocations:[dictionary copy]];
        
        NSMutableArray *array = [[self arrayFavoriteLocations] mutableCopy];
        [array removeObjectAtIndex:indexPath.row];
        [self setArrayFavoriteLocations:[array copy]];
        
        [self writeFavoritesDictionaryToFile:NO];
        
        [self updateButtonTitle];
        
        [[self tableViewFavoriteLocations] reloadData];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"GenericLocationFavLocSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[GenericLocationPickerViewController class]]) {
            [(GenericLocationPickerViewController *)[segue destinationViewController] setSegueType:[NSString stringWithFormat:@"%@%lu", SEGUE_TYPE_FAV_LOC_LOCATION, [sender tag]]];
            [(GenericLocationPickerViewController *)[segue destinationViewController] setDelegateGenericLocationPickerVC:self];
        }
    } else if ([[segue identifier] isEqualToString:@"AutoCompleteFavLocSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[PlacesAutoCompleteViewController class]]) {
            [(PlacesAutoCompleteViewController *)[segue destinationViewController] setSegueType:[NSString stringWithFormat:@"%@%lu", SEGUE_TYPE_FAV_LOC_AUTO_COMPLETE, [sender tag]]];
            [(PlacesAutoCompleteViewController *)[segue destinationViewController] setDelegatePlacesAutoCompleteVC:self];
        }
    }
}

#pragma mark - GenericLocationPickerVCProtocol methods

- (void)addressModelFromSender:(GenericLocationPickerViewController *)sender
                       address:(AddressModel *)model
                  forSegueType:(NSString *)segueType {
    
    NSUInteger index = [[segueType stringByReplacingOccurrencesOfString:SEGUE_TYPE_FAV_LOC_LOCATION
                                                             withString:@""] integerValue];
    [self addAddressModelToDictionary:model
                               forTag:[[self arrayFavoriteLocations] objectAtIndex:index]];
    [[self tableViewFavoriteLocations] reloadData];
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" addressModelFromSender segueType : %@ name : %@ index : %lu", segueType, [model longName], index]];
}

#pragma mark - PlacesAutoCompleteVCProtocol methods

- (void)addressModelFromSenderAutoComp:(PlacesAutoCompleteViewController *)sender
                               address:(AddressModel *)model
                          forSegueType:(NSString *)segueType {
    
    NSUInteger index = [[segueType stringByReplacingOccurrencesOfString:SEGUE_TYPE_FAV_LOC_AUTO_COMPLETE
                                                             withString:@""] integerValue];
    [self addAddressModelToDictionary:model
                               forTag:[[self arrayFavoriteLocations] objectAtIndex:index]];
    [[self tableViewFavoriteLocations] reloadData];
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" addressModelFromSenderAutoComp segueType : %@ name : %@ index : %lu", segueType, [model longName], index]];
}

@end
