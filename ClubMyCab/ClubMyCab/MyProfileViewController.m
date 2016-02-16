//
//  MyProfileViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 11/09/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import "MyProfileViewController.h"
#import "SWRevealViewController.h"
#import "Logger.h"
#import "ToastLabel.h"
#import "ActivityIndicatorView.h"
#import "GlobalMethods.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

@interface MyProfileViewController () <GlobalMethodsAsyncRequestProtocol, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) NSString *TAG;

@property (strong, nonatomic) ToastLabel *toastLabel;
@property (strong, nonatomic) ActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) NSString *mobileNumber;

@property (weak, nonatomic) IBOutlet UIImageView *imageViewBackground;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewProfile;
@property (weak, nonatomic) IBOutlet UILabel *labelName;
@property (weak, nonatomic) IBOutlet UITextField *textFieldName;
@property (weak, nonatomic) IBOutlet UITextField *textFieldNumber;
@property (weak, nonatomic) IBOutlet UITextField *textFieldEmail;
@property (weak, nonatomic) IBOutlet UITextField *textFieldDOB;
@property (weak, nonatomic) IBOutlet UITextField *textFieldGender;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UIButton *buttonUpdate;

@end

@implementation MyProfileViewController

- (NSString *)TAG {
    return @"MyProfileViewController";
}

#pragma mark - View Controller Life Cycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    SWRevealViewController *revealViewController = [self revealViewController];
    if (revealViewController) {
        [[self barButtonItem] setTarget:revealViewController];
        [[self barButtonItem] setAction:@selector(revealToggle:)];
        [[self view] addGestureRecognizer:[[self revealViewController] panGestureRecognizer]];
    }
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(keyboardWillShow:)
//                                                 name:UIKeyboardWillShowNotification
//                                               object:nil];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [self setMobileNumber:[userDefaults objectForKey:KEY_USER_DEFAULT_MOBILE]];
    
    [self fetchMyProfile];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_FETCH_UNREAD_NOTIFICATIONS_COUNT
                                                     parameters:[NSString stringWithFormat:@"MobileNumber=%@", [self mobileNumber]]
                                            delegateForProtocol:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [[self scrollView] setContentOffset:CGPointZero];
    
    [textField resignFirstResponder];
    return YES;
}

#define GENDER_TYPE_MALE                @"Male"
#define GENDER_TYPE_FEMALE              @"Female"

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (textField == [self textFieldName]) {
        return YES;
    } else if (textField == [self textFieldEmail]) {
//        [[self scrollView] setContentOffset:CGPointMake(0.0f, [[self textFieldEmail] frame].origin.y * 0.95)];
        [[self scrollView] setContentOffset:CGPointMake(0.0f, 50.0f)];
        return YES;
    } else if (textField == [self textFieldDOB]) {
        [[self scrollView] setContentOffset:CGPointMake(0.0f, 100.0f)];
        [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                                   target:self
                                                                                                   action:@selector(datePickerDonePressed:)]];
        [[self buttonUpdate] setHidden:YES];
        [[self datePicker] setMaximumDate:[NSDate date]];
        [[self datePicker] setHidden:NO];
        return NO;
    } else if (textField == [self textFieldGender]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@""
                                                                                 message:@"Please select gender"
                                                                          preferredStyle:UIAlertControllerStyleActionSheet];
        
        [alertController addAction:[UIAlertAction actionWithTitle:GENDER_TYPE_MALE
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              [[self textFieldGender] setText:GENDER_TYPE_MALE];
                                                          }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:GENDER_TYPE_FEMALE
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              [[self textFieldGender] setText:GENDER_TYPE_FEMALE];
                                                          }]];
        
        [self presentViewController:alertController
                           animated:YES
                         completion:^{}];
        
        return NO;
    }
    
    return NO;
}

#pragma mark - IBAction methods

- (IBAction)notificationsBarButtonItemPressed {
    
    [self performSegueWithIdentifier:@"NotificationsProfileSegue"
                              sender:self];
}


- (IBAction)datePickerValueChanged:(UIDatePicker *)sender {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd/MM/yyyy"];
    [[self textFieldDOB] setText:[dateFormatter stringFromDate:[sender date]]];
}

- (IBAction)updatePressed:(UIButton *)sender {
    [self showActivityIndicatorView];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_UPDATE_PROFILE
                                                     parameters:[NSString stringWithFormat:@"UserNumber=%@&Email=%@&Gender=%@&DOB=%@&fullName=%@", [self mobileNumber], [[self textFieldEmail] text], [[self textFieldGender] text], [[self textFieldDOB] text], [[self textFieldName] text]]
                                            delegateForProtocol:self];
}

