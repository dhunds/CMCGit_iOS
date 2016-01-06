//
//  PlacesAutoCompleteViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 18/11/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import "PlacesAutoCompleteViewController.h"
#import "Logger.h"
#import "AutoCompleteTableViewCell.h"

@interface PlacesAutoCompleteViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSString *TAG;

@property (weak, nonatomic) IBOutlet UITextField *textFieldSearch;
@property (weak, nonatomic) IBOutlet UITableView *tableViewPlaces;

@property (nonatomic) BOOL isSearching;
@property (strong, nonatomic) NSString *searchStringOld, *searchStringNew;

@property (strong, nonatomic) NSArray *arrayPlaces;

@end

@implementation PlacesAutoCompleteViewController

#define PLACES_API_BASE                     @"https://maps.googleapis.com/maps/api/place"
#define TYPE_AUTOCOMPLETE_JSON              @"/autocomplete/json"

- (NSString *)TAG {
    return @"PlacesAutoCompleteViewController";
}

#pragma mark - View Controller Life Cycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[self textFieldSearch] addTarget:self
                               action:@selector(textFieldEditing:)
                     forControlEvents:UIControlEventEditingChanged];
    
    [self setIsSearching:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - IBAction methods

- (IBAction)textFieldEditing:(id)sender {
    
    NSString *searchString = [(UITextField *)sender text];
    searchString = [searchString stringByReplacingOccurrencesOfString:@" "
                                                           withString:@"%20"];
    
    if ([self isSearching]) {
        [self setSearchStringNew:searchString];
        
        return;
    } else {
        [self setIsSearching:YES];
        
        [self setSearchStringOld:searchString];
        [self setSearchStringNew:searchString];
        
        [self performSearchForString:[self searchStringNew]];
    }
    
    
}

#pragma mark - Private methods

- (void)performSearchForString:(NSString *)searchString {
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@?sensor=false&key=%@&components=country:ind&input=%@", PLACES_API_BASE, TYPE_AUTOCOMPLETE_JSON, GOOGLE_MAPS_API_KEY, searchString]]];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (!connectionError && data) {
//                                   NSString *resp = [[NSString alloc] initWithData:data
//                                                                          encoding:NSUTF8StringEncoding];
                                   
                                   NSError *error = nil;
                                   NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:data
                                                                                         options:NSJSONReadingMutableContainers
                                                                                           error:&error];
                                   if (!error) {
//                                       [Logger logDebug:[self TAG]
//                                                message:[NSString stringWithFormat:@" PLACES_API_BASE response : %@", [[[parsedJson objectForKey:@"predictions"] firstObject] description]]];
                                       [self setArrayPlaces:[parsedJson objectForKey:@"predictions"]];
                                       
                                       [[self tableViewPlaces] reloadData];
                                   } else {
                                       [Logger logError:[self TAG]
                                                message:[NSString stringWithFormat:@" PLACES_API_BASE parsing error : %@", [error localizedDescription]]];
                                   }
                               } else {
                                   [Logger logError:[self TAG]
                                            message:[NSString stringWithFormat:@" PLACES_API_BASE error : %@", [connectionError localizedDescription]]];
                               }
                               
                               if ([[self searchStringNew] isEqualToString:[self searchStringOld]]) {
                                   [self setIsSearching:NO];
                               } else {
                                   [self setSearchStringOld:[self searchStringNew]];
                                   [self performSearchForString:[self searchStringNew]];
                               }
                           }];
}

