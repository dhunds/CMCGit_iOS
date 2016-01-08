//
//  AddressModel.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 17/11/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import "AddressModel.h"

@implementation AddressModel

- (NSDictionary *)dictionaryAddressModel {
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:[[self location] coordinate].latitude], MODEL_DICT_KEY_LATITUDE, [NSNumber numberWithDouble:[[self location] coordinate].longitude], MODEL_DICT_KEY_LONGITUDE, [self shortName], MODEL_DICT_KEY_SHORT_NAME, [self longName], MODEL_DICT_KEY_LONG_NAME, nil];
}

@end
