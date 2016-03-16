//
//  HomePageViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 11/09/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import "HomePageViewController.h"
#import "Logger.h"
#import "ActivityIndicatorView.h"
#import "ToastLabel.h"
#import "GenericLocationPickerViewController.h"
#import "FavoriteLocationsViewController.h"
#import "PlacesAutoCompleteViewController.h"
#import "TripDateTimeViewController.h"
#import "BookACabViewController.h"
#import <Google/Analytics.h>

@import GoogleMaps;

@interface HomePageViewController () <UITextFieldDelegate, GenericLocationPickerVCProtocol, UIAlertViewDelegate, PlacesAutoCompleteVCProtocol>

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (weak, nonatomic) IBOutlet UITextField *textfieldFromLocation;
@property (weak, nonatomic) IBOutlet UITextField *textfieldToLocation;
@property (weak, nonatomic) IBOutlet UIView *viewClubAndCabButtons;
@property (weak, nonatomic) IBOutlet UIView *viewSubClubAndCabButtons;
@property (weak, nonatomic) IBOutlet UIButton *buttonNext;
@property (weak, nonatomic) IBOutlet UIView *viewHomeToOffice;
@property (weak, nonatomic) IBOutlet UIView *viewOfficeToHome;
@property (weak, nonatomic) IBOutlet UIButton *buttonSaveFavorites;
@property (weak, nonatomic) IBOutlet UILabel *labelChooseFavorite;

@property (strong, nonatomic) AddressModel *addressModelFrom, *addressModelTo;

@property (nonatomic) BOOL hasFavoriteLocations;

@property (strong, nonatomic) NSDictionary *dictionaryFavoriteLocations;

@property (strong, nonatomic) UIAlertView *alertViewFavoriteLocations;

@end

@implementation HomePageViewController

- (NSString *)TAG {
    return @"HomePageViewController";
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
    
//    SWRevealViewController *revealViewController = [self revealViewController];
//    if (revealViewController) {
//        [[self barButtonItem] setTarget:revealViewController];
//        [[self barButtonItem] setAction:@selector(revealToggle:)];
//        [[self view] addGestureRecognizer:[[self revealViewController] panGestureRecognizer]];
//    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName
           value:[self TAG]];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    [self clearHomeOfficeSelection];
    
    [self readFavoriteLocationsJSONFromFile];
    
    if ([self hasFavoriteLocations]) {
        [[self viewHomeToOffice] setHidden:NO];
        [[self viewOfficeToHome] setHidden:NO];
        [[self labelChooseFavorite] setHidden:NO];
        [[self buttonSaveFavorites] setHidden:YES];
    } else {
        [[self viewHomeToOffice] setHidden:YES];
        [[self viewOfficeToHome] setHidden:YES];
        [[self labelChooseFavorite] setHidden:YES];
        [[self buttonSaveFavorites] setHidden:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    
    [self clearHomeOfficeSelection];
    
    if (textField == [self textfieldFromLocation]) {
        [self performSegueWithIdentifier:@"AutoCompleteHomeSegue"
                                  sender:SEGUE_TYPE_HOME_PAGE_FROM_AUTO_COMPLETE];
    } else if (textField == [self textfieldToLocation]) {
        [self performSegueWithIdentifier:@"AutoCompleteHomeSegue"
                                  sender:SEGUE_TYPE_HOME_PAGE_TO_AUTO_COMPLETE];
    }
    
    return NO;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" prepareForSegue : %@", [segue identifier]]];
    
    if ([[segue identifier] isEqualToString:@"GenericLocationSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[GenericLocationPickerViewController class]]) {
            [(GenericLocationPickerViewController *)[segue destinationViewController] setDelegateGenericLocationPickerVC:self];
            [(GenericLocationPickerViewController *)[segue destinationViewController] setSegueType:sender];
        }
    } else if ([[segue identifier] isEqualToString:@"FavLocHomeSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[FavoriteLocationsViewController class]]) {
            
        }
    } else if ([[segue identifier] isEqualToString:@"AutoCompleteHomeSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[PlacesAutoCompleteViewController class]]) {
            [(PlacesAutoCompleteViewController *)[segue destinationViewController] setSegueType:sender];
            [(PlacesAutoCompleteViewController *)[segue destinationViewController] setDelegatePlacesAutoCompleteVC:self];
        }
    } else if ([[segue identifier] isEqualToString:@"TripDateTimeSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[TripDateTimeViewController class]]) {
            [(TripDateTimeViewController *)[segue destinationViewController] setAddressModelFrom:[self addressModelFrom]];
            [(TripDateTimeViewController *)[segue destinationViewController] setAddressModelTo:[self addressModelTo]];
            [(TripDateTimeViewController *)[segue destinationViewController] setSegueType:[self segueType]];
            
            [self clearAddressModels];
        }
    } else if ([[segue identifier] isEqualToString:@"BookACabHomeSegue"]) {
        if ([[segue destinationViewController] isKindOfClass:[BookACabViewController class]]) {
            [(BookACabViewController *)[segue destinationViewController] setAddressModelFrom:[self addressModelFrom]];
            [(BookACabViewController *)[segue destinationViewController] setAddressModelTo:[self addressModelTo]];
            
            [self clearAddressModels];
        }
    }
}

