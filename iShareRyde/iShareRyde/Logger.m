//
//  Logger.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 20/08/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import "Logger.h"

@implementation Logger

+ (void)logDebug:(NSString *)tag
         message:(NSString *)message {
    if (LOGGING_ENABLED) {
        NSLog(@"%@%@", tag, message);
    }
}

+ (void)logError:(NSString *)tag
         message:(NSString *)message {
    NSLog(@"%@%@", tag, message);
}

@end
