//
//  Logger.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 20/08/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Logger : NSObject

+ (void)logDebug:(NSString *)tag
         message:(NSString *)message;

+ (void)logError:(NSString *)tag
         message:(NSString *)message;

@end
