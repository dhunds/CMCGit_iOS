//
//  CabsWebViewController.h
//  ClubMyCab
//
//  Created by Rohit Dhundele on 28/12/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CabsWebViewController;

@protocol CabsWebViewControllerProtocol <NSObject>

@required

- (void)bookingProcessCompletedForCabType:(NSString *)cabType
                            withRequestID:(NSString *)reqID
                           andOptionalURL:(NSString *)url;

@end

@interface CabsWebViewController : UIViewController

#define UBER_REQUEST_ID                     @"UberRequestID"
#define OLA_REQUEST_ID                      @"OlaRequestID"

@property (strong, nonatomic) NSString *cabType, *uberRequestID, *olaRequestID, *uberURL, *olaURL;

@property (weak, nonatomic) id <CabsWebViewControllerProtocol> delegateCabsWebViewControllerProtocol;

@end
