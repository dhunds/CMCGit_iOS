//
//  TripDateTimeViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 23/11/15.
//  Copyright © 2015 ClubMyCab. All rights reserved.
//

#import "TripDateTimeViewController.h"
#import "Logger.h"

@interface TripDateTimeViewController ()

@property (strong, nonatomic) NSString *TAG;

@property (weak, nonatomic) IBOutlet UIImageView *imageView30Min;
@property (weak, nonatomic) IBOutlet UIImageView *imageView1Hour;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewSelectDateTime;
@property (weak, nonatomic) IBOutlet UILabel *label30Min;
@property (weak, nonatomic) IBOutlet UILabel *label1Hour;
@property (weak, nonatomic) IBOutlet UILabel *labelSelectDateTime;
@property (weak, nonatomic) IBOutlet UILabel *labelCoPassengers;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBarDatePicker;

@end

@implementation TripDateTimeViewController

#define TEXT_TAP_TO_CHANGE                  @"        (tap to change)"

- (NSString *)TAG {
    return @"TripDateTimeViewController";
}

#pragma mark - View Controller Life Cycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self label30MinPressed:nil];
    [[self labelCoPassengers] setText:[NSString stringWithFormat:@"3%@", TEXT_TAP_TO_CHANGE]];
    
    [[self datePicker] setMinimumDate:[NSDate date]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark - Private methods

- (void)hideDatePicker {
    [[self datePicker] setHidden:YES];
    [[self toolBarDatePicker] setHidden:YES];
}

#pragma mark - IBAction methods

- (IBAction)nextPressed:(UIButton *)sender {
    
}

- (IBAction)label30MinPressed:(UITapGestureRecognizer *)sender {
    [self hideDatePicker];
    
    [[self imageView30Min] setHidden:NO];
    [[self imageView1Hour] setHidden:YES];
    [[self imageViewSelectDateTime] setHidden:YES];
    
    NSDate *date = [NSDate date];
    date = [date dateByAddingTimeInterval:(30.0 * 60.0)];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd/MM/yyyy    hh:mm a"];
    
    [[self label30Min] setText:[dateFormatter stringFromDate:date]];
    [[self label1Hour] setText:@""];
    [[self labelSelectDateTime] setText:@""];
}

- (IBAction)label1HourPressed:(UITapGestureRecognizer *)sender {
    [self hideDatePicker];
    
    [[self imageView30Min] setHidden:YES];
    [[self imageView1Hour] setHidden:NO];
    [[self imageViewSelectDateTime] setHidden:YES];
    
    NSDate *date = [NSDate date];
    date = [date dateByAddingTimeInterval:(60.0 * 60.0)];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd/MM/yyyy    hh:mm a"];
    
    [[self label30Min] setText:@""];
    [[self label1Hour] setText:[dateFormatter stringFromDate:date]];
    [[self labelSelectDateTime] setText:@""];
}

- (IBAction)labelSelectDateTimePressed:(UITapGestureRecognizer *)sender {
    [[self imageView30Min] setHidden:YES];
    [[self imageView1Hour] setHidden:YES];
    [[self imageViewSelectDateTime] setHidden:NO];
    
    [[self datePicker] setHidden:NO];
    [[self toolBarDatePicker] setHidden:NO];
}

- (IBAction)labelCoPassengersPressed:(UITapGestureRecognizer *)sender {
    [self hideDatePicker];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@""
                                                                             message:@"Select number of seats"
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (int i = 1; i <= 6; i++) {
        [alertController addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%d", i]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              [[self labelCoPassengers] setText:[NSString stringWithFormat:@"%@%@", [action title], TEXT_TAP_TO_CHANGE]];
                                                          }]];
    }
    
    [self presentViewController:alertController
                       animated:YES
                     completion:^{}];
}

- (IBAction)datePickerValueChanged:(UIDatePicker *)sender {
    NSDate *date = [sender date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd/MM/yyyy    hh:mm a"];
    
    [[self label30Min] setText:@""];
    [[self label1Hour] setText:@""];
    [[self labelSelectDateTime] setText:[dateFormatter stringFromDate:date]];
}

- (IBAction)datePickerDonePressed:(UIBarButtonItem *)sender {
    [self hideDatePicker];
    
    NSDate *date = [[self datePicker] date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd/MM/yyyy    hh:mm a"];
    
    [[self label30Min] setText:@""];
    [[self label1Hour] setText:@""];
    [[self labelSelectDateTime] setText:[dateFormatter stringFromDate:date]];
}

@end