- (IBAction)datePickerDonePressed:(id)sender {
    [[self navigationItem] setRightBarButtonItem:nil];
    [[self scrollView] setContentOffset:CGPointZero];
    [[self buttonUpdate] setHidden:NO];
    [[self datePicker] setHidden:YES];
}

- (IBAction)imageViewProfilePressed:(UITapGestureRecognizer *)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Profile picture"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Take Photo"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          [self checkCameraPermission];
                                                      }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Photo Library"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          [self checkPhotoPermission];
                                                      }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                      }]];
    
    [self presentViewController:alertController
                       animated:YES
                     completion:^{}];
}

#pragma mark - UIImagePickerControllerDelegate methods

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    [self dismissViewControllerAnimated:YES
                             completion:^{}];
    
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    CGRect frame = [[self imageViewProfile] frame];
    UIImage *scaledImage = [self scaleImage:image
                                     toSize:CGSizeMake(frame.size.width, frame.size.height)];
    
    NSString *base64 = [UIImagePNGRepresentation(scaledImage) base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    
    [self showActivityIndicatorView];
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_IMAGE_UPLOAD
                                                     parameters:[NSString stringWithFormat:@"MobileNumber=%@&imagestr=%@", [self mobileNumber], base64]
                                            delegateForProtocol:self];
    
    [[NSUserDefaults standardUserDefaults] setObject:UIImagePNGRepresentation(scaledImage)
                                              forKey:KEY_USER_DEFAULT_PROFILE_IMAGE_DATA];
    
//    [Logger logDebug:[self TAG]
//             message:[NSString stringWithFormat:@" didFinishPickingMediaWithInfo : (%f, %f) image : %@", frame.size.width, frame.size.height, [[[self imageViewProfile] image] description]]];
    
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:@"Cancel"]) {
        
    } else if ([buttonTitle isEqualToString:@"Settings"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
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
            if ([endPoint isEqualToString:ENDPOINT_FETCH_PROFILE]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSArray *parsedJson = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                      options:NSJSONReadingMutableContainers
                                                                        error:&error];
                if (!error) {
                    [Logger logDebug:[self TAG]
                             message:[NSString stringWithFormat:@" parsedJson : %@", parsedJson]];
                    
                    NSDictionary *profileDictionary = [parsedJson firstObject];
                    
                    [[self labelName] setText:[profileDictionary objectForKey:@"FullName"]];
                    [[self textFieldName] setText:[profileDictionary objectForKey:@"FullName"]];
                    [[self textFieldNumber] setText:[[profileDictionary objectForKey:@"MobileNumber"] stringByReplacingOccurrencesOfString:@"0091"
                                                                                                                         withString:@""]];
                    [[self textFieldEmail] setText:[profileDictionary objectForKey:@"Email"]];
                    [[self textFieldDOB] setText:[profileDictionary objectForKey:@"DOB"]];
                    [[self textFieldGender] setText:[profileDictionary objectForKey:@"Gender"]];
                    
                    [self fetchImageName];
                } else {
                    [Logger logError:[self TAG]
                             message:[NSString stringWithFormat:@" %@ parsing error : %@", endPoint, [error localizedDescription]]];
                    [self makeToastWithMessage:GENERIC_ERROR_MESSAGE];
                }
            } else if ([endPoint isEqualToString:ENDPOINT_UPDATE_PROFILE]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                if (response && [response caseInsensitiveCompare:@"update success"] == NSOrderedSame) {
                    [self makeToastWithMessage:@"Profile updated successfully"];
                    [self fetchMyProfile];
                } else {
                    [self makeToastWithMessage:response];
                }
            } else if ([endPoint isEqualToString:ENDPOINT_FETCH_UNREAD_NOTIFICATIONS_COUNT]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                [[self navigationItem] setRightBarButtonItem:[[[GlobalMethods alloc] init] getNotificationsBarButtonItemWithTarget:self
                                                                                                          unreadNotificationsCount:[response intValue]]];
            } else if ([endPoint isEqualToString:ENDPOINT_FETCH_IMAGE_NAME]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                if (response && [response length] > 0) {
                    NSData *image = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/ProfileImages/%@", SERVER_ADDRESS, response]]];
//                    [Logger logDebug:[self TAG]
//                             message:[NSString stringWithFormat:@" ProfileImages : %@", [image description]]];
                    [[self imageViewProfile] setImage:[UIImage imageWithData:image]];
                }
                
                CGRect frame = [[self imageViewProfile] frame];
                [[[self imageViewProfile] layer] setCornerRadius:(frame.size.width / 2.0f)];
                [[self imageViewProfile] setClipsToBounds:YES];
                
                if ([self changeProfilePicture]) {
                    [self setChangeProfilePicture:NO];
                    [self imageViewProfilePressed:nil];
                }
            } else if ([endPoint isEqualToString:ENDPOINT_IMAGE_UPLOAD]) {
                NSString *response = [data valueForKey:KEY_DATA_ASYNC_CONNECTION];
                if (response && [[response lowercaseString] rangeOfString:@"Error"].location == NSNotFound) {
                    [self makeToastWithMessage:@"Image Uploaded"];
                    [self fetchImageName];
                } else {
                    [self makeToastWithMessage:@"Error uploading Image, Please try again or use a different image"];
                }
            }
        }
    });
}

