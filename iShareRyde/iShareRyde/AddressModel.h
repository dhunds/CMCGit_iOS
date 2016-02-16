//
//  AddressModel.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 17/11/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMaps/GoogleMaps.h>

@interface AddressModel : NSObject

@property (strong, nonatomic) CLLocation *location;
@property (strong, nonatomic) NSString *shortName;
@property (strong, nonatomic) NSString *longName;

#define MODEL_DICT_KEY_LATITUDE                 @"locationLatitude"
#define MODEL_DICT_KEY_LONGITUDE                @"locationLongitude"
#define MODEL_DICT_KEY_SHORT_NAME               @"shortName"
#define MODEL_DICT_KEY_LONG_NAME                @"longName"

- (NSDictionary *)dictionaryAddressModel;

@end
