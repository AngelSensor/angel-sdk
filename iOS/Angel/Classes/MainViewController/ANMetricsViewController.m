/*
 * Copyright (c) 2016, Seraphim Sense Ltd.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions
 *    and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of
 *    conditions and the following disclaimer in the documentation and/or other materials provided
 *    with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to
 *    endorse or promote products derived from this software without specific prior written
 *    permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
 * BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "ANMetricsViewController.h"

#import "ANRightNowViewController.h"
#import "ANDailyViewController.h"
#import "ANHistoryViewController.h"
#import "ANLandscapeRightNowViewController.h"

typedef enum {
    ViewControllerTypeNone,
    ViewControllerTypeRightNow,
    ViewControllerTypeToday,
    ViewControllerTypeHistory
} ViewControllerType;

@interface ANMetricsViewController ()

@property (nonatomic, weak) IBOutlet UIView *headerView;
@property (nonatomic, weak) IBOutlet UIView *containerView;

@property (nonatomic) ViewControllerType viewType;

@property (nonatomic, strong) ANRightNowViewController *rightNowViewController;
@property (nonatomic, strong) ANDailyViewController *todayViewController;
@property (nonatomic, strong) ANHistoryViewController *historyViewController;

@property (nonatomic, strong) ANLandscapeRightNowViewController *landscapeRightNowViewController;

@property (nonatomic, weak) UIViewController *currentViewController;

@property (nonatomic, weak) IBOutlet UIButton *rightNowButton;
@property (nonatomic, weak) IBOutlet UIButton *todayButton;
@property (nonatomic, weak) IBOutlet UIButton *historyButton;

@property BOOL isShowingLandscapeView;

@end

@implementation ANMetricsViewController

#pragma mark Initialization

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
    
    }
    return self;
}

#pragma mark Child controllers handling

- (ANRightNowViewController *)rightNowViewController {
    if (!_rightNowViewController) {
        _rightNowViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"rightNowViewController"];
    }
    return _rightNowViewController;
}

- (ANDailyViewController *)todayViewController {
    if (!_todayViewController) {
        _todayViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"todayViewController"];
    }
    return _todayViewController;
}

- (ANHistoryViewController *)historyViewController {
    if (!_historyViewController) {
        _historyViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"historyViewController"];
    }
    return _historyViewController;
}

- (ANLandscapeRightNowViewController *)landscapeRightNowViewController {
    if (!_landscapeRightNowViewController) {
        _landscapeRightNowViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"landscapeRightNowViewController"];
    }
    return _landscapeRightNowViewController;
}

#pragma mark View type handling

- (void)setViewType:(ViewControllerType)viewType {
    if (_viewType != viewType) {
        _viewType = viewType;
        
        self.rightNowButton.selected = NO;
        self.todayButton.selected = NO;
        self.historyButton.selected = NO;
        
        UIViewController *controller;
        switch (viewType) {
            case ViewControllerTypeRightNow: {
                self.rightNowButton.selected = YES;
                controller = [self rightNowViewController];
            } break;
            case ViewControllerTypeToday: {
                self.todayButton.selected = YES;
                controller = [self todayViewController];
            } break;
            case ViewControllerTypeHistory: {
                self.historyButton.selected = YES;
                controller = [self historyViewController];
            } break;
            default: {
                
            } break;
        }
        self.currentViewController = controller;
    }
}

- (void)presentDailyWithItem:(ANHistoryItem *)item {
    [self.todayViewController setHistoryItem:item];
    [self setViewType:ViewControllerTypeToday];
}

- (void)setCurrentViewController:(UIViewController *)currentViewController {
    if (_currentViewController) {
        [_currentViewController willMoveToParentViewController:nil];
        [_currentViewController.view removeFromSuperview];
        [_currentViewController removeFromParentViewController];
        _currentViewController = nil;
    }
    _currentViewController = currentViewController;
    if (_currentViewController) {
        [_currentViewController willMoveToParentViewController:self];
        [self addChildViewController:_currentViewController];
        _currentViewController.view.frame = self.containerView.bounds;
        [self.containerView addSubview:_currentViewController.view];
        [_currentViewController didMoveToParentViewController:self];
    }
}

#pragma mark Interface Actions

- (IBAction)rightNowButtonPressed:(id)sender {
    [self setViewType:ViewControllerTypeRightNow];
}

- (IBAction)todayButtonPressed:(id)sender {
    [self setViewType:ViewControllerTypeToday];
}

- (IBAction)historyButtonPressed:(id)sender {
    [self setViewType:ViewControllerTypeHistory];
}

#pragma mark Orienation handling

- (void)awakeFromNib {
    self.isShowingLandscapeView = NO;
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)orientationChanged:(NSNotification *)notification {
    
   if ([[ANDataManager sharedManager] isUpdateMode])
   {
       return;
   }
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsLandscape(deviceOrientation) && !self.isShowingLandscapeView) {
        if ((self.viewType == ViewControllerTypeRightNow) && (![[ANDataManager sharedManager] updating])) {
            [[ANDataManager sharedManager] setServiceEnableMode:ServiceEnableModeLandscape];
            [self presentViewController:self.landscapeRightNowViewController animated:NO completion:nil];
            self.isShowingLandscapeView = YES;
        }
    } else if (UIDeviceOrientationIsPortrait(deviceOrientation) && self.isShowingLandscapeView) {
        if (self.viewType == ViewControllerTypeRightNow) {
            [[ANDataManager sharedManager] setServiceEnableMode:ServiceEnableModePortrait];
            [self dismissViewControllerAnimated:NO completion:nil];
            self.isShowingLandscapeView = NO;
        }
    }
}

#pragma mark View lifeCycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //[self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //[self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setViewType:ViewControllerTypeRightNow];
    
    ANDataManager *dMgr = [ANDataManager sharedManager];
    if (!dMgr.currentWristband) {
        if (dMgr.connectedPeripheralsExists) {
            [dMgr connectStoredPeripheralWithCompletionHandler:^(BOOL success, NSError *error) {
                if (success && !error) {
                    
                }
            }];
        } else {
            //something went wrong
        }
    }
    
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ((self.viewType == ViewControllerTypeRightNow) && (![[ANDataManager sharedManager] updating])) {
        return UIInterfaceOrientationMaskAll;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

- (BOOL)shouldAutorotate {
    return ((self.viewType == ViewControllerTypeRightNow) && (![[ANDataManager sharedManager] updating]));
}

@end