#pragma mark - GenericLocationPickerVCProtocol methods

- (void)addressModelFromSender:(GenericLocationPickerViewController *)sender
                       address:(AddressModel *)model
                  forSegueType:(NSString *)segueType {
    if ([segueType isEqualToString:SEGUE_TYPE_HOME_PAGE_FROM_LOCATION]) {
        [self setAddressModelFrom:model];
        
        [[self textfieldFromLocation] setText:[[self addressModelFrom] longName]];
    } else if ([segueType isEqualToString:SEGUE_TYPE_HOME_PAGE_TO_LOCATION]) {
        [self setAddressModelTo:model];
        
        [[self textfieldToLocation] setText:[[self addressModelTo] longName]];
    }
    
//    [self showButtonsView];
    [self performSelector:@selector(showButtonsView)
               withObject:nil
               afterDelay:1.0];     //adding delay to let the GenericLocationPickerViewController popVC complete
}

#pragma mark - PlacesAutoCompleteVCProtocol methods

- (void)addressModelFromSenderAutoComp:(PlacesAutoCompleteViewController *)sender
                               address:(AddressModel *)model
                          forSegueType:(NSString *)segueType {
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" addressModelFromSenderAutoComp model : %@ segueType : %@", model, segueType]];
    
    if ([segueType isEqualToString:SEGUE_TYPE_HOME_PAGE_FROM_AUTO_COMPLETE]) {
        [self setAddressModelFrom:model];
        
        [[self textfieldFromLocation] setText:[[self addressModelFrom] longName]];
    } else if ([segueType isEqualToString:SEGUE_TYPE_HOME_PAGE_TO_AUTO_COMPLETE]) {
        [self setAddressModelTo:model];
        
        [[self textfieldToLocation] setText:[[self addressModelTo] longName]];
    }
    
//    [self showButtonsView];
    [self performSelector:@selector(showButtonsView)
               withObject:nil
               afterDelay:1.0];     //adding delay to let the PlacesAutoCompleteViewController popVC complete
}

#pragma mark - IBAction methods

- (IBAction)homeToOfficeTapped:(UITapGestureRecognizer *)sender {
    
    [self clearAddressModels];
    
    if ([self hasFavoriteLocations]) {
        [self setAddressModelFrom:[[self dictionaryFavoriteLocations] objectForKey:FAVORITE_LOCATIONS_TAG_VALUE_HOME]];
        [self setAddressModelTo:[[self dictionaryFavoriteLocations] objectForKey:FAVORITE_LOCATIONS_TAG_VALUE_OFFICE]];
        
        [[self viewHomeToOffice] setBackgroundColor:[UIColor lightGrayColor]];
        [[self viewOfficeToHome] setBackgroundColor:[UIColor whiteColor]];
        
        [self showButtonsView];
        
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Home to Office click"
                                                              action:@"Home to Office click"
                                                               label:@"Home to Office click"
                                                               value:nil] build]];
    } else {
        [self showFavoriteLocationAlertView];
    }
}

- (IBAction)officeToHomeTapped:(UITapGestureRecognizer *)sender {
    
    [self clearAddressModels];
    
    if ([self hasFavoriteLocations]) {
        [self setAddressModelFrom:[[self dictionaryFavoriteLocations] objectForKey:FAVORITE_LOCATIONS_TAG_VALUE_OFFICE]];
        [self setAddressModelTo:[[self dictionaryFavoriteLocations] objectForKey:FAVORITE_LOCATIONS_TAG_VALUE_HOME]];
        
        [[self viewOfficeToHome] setBackgroundColor:[UIColor lightGrayColor]];
        [[self viewHomeToOffice] setBackgroundColor:[UIColor whiteColor]];
        
        [self showButtonsView];
        
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Office to Home click"
                                                              action:@"Office to Home click"
                                                               label:@"Office to Home click"
                                                               value:nil] build]];
        
    } else {
        [self showFavoriteLocationAlertView];
    }
}

- (IBAction)fromLocationPressed:(UIButton *)sender {
    [self performSegueWithIdentifier:@"GenericLocationSegue"
                              sender:SEGUE_TYPE_HOME_PAGE_FROM_LOCATION];
    
    [self clearHomeOfficeSelection];
}

- (IBAction)toLocationPressed:(UIButton *)sender {
    [self performSegueWithIdentifier:@"GenericLocationSegue"
                              sender:SEGUE_TYPE_HOME_PAGE_TO_LOCATION];
    
    [self clearHomeOfficeSelection];
}