- (AddressModel *)geocodeToAddressModelFromAddress:(NSString *)address {
    
    AddressModel *model = nil;
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/geocode/json?address=%@&key=%@", address, GOOGLE_MAPS_API_KEY]]];
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest
                                         returningResponse:&response
                                                     error:&error];
    
    if (!error) {
//        NSString *resp = [[NSString alloc] initWithData:data
//                                               encoding:NSUTF8StringEncoding];
//        [Logger logDebug:[self TAG]
//                 message:[NSString stringWithFormat:@" PLACES_API_BASE response : %@", resp]];
        
        NSError *errorParse = nil;
        NSDictionary *parsedJson = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingMutableContainers
                                                                     error:&errorParse];
        if (!errorParse) {
            if ([[parsedJson objectForKey:@"status"] isEqualToString:@"OK"]) {
//                [Logger logDebug:[self TAG]
//                         message:[NSString stringWithFormat:@" geocodeToAddressModelFromAddress response : %@", [[[parsedJson objectForKey:@"results"] firstObject] description]]];
                
                NSDictionary *resultDictionary = [[parsedJson objectForKey:@"results"] firstObject];
                
                model = [[AddressModel alloc] init];
                CLLocation *location = [[CLLocation alloc] initWithLatitude:[[[[resultDictionary objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lat"] doubleValue]
                                                                  longitude:[[[[resultDictionary objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lng"] doubleValue]];
                [model setLocation:location];
                [model setLongName:[resultDictionary objectForKey:@"formatted_address"]];
                
                NSArray *addressComponents = [resultDictionary objectForKey:@"address_components"];
                
//                [Logger logDebug:[self TAG]
//                         message:[NSString stringWithFormat:@" geocodeToAddressModelFromAddress addressComponents : %@", [addressComponents description]]];
                NSString *subLocality = @"", *locality = @"";
                for (NSDictionary *dict in addressComponents) {
                    if ([[[dict objectForKey:@"types"] description] rangeOfString:@"sublocality"].location != NSNotFound) {
                        subLocality = [dict objectForKey:@"long_name"];
                    }
                    if ([[[dict objectForKey:@"types"] description] rangeOfString:@"locality"].location != NSNotFound) {
                        locality = [dict objectForKey:@"long_name"];
                    }
                }
                
                if ([subLocality length] > 0) {
                    [model setShortName:[NSString stringWithFormat:@"%@, %@", subLocality, locality]];
                } else {
                    [model setShortName:locality];
                }
            } else {
                [Logger logError:[self TAG]
                         message:[NSString stringWithFormat:@" geocodeToAddressModelFromAddress API status error : %@", [parsedJson objectForKey:@"status"]]];
            }
        } else {
            [Logger logError:[self TAG]
                     message:[NSString stringWithFormat:@" geocodeToAddressModelFromAddress parsing error : %@", [errorParse localizedDescription]]];
        }
    } else {
        [Logger logError:[self TAG]
                 message:[NSString stringWithFormat:@" geocodeToAddressModelFromAddress error : %@", [error localizedDescription]]];
    }
    
    return model;
}

- (void)popVC {
    [[self navigationController] popViewControllerAnimated:NO];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return [[self arrayPlaces] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    AutoCompleteTableViewCell *cell;
    static NSString *reuseIdentifier = @"AutoCompleteTableViewCell";
    cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (!cell) {
        cell = [[AutoCompleteTableViewCell alloc] init];
    }
    
    [[cell labelMain] setText:[[[self arrayPlaces] objectAtIndex:indexPath.row] objectForKey:@"description"]];
    [[cell labelSub] setText:@""];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGRect frameTableView = [tableView frame];
    return frameTableView.size.height / 6.0;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:NO];
    
    AddressModel *model = [self geocodeToAddressModelFromAddress:[[[[self arrayPlaces] objectAtIndex:indexPath.row] objectForKey:@"description"] stringByReplacingOccurrencesOfString:@" "
                                                                                                                                                     withString:@"%20"]];
    if (model) {
        [[self delegatePlacesAutoCompleteVC] addressModelFromSenderAutoComp:self
                                                            address:model
                                                       forSegueType:[self segueType]];
        
        [self popVC];
    } else {
        [Logger logError:[self TAG]
                 message:[NSString stringWithFormat:@""]];
    }
    
//    NSString *placeID = [[[self arrayPlaces] objectAtIndex:indexPath.row] objectForKey:@"place_id"];
//    GMSPlacesClient *client = [GMSPlacesClient sharedClient];
//    [client lookUpPlaceID:placeID
//                 callback:^(GMSPlace *result, NSError *error) {
//                     if (!error) {
//                         [Logger logDebug:[self TAG]
//                                  message:[NSString stringWithFormat:@" lookUpPlaceID : %@", [result description]]];
//                     } else {
//                         [Logger logError:[self TAG]
//                                  message:[NSString stringWithFormat:@" lookUpPlaceID error : %@", [error localizedDescription]]];
//                     }
//    }];
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
