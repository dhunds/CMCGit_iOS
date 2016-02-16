//
//  IntroPageViewController.m
//  ClubMyCab
//
//  Created by Rohit Dhundele on 20/08/15.
//  Copyright (c) 2015 ClubMyCab. All rights reserved.
//

#import "IntroPageViewController.h"
#import "IntroPageImageViewController.h"
#import "Logger.h"

@interface IntroPageViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (strong, nonatomic) NSString *TAG;
@property (strong, nonatomic) NSMutableArray *viewControllers;

@end

@implementation IntroPageViewController

@synthesize viewControllers = _viewControllers;

- (NSString *)TAG {
    return @"IntroPageViewController";
}

- (NSMutableArray *)viewControllers {
    if(!_viewControllers) {
        _viewControllers = [NSMutableArray array];
    }
    
    return _viewControllers;
}

- (id)init {
    self = [super init];
    
    self = [self initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                   navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                 options:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:UIPageViewControllerSpineLocationMin]
                                                                     forKey:UIPageViewControllerOptionSpineLocationKey]];
    [self setDataSource:self];
    [self setDelegate:self];
    [self setDoubleSided:NO];
    
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" init dataSource : %@", [[self dataSource] description]]];
    
    [self setViewControllers:[NSArray arrayWithObject:[[self viewControllers] objectAtIndex:0]]
                   direction:UIPageViewControllerNavigationDirectionForward
                    animated:YES
                  completion:^(BOOL finished) {}];
    
    return self;
    
}

- (IntroPageViewController *)designatedInitializer {
    return [self init];
}

- (void)initializeDatasource {
    
    id viewController = nil;
    
    for(int i = 0; i < 3; i++) {
        viewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"IntroPageVC"];
        [Logger logDebug:[self TAG]
                 message:[NSString stringWithFormat:@" initializeDatasource viewController : %@", [viewController description]]];
        if ([viewController isKindOfClass:[IntroPageImageViewController class]]) {
            switch (i) {
                case 0: {
                    [(IntroPageImageViewController *)viewController setImage:[UIImage imageNamed:@"help_screen_1.jpg"]];
                    break;
                }
                    
                case 1: {
                    [(IntroPageImageViewController *)viewController setImage:[UIImage imageNamed:@"help_screen_2.jpg"]];
                    break;
                }
                    
                case 2: {
                    [(IntroPageImageViewController *)viewController setImage:[UIImage imageNamed:@"help_screen_3.jpg"]];
                    break;
                }
                    
//                case 3: {
//                    [(IntroPageImageViewController *)viewController setImage:[UIImage imageNamed:@"help_screen_4.png"]];
//                    break;
//                }
            }
            
            [[self viewControllers] addObject:viewController];
        }
        
    }
    
    [self designatedInitializer];
}

#pragma mark - View controller life cycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [Logger logDebug:[self TAG]
             message:@" viewDidLoad"];
    
//    [[self navigationController] setNavigationBarHidden:YES
//                                               animated:NO];
    
//    [[self navigationItem] setTitle:@""];
//    [[self navigationItem] setHidesBackButton:YES
//                                     animated:NO];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIPageViewControllerDataSource methods

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController {
    
    NSUInteger currentIndex = [[self viewControllers] indexOfObject:viewController];
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" viewControllerAfterViewController currentIndex : %lu", (unsigned long)currentIndex]];
    currentIndex++;
    
    if (currentIndex >= [[self viewControllers] count]) {
        return nil;
    }
    
    return (UIViewController *)[[self viewControllers] objectAtIndex:currentIndex];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger currentIndex = [[self viewControllers] indexOfObject:viewController];
    [Logger logDebug:[self TAG]
             message:[NSString stringWithFormat:@" viewControllerBeforeViewController currentIndex : %lu", (unsigned long)currentIndex]];
    currentIndex--;
    
    if (currentIndex >= [[self viewControllers] count]) {       //condition is >= because unsigned integer will not go negative on -- operator
        return nil;
    }
    
    return (UIViewController *)[[self viewControllers] objectAtIndex:currentIndex];
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