- (IBAction)clubMyCabPressed:(UIButton *)sender {
    [[self viewClubAndCabButtons] setHidden:YES];
    
    [self performSegueWithIdentifier:@"TripDateTimeSegue"
                              sender:self];
}

- (IBAction)bookCabPressed:(UIButton *)sender {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"BookaCab click"
                                                          action:@"BookaCab click"
                                                           label:@"BookaCab click"
                                                           value:nil] build]];
    
    [[self viewClubAndCabButtons] setHidden:YES];
    
    [self performSegueWithIdentifier:@"BookACabHomeSegue"
                              sender:self];
}

- (IBAction)cancelPressed:(UIButton *)sender {
    [[self viewClubAndCabButtons] setHidden:YES];
    [self clearAddressModels];
}

- (IBAction)nextPressed:(UIButton *)sender {
    if ([[self segueType] isEqualToString:HOME_SEGUE_TYPE_CAR_POOL] || [[self segueType] isEqualToString:HOME_SEGUE_TYPE_SHARE_CAB]) {
        [self clubMyCabPressed:nil];
    } else if ([[self segueType] isEqualToString:HOME_SEGUE_TYPE_BOOK_CAB]) {
        [self bookCabPressed:nil];
    }
}

- (IBAction)saveFavoritesPressed:(UIButton *)sender {
    [self performSegueWithIdentifier:@"FavLocHomeSegue"
                              sender:self];
}

#pragma mark - Private methods

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
        } else {
            [self setHasFavoriteLocations:NO];
            return;
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
        } else {
            [self setHasFavoriteLocations:NO];
            return;
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
        
        [self setHasFavoriteLocations:YES];
        
        [Logger logDebug:[self TAG]
                 message:[NSString stringWithFormat:@" readFavoriteLocationsJSONFromFile home : %@ office : %@ dictionary : %@", [[[self dictionaryFavoriteLocations] objectForKey:FAVORITE_LOCATIONS_TAG_VALUE_HOME] longName], [[[self dictionaryFavoriteLocations] objectForKey:FAVORITE_LOCATIONS_TAG_VALUE_OFFICE] longName], [[self dictionaryFavoriteLocations] description]]];
    } else {
        [Logger logError:[self TAG]
                 message:[NSString stringWithFormat:@" readFavoriteLocationsJSONFromFile error : %@", [error localizedDescription]]];
        
        [self setHasFavoriteLocations:NO];
        
        //        [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
    }
}

- (void)addAddressModelToDictionary:(AddressModel *)address
                             forTag:(NSString *)tag {
    NSMutableDictionary *dictionaryMutable = [[self dictionaryFavoriteLocations] mutableCopy];
    [dictionaryMutable setObject:address
                          forKey:tag];
    [self setDictionaryFavoriteLocations:[dictionaryMutable copy]];
}

- (void)clearAddressModels {
    [self setAddressModelFrom:nil];
    [self setAddressModelTo:nil];
    
    [[self textfieldFromLocation] setText:@""];
    [[self textfieldToLocation] setText:@""];
}

-(void)clearHomeOfficeSelection {
    [[self viewHomeToOffice] setBackgroundColor:[UIColor whiteColor]];
    [[self viewOfficeToHome] setBackgroundColor:[UIColor whiteColor]];
    
    [[self buttonNext] setHidden:YES];
}

- (void)showButtonsView {
    
    NSString *fromText = [[self textfieldFromLocation] text];
    NSString *toText = [[self textfieldToLocation] text];
    
    if ([self addressModelFrom] && [self addressModelTo] && [fromText length] <= 0 && [toText length] <= 0) {
        
        [[self buttonNext] setHidden:NO];
        
//        [[self viewClubAndCabButtons] setHidden:NO];
//        [[self viewClubAndCabButtons] setBackgroundColor:[UIColor colorWithRed:0.0
//                                                                         green:0.0
//                                                                          blue:0.0
//                                                                         alpha:0.6]];
//        [[self viewSubClubAndCabButtons] setBackgroundColor:[UIColor colorWithRed:1.0
//                                                                            green:1.0
//                                                                             blue:1.0
//                                                                            alpha:1.0]];
    } else {
        if ([self addressModelFrom] && [self addressModelTo] && [fromText length] > 0 && [toText length] > 0) {
            [[self buttonNext] setHidden:NO];
        } else {
            [[self buttonNext] setHidden:YES];
        }
    }
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

- (void)showFavoriteLocationAlertView {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Favorites"
                                                        message:@"You have not saved your home and/or office locations. Save them in favorites to activate these options, would you like to do that now?"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Yes", @"Later", nil];
    [alertView show];
    
    [self setAlertViewFavoriteLocations:alertView];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    
    if (alertView == [self alertViewFavoriteLocations]) {
        if ([buttonTitle isEqualToString:@"Yes"]) {
            [self performSegueWithIdentifier:@"FavLocHomeSegue"
                                      sender:self];
        } else if ([buttonTitle isEqualToString:@"Later"]) {
            
        }
    }
}

@end