#pragma mark - Private methods

- (void)fetchMyProfile {
    [self showActivityIndicatorView];
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_FETCH_PROFILE
                                                     parameters:[NSString stringWithFormat:@"UserNumber=%@", [self mobileNumber]]
                                            delegateForProtocol:self];
}

- (void)fetchImageName {
    
    GlobalMethods *globalMethods = [[GlobalMethods alloc] init];
    [globalMethods makeURLConnectionAsynchronousRequestToServer:SERVER_ADDRESS
                                                       endPoint:ENDPOINT_FETCH_IMAGE_NAME
                                                     parameters:[NSString stringWithFormat:@"MobileNumber=%@", [self mobileNumber]]
                                            delegateForProtocol:self];
}

//- (void)keyboardWillShow:(NSNotification *)notification
//{
//    [Logger logDebug:[self TAG]
//             message:[NSString stringWithFormat:@" keyboardWillShow"]];
//    
//    [UIView animateWithDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] delay:0 options:[[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue] animations:^{
//        [[self scrollView] setContentOffset:CGPointMake(0.0f, 20.0f)];
//    } completion:^(BOOL finished) {
//    }];
//}

- (void)checkCameraPermission {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusAuthorized) {
        [Logger logDebug:[self TAG]
                 message:[NSString stringWithFormat:@"checkCameraPermission AVAuthorizationStatusAuthorized"]];
        [self showImagePickerCamera];
    } else if (status == AVAuthorizationStatusNotDetermined) {
        [Logger logDebug:[self TAG]
                 message:[NSString stringWithFormat:@"checkCameraPermission AVAuthorizationStatusNotDetermined"]];
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                                 completionHandler:^(BOOL granted) {
                                     if (granted) {
                                         [self showImagePickerCamera];
                                     } else {
                                         [self showCameraPermissionAlertView];
                                     }
                                 }];
    } else {
        [Logger logDebug:[self TAG]
                 message:[NSString stringWithFormat:@"checkCameraPermission AVAuthorizationStatus Others"]];
        [self showCameraPermissionAlertView];
    }
}

- (void)showImagePickerCamera {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    [imagePickerController setSourceType:UIImagePickerControllerSourceTypeCamera];
    [imagePickerController setDelegate:self];
    [self presentViewController:imagePickerController
                       animated:YES
                     completion:^{}];
}

- (void)showCameraPermissionAlertView {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Permission needed"
                                                        message:@"iShareRyde cannot take your profile picture without access to the Camera. Please provide access in Settings"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Cancel", @"Settings", nil];
    [alertView show];
}

- (void)checkPhotoPermission {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusAuthorized) {
        [Logger logDebug:[self TAG]
                 message:[NSString stringWithFormat:@"checkPhotoPermission PHAuthorizationStatusAuthorized"]];
        [self showImagePickerPhotos];
    } else if (status == PHAuthorizationStatusNotDetermined) {
        [Logger logDebug:[self TAG]
                 message:[NSString stringWithFormat:@"checkPhotoPermission PHAuthorizationStatusNotDetermined"]];
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status) {
                [self showImagePickerPhotos];
            } else {
                [self showPhotoPermissionAlertView];
            }
        }];
    } else {
        [Logger logDebug:[self TAG]
                 message:[NSString stringWithFormat:@"checkPhotoPermission PHAuthorizationStatus Others"]];
        [self showPhotoPermissionAlertView];
    }
}

- (void)showImagePickerPhotos {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    [imagePickerController setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [imagePickerController setDelegate:self];
    [self presentViewController:imagePickerController
                       animated:YES
                     completion:^{}];
}

- (void)showPhotoPermissionAlertView {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Permission needed"
                                                        message:@"iShareRyde cannot choose a profile picture without access to your Photo Library. Please provide access in Settings"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Cancel", @"Settings", nil];
    [alertView show];
}

- (UIImage *)scaleImage:(UIImage *)originalImage
                 toSize:(CGSize)newSize {
    if (CGSizeEqualToSize([originalImage size], newSize)) {
        return originalImage;
    }
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0f);
    [originalImage drawInRect:CGRectMake(0.0f, 0.0f, newSize.width, newSize.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
