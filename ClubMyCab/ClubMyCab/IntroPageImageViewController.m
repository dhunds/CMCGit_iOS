//
//  IntroPageImageViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 20/08/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import "IntroPageImageViewController.h"
#import "Logger.h"

@interface IntroPageImageViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation IntroPageImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[self imageView] setImage:[self image]];
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
    
    [Logger logDebug:@"IntroPageImageViewController"
             message:[NSString stringWithFormat:@" prepareForSegue identifier : %@", [segue identifier]]];
}


@end
